// T-106 / S-V-20/31/33. KYC editor reuses the secure masked-document workflow.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import '../../core/router/routes.dart';
import '../auth/session_controller.dart';
import '../subscriptions/vendor_subscriptions_pages.dart'
    show subscriptionAmount;
import 'vendor_settings_controller.dart';

class VendorSettingsPage extends ConsumerStatefulWidget {
  const VendorSettingsPage({super.key, this.section});
  final String? section;
  @override
  ConsumerState<VendorSettingsPage> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<VendorSettingsPage> {
  VendorSettingsController? initialized;
  final form = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  bool sameDay = false;
  String? synced;
  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController c(String key) =>
      fields.putIfAbsent(key, () => TextEditingController());
  Future<bool> confirm() async =>
      await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                  scrollable: true,
                  title: Text(context.l10n.settingsReverifyTitle),
                  content: Text(context.l10n.settingsReverifyWarning),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(context.l10n.settingsCancel)),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(context.l10n.settingsConfirm)),
                  ])) ??
      false;
  @override
  Widget build(BuildContext context) {
    final m = ref.watch(vendorSettingsProvider),
        l = context.l10n,
        p = m.profile,
        section = widget.section;
    if (initialized != m) {
      initialized = m;
      if (p == null || m.stale) Future.microtask(m.load);
    }
    if (p != null &&
        synced != '${p.id}:${p.settings.version}:${m.pendingKey}') {
      synced = '${p.id}:${p.settings.version}:${m.pendingKey}';
      final values = <String, String>{
        'businessName': p.businessName ?? '',
        'gstin': p.gstin ?? '',
        'addressLine': p.addressLine ?? '',
        'city': p.city ?? '',
        'state': p.state ?? '',
        'pincode': p.pincode ?? '',
        'latitude': '${p.latitude ?? ''}',
        'longitude': '${p.longitude ?? ''}',
        'charge':
            subscriptionAmount(BigInt.from(p.settings.deliveryChargePaise)),
        'minimum': subscriptionAmount(BigInt.from(p.settings.minOrderPaise)),
        'slots': p.settings.timeSlots.join('\n'),
        'cutoff': p.settings.sameDayCutoff ?? ''
      };
      sameDay = p.settings.acceptingToday;
      final pending = m.pendingPayload;
      if (pending != null && m.pendingKind == 'business') {
        for (final key in [
          'businessName',
          'gstin',
          'addressLine',
          'city',
          'state',
          'pincode',
          'latitude',
          'longitude'
        ]) {
          values[key] = '${pending[key] ?? ''}';
        }
      } else if (pending != null && m.pendingKind == 'delivery') {
        values['charge'] = subscriptionAmount(
            BigInt.from(pending['deliveryChargePaise'] as int));
        values['minimum'] =
            subscriptionAmount(BigInt.from(pending['minOrderPaise'] as int));
        values['slots'] = (pending['timeSlots'] as List).join('\n');
        values['cutoff'] = pending['sameDayCutoff'] as String? ?? '';
        sameDay = pending['acceptingToday'] as bool;
      }
      for (final e in values.entries) {
        c(e.key).text = e.value;
      }
    }
    final disabled = m.busy || m.stale || m.pending;
    Widget row(String label, String? path) => ListTile(
        minVerticalPadding: 16,
        title: Text(label),
        enabled: path != null,
        subtitle: path == null ? Text(l.dashAvailableSoon) : null,
        trailing: path == null ? null : const Icon(Icons.chevron_right),
        onTap: path == null
            ? null
            : () async {
                await context.push(path);
                await m.load();
              });
    Widget input(String key, String label,
            {int max = 120,
            String? pattern,
            bool optional = false,
            bool money = false,
            int? coordinate,
            int lines = 1}) =>
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextFormField(
                controller: c(key),
                enabled: !disabled,
                maxLength: max,
                maxLines: lines,
                decoration: InputDecoration(
                    labelText: label, border: const OutlineInputBorder()),
                autocorrect: false,
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (optional && s.isEmpty) return null;
                  if (s.isEmpty ||
                      pattern != null && !RegExp(pattern).hasMatch(s) ||
                      money && settingsPaise(s) == null) {
                    return l.onboardingInvalid;
                  }
                  if (coordinate != null) {
                    final n = num.tryParse(s);
                    if (n == null || !n.isFinite || n.abs() > coordinate) {
                      return l.onboardingInvalid;
                    }
                  }
                  return null;
                }));
    Future<void> save() async {
      if (!form.currentState!.validate() || p == null) return;
      if (section == 'business') {
        if (c('businessName').text.trim() != p.businessName &&
            !await confirm()) {
          return;
        }
        await m.save(
            'business',
            VendorBusinessEditDto(
                    version: p.settings.version,
                    businessName: c('businessName').text.trim(),
                    gstin: c('gstin').text.trim().toUpperCase(),
                    addressLine: c('addressLine').text.trim(),
                    city: c('city').text.trim(),
                    state: c('state').text.trim(),
                    pincode: c('pincode').text.trim(),
                    latitude: num.parse(c('latitude').text.trim()),
                    longitude: num.parse(c('longitude').text.trim()),
                    shopPhotoMediaId: p.shopPhotoMediaId)
                .toJson());
      } else {
        final slots = c('slots')
            .text
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        await m.save(
            'delivery',
            VendorDeliveryDto(
                    version: p.settings.version,
                    deliveryChargePaise:
                        settingsPaise(c('charge').text.trim())!,
                    minOrderPaise: settingsPaise(c('minimum').text.trim())!,
                    timeSlots: slots,
                    acceptingToday: sameDay,
                    sameDayCutoff: c('cutoff').text.trim().isEmpty
                        ? null
                        : c('cutoff').text.trim())
                .toJson());
      }
    }

    return Scaffold(
        appBar: AppBar(
            title: Text(section == 'business'
                ? l.settingsBusiness
                : section == 'delivery'
                    ? l.settingsDelivery
                    : l.dashVendorSettings)),
        body: SafeArea(
            child: RefreshIndicator(
                onRefresh: m.load,
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (m.busy) const SbSkeleton(lines: 2),
                      if (m.failure != null)
                        Semantics(
                            liveRegion: true,
                            child: Text(m.failure!.toMessage(l))),
                      if (m.stale && p != null) Text(l.settingsOffline),
                      if (m.cacheUnavailable) Text(l.dashCacheUnavailable),
                      if (section == null && p != null)
                        Text(switch (p.kycStatus) {
                          'VERIFIED' => l.onboardingVerified,
                          'REJECTED' => l.onboardingRejected,
                          'PENDING' || 'MANUAL_REVIEW' => l.onboardingReview,
                          _ => l.onboardingNotVerified,
                        }),
                      SbButton(
                          label: l.onboardingRefresh,
                          onPressed: m.busy ? null : m.load),
                      if (m.pending) ...[
                        Text(l.settingsFrozen),
                        SbButton(
                            label: l.settingsRetry,
                            onPressed: m.busy || m.stale || m.terminal
                                ? null
                                : m.retry),
                        if (m.terminal)
                          SbButton(
                              label: l.settingsReviewConflict,
                              onPressed: m.busy ? null : m.reviewConflict)
                      ],
                      if (section == null) ...[
                        row(l.settingsProfile, '/account/profile'),
                        row(l.settingsBusiness, '/vendor/settings/business'),
                        row(l.settingsKyc, '/vendor/settings/kyc'),
                        row(l.areaTitle, const ServiceAreaRoute().location),
                        row(l.settingsDelivery, '/vendor/settings/delivery'),
                        row(
                            l.notificationsPreferences,
                            const CommonRoute(CommonPage.notifications)
                                .location),
                        row(l.dashSubscriptions,
                            '/vendor/subscription-settings'),
                        row(l.dashPlans, '/vendor/plans'),
                        row(l.authPrivacy, '/account/legal/PRIVACY'),
                        row(l.authTerms, '/account/legal/TERMS'),
                        row(l.dashHelp, '/account/help'),
                        row(l.settingsSwitch,
                            const CommonRoute(CommonPage.switchRole).location),
                        ListTile(
                            minVerticalPadding: 16,
                            title: Text(l.authLogout),
                            onTap: m.busy
                                ? null
                                : () async {
                                    await ref
                                        .read(sessionProvider.notifier)
                                        .logout();
                                    if (!context.mounted) return;
                                    final failure =
                                        ref.read(sessionProvider).failure;
                                    if (failure != null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content:
                                                  Text(failure.toMessage(l))));
                                    }
                                  }),
                        row(l.settingsDelete,
                            const AccountDeletionRoute().location),
                      ] else if (p != null)
                        Form(
                            key: form,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (section == 'business') ...[
                                    Text(l.settingsReverifyWarning),
                                    input('businessName',
                                        l.onboardingBusinessName,
                                        max: 80),
                                    input('gstin', l.onboardingGstin,
                                        max: 15,
                                        optional: true,
                                        pattern:
                                            r'^\d{2}[A-Z]{5}\d{4}[A-Z][1-9A-Z]Z[0-9A-Z]$'),
                                    input('addressLine', l.onboardingAddress,
                                        max: 200),
                                    input('city', l.onboardingCity),
                                    input('state', l.onboardingState),
                                    input('pincode', l.onboardingPincode,
                                        max: 6, pattern: r'^[1-9]\d{5}$'),
                                    input('latitude', l.onboardingLatitude,
                                        coordinate: 90),
                                    input('longitude', l.onboardingLongitude,
                                        coordinate: 180),
                                  ] else ...[
                                    Text(l.settingsDeliveryInfo),
                                    input('charge', l.settingsCharge,
                                        money: true, max: 12),
                                    input('minimum', l.settingsMinimum,
                                        money: true, max: 12),
                                    Text(l.settingsSlotHelp),
                                    input('slots', l.settingsSlots,
                                        max: 200, optional: true, lines: 4),
                                    SwitchListTile(
                                        title: Text(l.settingsSameDay),
                                        value: sameDay,
                                        onChanged: disabled
                                            ? null
                                            : (v) =>
                                                setState(() => sameDay = v)),
                                    input('cutoff', l.settingsCutoff,
                                        max: 5,
                                        optional: !sameDay,
                                        pattern:
                                            r'^(?:[01]\d|2[0-3]):[0-5]\d$'),
                                    row(l.availabilityTitle,
                                        '/vendor/availability'),
                                  ],
                                  SbButton(
                                      label: l.settingsSave,
                                      onPressed: disabled ? null : save),
                                ])),
                    ]))));
  }
}
