// T-019 / S-COM-10. OTPs and pending confirmation live only in this tab's memory.
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:uuid/uuid.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import '../../core/network/app_failure.dart';
import '../../core/network/network_client.dart';
import '../auth/session_controller.dart';
import '../profile/profile_controller.dart';

final accountDeletionProvider =
    ChangeNotifierProvider.autoDispose<DeletionController>((ref) {
  final identity = ref.watch(
      sessionProvider.select((s) => (s.user?.id, s.user?.activeRole?.value)));
  final session = ref.read(sessionProvider.notifier),
      storage = ref.read(authStorageProvider);
  final client = profileClient(ref);
  ref.onDispose(client.close);
  return DeletionController(client, storage.installationId,
      () => session.clearDeletedAccount(identity.$1 ?? ''));
});

class DeletionController extends ChangeNotifier {
  DeletionController(NetworkClient client, this.device, this.clear)
      : api = AccountDeletionApi(client.dio);
  final AccountDeletionApi api;
  final Future<String> Function() device;
  final Future<void> Function() clear;
  DeletionPreview? preview;
  AppFailure? failure;
  DateTime? resendAt;
  bool busy = false, sent = false, uncertain = false, disposed = false;
  String? _key, _code;
  bool? _acknowledge;
  bool get canSend =>
      !busy &&
      !uncertain &&
      (resendAt == null || !DateTime.now().isBefore(resendAt!));
  @override
  void dispose() {
    disposed = true;
    _code = null;
    super.dispose();
  }

  Future<void> run(Future<void> Function() action) async {
    if (busy || disposed) return;
    busy = true;
    failure = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      if (!disposed) {
        failure = e is DioException
            ? mapDioFailure(e)
            : e is AppFailure
                ? e
                : const UnknownFailure();
      }
    } finally {
      busy = false;
      if (!disposed) notifyListeners();
    }
  }

  Future<void> load() => run(() async {
        preview = (await api.accountDeletionControllerPreview()).data;
      });
  Future<void> send() => run(() async {
        if (uncertain ||
            (resendAt != null && DateTime.now().isBefore(resendAt!))) {
          return;
        }
        final result = (await api.accountDeletionControllerSend(
                idempotencyKey: const Uuid().v4(), xDeviceId: await device()))
            .data!;
        sent = true;
        resendAt = DateTime.now().add(Duration(seconds: result.resendAfterSec));
      });
  Future<void> confirm(String code, bool acknowledge) => run(() async {
        if (!sent || preview == null) return;
        _key ??= const Uuid().v4();
        _code ??= code;
        _acknowledge ??= acknowledge;
        uncertain = true;
        try {
          await api.accountDeletionControllerConfirm(
              idempotencyKey: _key!,
              confirmDeletionInput: ConfirmDeletionInput(
                  code: _code!, acknowledgeReceivables: _acknowledge!));
        } on DioException catch (error) {
          if ([400, 409, 410, 422].contains(error.response?.statusCode)) {
            uncertain = false;
            _key = null;
            _code = null;
            _acknowledge = null;
          }
          rethrow;
        }
        _code = null;
        await clear();
      });
}

class AccountDeletionPage extends ConsumerStatefulWidget {
  const AccountDeletionPage({super.key});
  @override
  ConsumerState<AccountDeletionPage> createState() => _DeletionPageState();
}

class _DeletionPageState extends ConsumerState<AccountDeletionPage> {
  final code = TextEditingController();
  DeletionController? initialized;
  bool acknowledged = false;
  bool invalidCode = false;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = ref.watch(accountDeletionProvider), l = context.l10n;
    if (initialized != m) {
      initialized = m;
      code.clear();
      acknowledged = false;
      Future.microtask(m.load);
    }
    return Scaffold(
        appBar: AppBar(title: Text(l.settingsDelete)),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(16), children: [
          Text(l.deletionExplanation),
          const SizedBox(height: 12),
          Text(l.deletionRetention),
          if (m.busy) const SbSkeleton(lines: 2),
          if (m.failure != null)
            Semantics(liveRegion: true, child: Text(m.failure!.toMessage(l))),
          if (m.preview == null)
            SbButton(label: l.authRetry, onPressed: m.busy ? null : m.load),
          if (m.preview != null) ...[
            if (BigInt.parse(m.preview!.outstandingReceivablesPaise) >
                BigInt.zero)
              Semantics(
                  liveRegion: true,
                  child: Text(l.deletionReceivables(
                      m.preview!.outstandingReceivablesPaise))),
            CheckboxListTile(
                value: acknowledged,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(l.deletionAcknowledge),
                onChanged: m.busy || m.uncertain
                    ? null
                    : (v) => setState(() => acknowledged = v ?? false)),
            SbButton(
                label: m.sent ? l.deletionResend : l.deletionSend,
                onPressed: m.canSend
                    ? () async {
                        await m.send();
                        if (mounted) setState(() {});
                      }
                    : null),
            if (m.sent) ...[
              Text(l.deletionOtpNotice),
              TextField(
                  controller: code,
                  enabled: !m.busy && !m.uncertain,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  autofillHints: const [],
                  onChanged: (_) => setState(() => invalidCode = false),
                  decoration: InputDecoration(
                      labelText: l.deletionOtp,
                      errorText: invalidCode ? l.networkValidation : null)),
              if (m.uncertain) Text(l.deletionUncertain),
              SbButton(
                  label: m.uncertain ? l.deletionRetry : l.deletionConfirm,
                  onPressed: m.busy || !acknowledged
                      ? null
                      : () async {
                          if (!m.uncertain &&
                              !RegExp(r'^\d{6}$').hasMatch(code.text)) {
                            setState(() => invalidCode = true);
                            return;
                          }
                          if (!m.uncertain) {
                            final yes = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                        scrollable: true,
                                        title: Text(l.settingsDelete),
                                        content: Text(l.deletionFinalWarning),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: Text(l.settingsCancel)),
                                          FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: Text(l.deletionConfirm))
                                        ]));
                            if (yes != true || !mounted) return;
                          }
                          await m.confirm(code.text, acknowledged);
                        }),
            ],
          ],
          if (m.uncertain)
            SbButton(
                label: l.authLogout,
                variant: SbButtonVariant.secondary,
                onPressed: m.busy ? null : m.clear),
        ])));
  }
}
