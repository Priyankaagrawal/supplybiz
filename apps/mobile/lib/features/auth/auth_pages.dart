import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../core/l10n/l10n.dart';
import '../../core/router/route_widgets.dart';
import '../../core/router/routes.dart';
import 'session_controller.dart';
import '../../core/auth/sms_retriever.dart';

final authEnabledProvider = Provider<bool>((ref) => false);

/// S-COM-03/04/05 and authenticated session actions. OTP is one semantic text field.
class AuthPage extends ConsumerStatefulWidget {
  const AuthPage(this.title, {super.key});
  final RouteTitle title;
  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _mobile = TextEditingController();
  final _otp = TextEditingController();
  bool _consent = false;
  bool _preparing = false;
  Timer? _timer;
  final _sms = SmsRetriever();
  @override
  void initState() {
    super.initState();
    if (!ref.read(authEnabledProvider)) return;
    _mobile.text = ref.read(sessionProvider).mobile;
    if (widget.title == RouteTitle.otp &&
        ref.read(sessionProvider).channel == 'SMS') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_sms.start((code) {
            if (mounted && ref.read(sessionProvider).challenge) {
              _otp.text = code;
              unawaited(ref.read(sessionProvider.notifier).verify(code));
            }
          }));
        }
      });
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sms.stop();
    _mobile.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _send(String channel) async {
    if (_preparing || ref.read(sessionProvider).busy) return;
    setState(() => _preparing = true);
    String? hash;
    if (channel == 'SMS') {
      hash = await _sms.start((code) {
        if (mounted && ref.read(sessionProvider).challenge) {
          _otp.text = code;
          unawaited(ref.read(sessionProvider.notifier).verify(code));
        }
      });
    }
    if (!mounted) return;
    await ref.read(sessionProvider.notifier).send(_mobile.text, channel,
        consentAccepted: _consent || ref.read(sessionProvider).challenge,
        appHash: hash);
    if (mounted) setState(() => _preparing = false);
    if (mounted &&
        ref.read(sessionProvider).challenge &&
        ref.read(sessionProvider).failure == null) {
      _otp.clear();
      const OtpRoute().go(context);
    }
  }

  Future<void> _selectRole(String role) async {
    await ref.read(sessionProvider.notifier).selectRole(role);
    if (!mounted || widget.title != RouteTitle.settings) return;
    final state = ref.read(sessionProvider);
    if (state.failure != null || state.user?.activeRole?.value != role) return;
    if (role == 'VENDOR') {
      const VendorHomeRoute().go(context);
    } else {
      const CustomerHomeRoute().go(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(authEnabledProvider)) {
      return RoutePlaceholder(title: widget.title);
    }
    final state = ref.watch(sessionProvider);
    final controller = ref.read(sessionProvider.notifier);
    final l10n = context.l10n;
    final otp = widget.title == RouteTitle.otp;
    final role = widget.title == RouteTitle.role ||
        widget.title == RouteTitle.switchRole;
    final config = ref.read(authConfigProvider);
    final wait = state.retryAt?.difference(DateTime.now()).inSeconds ?? 0;
    final failure = state.failure;
    final error = switch (failure?.code) {
      'OTP_INVALID' => l10n.authWrongOtp,
      'OTP_EXPIRED' => l10n.authExpiredOtp,
      'OTP_ATTEMPTS_EXCEEDED' => l10n.authExhaustedOtp,
      'OTP_PROVIDER_UNAVAILABLE' => l10n.authDeliveryUnavailable,
      _ => failure?.toMessage(l10n),
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName)),
      body: SafeArea(
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: AutofillGroup(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                          header: true,
                          child: Text(routeLabel(context, widget.title),
                              style:
                                  Theme.of(context).textTheme.headlineSmall)),
                      const SizedBox(height: 16),
                      Text(switch (
                          AppRoutingScope.of(context).environment.name) {
                        'dev' => l10n.developmentEnvironment,
                        'staging' => l10n.stagingEnvironment,
                        _ => l10n.productionEnvironment,
                      }),
                      if (error != null)
                        Semantics(
                            liveRegion: true,
                            child: Text(error,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error))),
                      if (failure?.code == 'RATE_LIMITED' && wait > 0)
                        Text(l10n.authResendWait(wait + 1)),
                      if (!state.ready) ...[
                        const LinearProgressIndicator(),
                        SbButton(
                            label: l10n.authRetry,
                            loading: state.busy,
                            onPressed: controller.restore),
                        SbButton(
                            label: l10n.authLogout,
                            onPressed: state.busy ? null : controller.clear,
                            variant: SbButtonVariant.secondary),
                      ] else if (state.user != null || role) ...[
                        if (widget.title == RouteTitle.switchRole)
                          SbButton(
                              label: l10n.routeHomeAction,
                              variant: SbButtonVariant.tertiary,
                              onPressed: state.busy
                                  ? null
                                  : AppRoutingScope.of(context)
                                      .controller
                                      .cancelPending),
                        SbButton(
                            label: l10n.authCustomer,
                            loading: state.busy,
                            onPressed: () => _selectRole('CUSTOMER')),
                        const SizedBox(height: 12),
                        SbButton(
                            label: l10n.authVendor,
                            loading: state.busy,
                            onPressed: () => _selectRole('VENDOR')),
                        const SizedBox(height: 24),
                        SbButton(
                            label: l10n.authLogout,
                            loading: state.busy,
                            onPressed: controller.logout,
                            variant: SbButtonVariant.secondary),
                        const SizedBox(height: 12),
                        SbButton(
                            label: l10n.authLogoutAll,
                            loading: state.busy,
                            onPressed: () => controller.logout(all: true),
                            variant: SbButtonVariant.secondary),
                      ] else if (otp && state.challenge) ...[
                        Text(state.channel == 'SMS'
                            ? l10n.authSms
                            : l10n.authWhatsapp),
                        Text('+91 ${state.mobile}'),
                        const SizedBox(height: 16),
                        SbOtpField(
                            controller: _otp,
                            enabled: !state.busy,
                            onChanged: (code) {
                              if (code.length == 6) {
                                unawaited(controller.verify(code));
                              }
                            }),
                        SbButton(
                            label: l10n.authVerify,
                            loading: state.busy,
                            onPressed: () => controller.verify(_otp.text)),
                        const SizedBox(height: 12),
                        SbButton(
                            label: wait > 0
                                ? l10n.authResendWait(wait + 1)
                                : l10n.authResend,
                            onPressed: wait > 0 || state.busy
                                ? null
                                : () => _send(state.channel),
                            variant: SbButtonVariant.secondary),
                        SbButton(
                            label: l10n.authChangeNumber,
                            onPressed: state.busy
                                ? null
                                : () {
                                    controller.changeNumber();
                                    const LoginRoute().go(context);
                                  },
                            variant: SbButtonVariant.tertiary),
                      ] else ...[
                        const SizedBox(height: 16),
                        TextField(
                            controller: _mobile,
                            enabled: !state.busy,
                            keyboardType: TextInputType.phone,
                            autofillHints: const [
                              AutofillHints.telephoneNumberNational
                            ],
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9\s]')),
                              LengthLimitingTextInputFormatter(20)
                            ],
                            decoration: InputDecoration(
                                prefixText: '+91 ',
                                labelText: l10n.authMobile,
                                errorText: _mobile.text.isNotEmpty &&
                                        !RegExp(r'^[6-9]\d{9}$').hasMatch(
                                            _mobile.text
                                                .replaceAll(RegExp(r'\s'), ''))
                                    ? l10n.authInvalidMobile
                                    : null),
                            onChanged: (_) => setState(() {})),
                        if (!config.consentAvailable)
                          Text(l10n.authLegalUnavailable),
                        CheckboxListTile(
                            value: _consent,
                            onChanged: config.consentAvailable && !state.busy
                                ? (value) =>
                                    setState(() => _consent = value ?? false)
                                : null,
                            title: Text(l10n.authConsent),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading),
                        SbButton(
                            label: l10n.authTerms,
                            onPressed: () =>
                                _legal(l10n.authTerms, config.terms),
                            variant: SbButtonVariant.tertiary),
                        SbButton(
                            label: l10n.authPrivacy,
                            onPressed: () =>
                                _legal(l10n.authPrivacy, config.privacy),
                            variant: SbButtonVariant.tertiary),
                        const SizedBox(height: 16),
                        SbButton(
                            label: l10n.authSend,
                            loading: state.busy || _preparing,
                            onPressed: _valid(config) && wait <= 0
                                ? () => _send('SMS')
                                : null),
                        const SizedBox(height: 12),
                        SbButton(
                            label: l10n.authWhatsapp,
                            loading: state.busy || _preparing,
                            onPressed: _valid(config) && wait <= 0
                                ? () => _send('WHATSAPP')
                                : null,
                            variant: SbButtonVariant.secondary),
                        const SizedBox(height: 16),
                        Text(l10n.authTrust),
                      ],
                    ]),
              ))),
    );
  }

  bool _valid(AuthConfig config) =>
      _consent &&
      config.consentAvailable &&
      RegExp(r'^[6-9]\d{9}$')
          .hasMatch(_mobile.text.replaceAll(RegExp(r'\s'), ''));
  void _legal(String title, String content) {
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => SafeArea(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                          header: true,
                          child: Text(title,
                              style: Theme.of(context).textTheme.titleLarge)),
                      const SizedBox(height: 16),
                      Text(content.isEmpty
                          ? context.l10n.authLegalUnavailable
                          : content),
                    ]))));
  }
}
