// S-V-01–04: resumable category, business, private KYC and manual-review status.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/l10n/l10n.dart';
import '../../core/network/app_failure.dart';
import '../../core/storage/onboarding_device.dart';
import 'mask_document.dart';
import '../../core/router/guards.dart';
import '../../core/router/routes.dart';
import 'onboarding_controller.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});
  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final form = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  int? editing;
  String? category;
  bool picking = false, secure = false;
  final secureOwner = const Uuid().v4();
  String? localError;
  final pending = <String, (Uint8List, bool, String)>{};
  @override
  void initState() {
    super.initState();
    _secure();
  }

  Future<void> _secure() async {
    try {
      await const OnboardingDevice().secure(true, secureOwner);
      if (mounted) setState(() => secure = true);
    } catch (_) {
      if (mounted) setState(() => localError = 'secure');
    }
  }

  @override
  void dispose() {
    for (final controller in fields.values) {
      controller.dispose();
    }
    pending.clear();
    // Leaving the screen must proceed even if its native Activity was destroyed.
    const OnboardingDevice()
        .secure(false, secureOwner)
        .catchError((Object _) {});
    super.dispose();
  }

  TextEditingController controller(String key, OnboardingController model) =>
      fields.putIfAbsent(
          key, () => TextEditingController(text: model.values[key] ?? ''));
  Widget field(OnboardingController model, String key, String label,
      {int min = 1,
      int max = 120,
      String? pattern,
      bool optional = false,
      bool secret = false,
      bool numeric = false,
      bool decimal = false}) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: TextFormField(
          controller: controller(key, model),
          enabled: !model.busy && !picking && secure,
          decoration: InputDecoration(
              labelText: label, border: const OutlineInputBorder()),
          obscureText: secret,
          enableSuggestions: !secret,
          autocorrect: false,
          keyboardType: decimal
              ? const TextInputType.numberWithOptions(
                  decimal: true, signed: true)
              : numeric
                  ? TextInputType.number
                  : TextInputType.text,
          maxLength: max,
          onChanged: (value) => model.edit(key, value),
          validator: (value) {
            final text = (value ?? '').trim();
            if (optional && text.isEmpty) return null;
            if (text.length < min ||
                text.length > max ||
                (pattern != null && !RegExp(pattern).hasMatch(text))) {
              return context.l10n.onboardingInvalid;
            }
            if (decimal) {
              final number = num.tryParse(text);
              final limit = key == 'latitude' ? 90 : 180;
              if (number == null ||
                  !number.isFinite ||
                  number < -limit ||
                  number > limit) {
                return context.l10n.onboardingInvalid;
              }
            }
            if (key == 'accountNumberConfirmation' &&
                text != model.values['accountNumber']?.trim()) {
              return context.l10n.onboardingAccountMismatch;
            }
            return null;
          },
        ));
  }

  Future<void> _preview(
      OnboardingController model, String field, String label) async {
    try {
      final bytes = await model.content(model.values[field]!);
      final pdf =
          bytes.length >= 5 && String.fromCharCodes(bytes.take(5)) == '%PDF-';
      final display =
          pdf ? await const OnboardingDevice().previewPdf(bytes) : bytes;
      if (mounted && display != null) {
        await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
                    title: Text(label),
                    content: SingleChildScrollView(
                        child: Image.memory(display, semanticLabel: label)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(context.l10n.onboardingClose))
                    ]));
      }
    } catch (_) {
      if (mounted) setState(() => localError = 'preview');
    }
  }

  Future<void> _pick(
      OnboardingController model, String field, String label) async {
    setState(() {
      picking = true;
      localError = null;
    });
    try {
      var selected = pending[field];
      if (selected == null) {
        final file = await const OnboardingDevice().pick();
        if (!mounted || file == null) return;
        var bytes = file['bytes'] as Uint8List;
        final pdf = file['pdf'] as bool;
        if (field.startsWith('aadhaar')) {
          final masked = await showDialog<Uint8List>(
              context: context,
              barrierDismissible: false,
              builder: (_) =>
                  MaskDocument(bytes: bytes, pdf: pdf, label: label));
          if (!mounted || masked == null) return;
          bytes = masked;
        }
        selected = (bytes, pdf, const Uuid().v4());
        pending[field] = selected;
      }
      await model.upload(field, selected.$1,
          pdf: selected.$2, key: selected.$3);
      if (model.failure == null ||
          (model.failure is! NetworkFailure &&
              model.failure is! TimeoutFailure &&
              model.failure is! ServerFailure)) {
        pending.remove(field);
      }
    } catch (_) {
      if (mounted) setState(() => localError = 'file');
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  Widget attachment(OnboardingController model, String key, String label) =>
      Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
                onPressed: model.busy || picking || !secure
                    ? null
                    : () => _pick(model, key, label),
                icon: const Icon(Icons.upload_file),
                label: Text(pending.containsKey(key)
                    ? context.l10n.onboardingRetryUpload(label)
                    : context.l10n.onboardingUpload(label))),
            if (model.values[key]?.isNotEmpty == true)
              TextButton.icon(
                  onPressed: model.busy || picking
                      ? null
                      : () => _preview(model, key, label),
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(context.l10n.onboardingView(label))),
          ]);
  Future<void> _save(OnboardingController model, int step) async {
    if (step == 1) {
      if (category == null) return;
      await model.saveCategory(category!);
    } else {
      if (!form.currentState!.validate()) return;
      if (step == 3 &&
          ['aadhaarFrontMediaId', 'aadhaarBackMediaId', 'panMediaId']
              .any((key) => model.values[key]?.isNotEmpty != true)) {
        setState(() => localError = 'documents');
        return;
      }
      if (step == 2) {
        await model.saveBusiness();
      } else {
        await model.submit();
      }
    }
    if (mounted && model.failure == null) {
      setState(() {
        editing = step == 2 && model.complete && model.canSubmit ? 3 : null;
        localError = null;
      });
      if (step == 3) const OnboardingRoute(OnboardingStep.status).go(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(onboardingProvider);
    final l = context.l10n;
    final step = editing ?? model.step;
    final disabled = model.busy || picking || !secure;
    return Scaffold(
        appBar: AppBar(title: Text(l.routeOnboarding), actions: [
          IconButton(
              tooltip: l.routeSettings,
              onPressed: model.busy || picking
                  ? null
                  : () => const CommonRoute(CommonPage.settings).go(context),
              icon: const Icon(Icons.manage_accounts_outlined)),
        ]),
        body: SafeArea(
            child: !secure
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(l.onboardingSecureError),
                    FilledButton(onPressed: _secure, child: Text(l.authRetry)),
                  ]))
                : !model.ready
                    ? Center(
                        child: model.failure == null
                            ? const CircularProgressIndicator()
                            : Column(mainAxisSize: MainAxisSize.min, children: [
                                Text(model.failure!.toMessage(l)),
                                FilledButton(
                                    onPressed: model.load,
                                    child: Text(l.authRetry))
                              ]))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                            key: form,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(l.onboardingStep(step),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge),
                                  const SizedBox(height: 16),
                                  if (model.failure != null)
                                    Semantics(
                                        liveRegion: true,
                                        child:
                                            Text(model.failure!.toMessage(l))),
                                  if (localError != null)
                                    Semantics(
                                        liveRegion: true,
                                        child: Text(switch (localError) {
                                          'secure' => l.onboardingSecureError,
                                          'documents' =>
                                            l.onboardingDocumentsRequired,
                                          'preview' => l.onboardingPreviewError,
                                          _ => l.onboardingFileError,
                                        })),
                                  if (localError == 'secure')
                                    FilledButton(
                                        onPressed: _secure,
                                        child: Text(l.authRetry)),
                                  if (model.busy || picking)
                                    const LinearProgressIndicator(),
                                  if (step == 1) ...[
                                    Text(l.onboardingCategory),
                                    if (model.categories.isEmpty)
                                      Text(l.onboardingNoCategories),
                                    RadioGroup<String>(
                                        groupValue: category ??
                                            model.values['categoryId'],
                                        onChanged: (value) {
                                          if (!disabled && value != null) {
                                            setState(() {
                                              category = value;
                                              model.edit('categoryId', value);
                                            });
                                          }
                                        },
                                        child: Column(children: [
                                          for (final item in model.categories)
                                            RadioListTile<String>(
                                                enabled: !disabled,
                                                title: Text(item.name),
                                                secondary: const Icon(
                                                    Icons.store_outlined),
                                                value: item.id),
                                        ])),
                                  ],
                                  if (step == 2) ...[
                                    field(model, 'businessName',
                                        l.onboardingBusinessName,
                                        min: 2, max: 80),
                                    field(model, 'gstin', l.onboardingGstin,
                                        max: 15,
                                        optional: true,
                                        pattern:
                                            r'^\d{2}[A-Z]{5}\d{4}[A-Z][1-9A-Z]Z[0-9A-Z]$'),
                                    field(model, 'addressLine',
                                        l.onboardingAddress,
                                        min: 5, max: 200),
                                    field(model, 'city', l.onboardingCity),
                                    field(model, 'state', l.onboardingState),
                                    field(model, 'pincode', l.onboardingPincode,
                                        max: 6,
                                        numeric: true,
                                        pattern: r'^[1-9]\d{5}$'),
                                    field(
                                        model, 'latitude', l.onboardingLatitude,
                                        decimal: true),
                                    field(model, 'longitude',
                                        l.onboardingLongitude,
                                        decimal: true),
                                    attachment(model, 'shopPhotoMediaId',
                                        l.onboardingShopPhoto),
                                  ],
                                  if (step == 3) ...[
                                    Text(l.onboardingSecurityNote),
                                    Text(l.onboardingMaskGuide),
                                    attachment(model, 'aadhaarFrontMediaId',
                                        l.onboardingAadhaarFront),
                                    attachment(model, 'aadhaarBackMediaId',
                                        l.onboardingAadhaarBack),
                                    attachment(model, 'panMediaId',
                                        l.onboardingPanPhoto),
                                    field(model, 'pan', l.onboardingPan,
                                        max: 10,
                                        pattern: r'^[A-Z]{5}\d{4}[A-Z]$'),
                                    field(
                                        model, 'holderName', l.onboardingHolder,
                                        min: 2),
                                    field(model, 'bankName', l.onboardingBank,
                                        min: 2),
                                    field(model, 'accountNumber',
                                        l.onboardingAccount,
                                        max: 18,
                                        numeric: true,
                                        secret: true,
                                        pattern: r'^\d{9,18}$'),
                                    field(model, 'accountNumberConfirmation',
                                        l.onboardingConfirmAccount,
                                        max: 18,
                                        numeric: true,
                                        secret: true,
                                        pattern: r'^\d{9,18}$'),
                                    field(model, 'ifsc', l.onboardingIfsc,
                                        max: 11,
                                        pattern: r'^[A-Z]{4}0[A-Z0-9]{6}$'),
                                    field(model, 'upiId', l.onboardingUpi,
                                        max: 321,
                                        optional: true,
                                        pattern:
                                            r'^[\w.\-]{2,256}@[a-zA-Z]{2,64}$'),
                                  ],
                                  if (step < 4) ...[
                                    if (step == 3)
                                      TextButton(
                                          onPressed: disabled
                                              ? null
                                              : () =>
                                                  setState(() => editing = 2),
                                          child:
                                              Text(l.onboardingEditBusiness)),
                                    const SizedBox(height: 16),
                                    FilledButton(
                                        onPressed: disabled ||
                                                (step == 1 &&
                                                    category == null &&
                                                    model.values[
                                                            'categoryId'] ==
                                                        null)
                                            ? null
                                            : () {
                                                category ??=
                                                    model.values['categoryId'];
                                                _save(model, step);
                                              },
                                        child: Text(step == 3
                                            ? l.onboardingSubmit
                                            : l.onboardingContinue)),
                                  ],
                                  if (step >= 4) ...[
                                    VerificationStatus(model: model),
                                    if (model.submission?.status == 'REJECTED')
                                      FilledButton(
                                          onPressed: disabled
                                              ? null
                                              : () =>
                                                  setState(() => editing = 3),
                                          child: Text(l.onboardingResubmit)),
                                    OutlinedButton(
                                        onPressed: disabled ? null : model.load,
                                        child: Text(l.onboardingRefresh)),
                                    FilledButton(
                                        onPressed: disabled
                                            ? null
                                            : () => const VendorHomeRoute()
                                                .go(context),
                                        child: Text(l.routeHomeAction)),
                                  ],
                                ])))));
  }
}

class VerificationStatus extends StatelessWidget {
  const VerificationStatus({required this.model, super.key});
  final OnboardingController model;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final status = model.submission?.status ?? model.profile?.kycStatus;
    return Semantics(
        liveRegion: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              switch (status) {
                'VERIFIED' => l.onboardingVerified,
                'REJECTED' => l.onboardingRejected,
                'MANUAL_REVIEW' || 'PENDING' => l.onboardingReview,
                _ => l.onboardingNotVerified
              },
              style: Theme.of(context).textTheme.titleMedium),
          if (status != 'VERIFIED') Text(l.onboardingHidden),
          if (model.submission != null) ...[
            Text(l.onboardingManualMethod),
            Text(l.onboardingProviderNotRun),
            Text(l.onboardingMaskedAccount(model.submission!.accountLast4)),
            if (model.submission!.reason != null)
              Text(model.submission!.reason!),
          ],
        ]));
  }
}
