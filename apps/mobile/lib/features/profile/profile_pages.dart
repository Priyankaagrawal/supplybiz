// T-126 / S-C-27/33/36. No deferred finance/referral/payment-method navigation.
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../core/config/app_config.dart';
import '../../core/l10n/l10n.dart';
import '../../core/router/routes.dart';
import '../../core/storage/onboarding_device.dart';
import '../auth/session_controller.dart';
import 'profile_controller.dart';

class AccountProfilePage extends ConsumerStatefulWidget {
  const AccountProfilePage({super.key, this.section, this.customer = false});
  final String? section;
  final bool customer;
  @override
  ConsumerState<AccountProfilePage> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<AccountProfilePage> {
  ProfileController? initialized;
  final form = GlobalKey<FormState>(),
      name = TextEditingController(),
      email = TextEditingController();
  String? synced, localError;
  bool picking = false;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    super.dispose();
  }

  Future<void> photo(ProfileController m) async {
    setState(() => picking = true);
    try {
      final value = await const OnboardingDevice().pick();
      if (!mounted || value == null) return;
      if (value['pdf'] == true) {
        setState(() => localError = context.l10n.profilePhotoOnly);
        return;
      }
      await m.upload(value['bytes'] as Uint8List);
    } catch (_) {
      if (mounted) {
        setState(() => localError = context.l10n.onboardingFileError);
      }
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  Future<void> logout() async {
    await ref.read(sessionProvider.notifier).logout();
    if (!mounted) return;
    final f = ref.read(sessionProvider).failure;
    if (f != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.toMessage(context.l10n))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = ref.watch(profileProvider),
        l = context.l10n,
        p = m.profile,
        edit = widget.section == 'edit',
        settings = widget.section == 'settings';
    if (initialized != m) {
      initialized = m;
      if (p == null || m.stale) Future.microtask(m.load);
    }
    final stamp = '${p?.id}:${p?.updatedAt}:${m.pendingKey}';
    if (p != null && synced != stamp) {
      synced = stamp;
      final body = m.pendingBody;
      name.text = body?['name'] as String? ?? p.name ?? '';
      email.text = body?['email'] as String? ?? p.email ?? '';
    }
    final disabled = m.busy || picking || m.stale || m.pending;
    Widget row(String label, String? path) => ListTile(
        minVerticalPadding: 16,
        title: Text(label),
        enabled: path != null,
        subtitle: path == null ? Text(l.dashAvailableSoon) : null,
        trailing: path == null ? null : const Icon(Icons.chevron_right),
        onTap: path == null ? null : () => context.push(path));
    Widget avatar() => Semantics(
        image: true,
        label: l.profilePhoto,
        child: SizedBox(
            height: 96,
            width: 96,
            child: m.photo == null
                ? const Icon(Icons.person_outline, size: 64)
                : Image.memory(m.photo!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person_outline, size: 64))));
    return Scaffold(
        appBar: AppBar(
            title: Text(edit
                ? l.profileEdit
                : settings
                    ? l.routeSettings
                    : l.navProfile)),
        body: SafeArea(
            child: RefreshIndicator(
                onRefresh: m.load,
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (m.busy || picking) const SbSkeleton(lines: 2),
                      if (m.failure != null)
                        Semantics(
                            liveRegion: true,
                            child: Text(m.failure!.toMessage(l))),
                      if (m.stale && p != null) Text(l.profileOffline),
                      if (m.cacheUnavailable) Text(l.dashCacheUnavailable),
                      if (m.photoUnavailable) Text(l.profilePhotoUnavailable),
                      if (localError != null) Text(localError!),
                      SbButton(
                          label: l.onboardingRefresh,
                          onPressed: m.busy || picking ? null : m.load),
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
                              onPressed: m.busy ? null : m.review)
                      ],
                      if (edit && p != null) ...[
                        avatar(),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          SbButton(
                              label: l.profileChoosePhoto,
                              onPressed: disabled ? null : () => photo(m)),
                          SbButton(
                              label: l.profileRemovePhoto,
                              onPressed: disabled || m.selectedPhoto == null
                                  ? null
                                  : m.removePhoto)
                        ]),
                        if (m.photoStaged) Text(l.profilePhotoStaged),
                        Text(l.profileEmailNote),
                        Form(
                            key: form,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextFormField(
                                      controller: name,
                                      enabled: !disabled,
                                      maxLength: 120,
                                      decoration: InputDecoration(
                                          labelText: l.profileName),
                                      validator: (s) => (s ?? '').trim().isEmpty
                                          ? l.onboardingInvalid
                                          : null),
                                  TextFormField(
                                      controller: email,
                                      enabled: !disabled,
                                      maxLength: 254,
                                      keyboardType: TextInputType.emailAddress,
                                      autocorrect: false,
                                      decoration: InputDecoration(
                                          labelText: l.profileEmail),
                                      validator: (s) {
                                        final v = (s ?? '').trim();
                                        return v.isEmpty ||
                                                RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                                    .hasMatch(v)
                                            ? null
                                            : l.onboardingInvalid;
                                      }),
                                  Text(l.profileMobile),
                                  SelectableText(p.mobile),
                                  Text(l.profileMobileReadOnly),
                                  SbButton(
                                      label: l.profileSave,
                                      onPressed: disabled
                                          ? null
                                          : () {
                                              if (form.currentState!
                                                  .validate()) {
                                                m.save(name.text, email.text);
                                              }
                                            }),
                                ])),
                      ] else if (settings) ...[
                        row(
                            l.notificationsPreferences,
                            const CommonRoute(CommonPage.notifications)
                                .location),
                        row(l.profileSwitchRole,
                            const CommonRoute(CommonPage.switchRole).location),
                        row(l.profileAbout, '/account/about'),
                        SbButton(
                            label: l.profileClearCache,
                            onPressed: m.busy
                                ? null
                                : () async {
                                    final yes = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                                scrollable: true,
                                                title:
                                                    Text(l.profileClearCache),
                                                content:
                                                    Text(l.profileCacheHelp),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              ctx, false),
                                                      child: Text(
                                                          l.settingsCancel)),
                                                  FilledButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              ctx, true),
                                                      child: Text(
                                                          l.profileClearCache))
                                                ]));
                                    if (yes == true) await m.clearCache();
                                  }),
                        row(l.settingsDelete, null),
                        SbButton(
                            label: l.authLogout,
                            onPressed: m.busy ? null : logout),
                      ] else if (p != null) ...[
                        avatar(),
                        Text(p.name ?? l.profileNameMissing,
                            style: Theme.of(context).textTheme.titleLarge),
                        SelectableText(p.mobile),
                        Text(p.email ?? l.profileNoEmail),
                        row(l.profileEdit, '/account/profile/edit'),
                        if (widget.customer)
                          row(l.profileAddresses,
                              const CustomerAddressesRoute().location),
                        row(l.routeSettings, '/account/settings'),
                        row(l.profileAbout, '/account/about'),
                        row(l.dashHelp, null),
                      ] else if (!m.busy)
                        Text(l.profileUnavailable),
                    ]))));
  }
}

final profileVersionProvider = FutureProvider.autoDispose<String>(
    (ref) => ref.read(androidAppInfoProvider).version());

class ProfileAboutPage extends ConsumerWidget {
  const ProfileAboutPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n,
        version = ref.watch(profileVersionProvider).asData?.value;
    return Scaffold(
        appBar: AppBar(title: Text(l.profileAbout)),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(16), children: [
          Text(l.appName, style: Theme.of(context).textTheme.headlineSmall),
          Text(l.profileVersion(version ?? l.profileUnknownVersion)),
          SbButton(
              label: l.profileLicenses,
              onPressed: () => showLicensePage(
                  context: context,
                  applicationName: l.appName,
                  applicationVersion: version)),
          SbButton(
              label: l.authTerms,
              onPressed: () => context.push('/account/legal/TERMS')),
          SbButton(
              label: l.authPrivacy,
              onPressed: () => context.push('/account/legal/PRIVACY')),
        ])));
  }
}

class ProfileLegalPage extends ConsumerStatefulWidget {
  const ProfileLegalPage({required this.type, super.key});
  final String type;
  @override
  ConsumerState<ProfileLegalPage> createState() => _LegalState();
}

class _LegalState extends ConsumerState<ProfileLegalPage> {
  ProfileLegalController? initialized;
  @override
  Widget build(BuildContext context) {
    final m = ref.watch(profileLegalProvider(widget.type)),
        l = context.l10n,
        v = m.value;
    if (initialized != m) {
      initialized = m;
      if (m.value == null || m.stale) Future.microtask(m.load);
    }
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.type == 'TERMS' ? l.authTerms : l.authPrivacy)),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(16), children: [
          if (m.busy) const SbSkeleton(lines: 3),
          if (m.failure != null) Text(l.profileLegalUnavailable),
          if (m.stale && v != null) Text(l.profileLegalStale),
          SbButton(label: l.authRetry, onPressed: m.busy ? null : m.load),
          if (v != null) ...[
            Text(v.title, style: Theme.of(context).textTheme.titleLarge),
            Text(l.profileLegalVersion(v.version)),
            SelectableText(v.text)
          ],
        ])));
  }
}
