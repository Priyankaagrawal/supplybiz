import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/l10n.dart';
import 'app_config.dart';

/// S-COM-01/06: policy gating wraps all routes, including Back/deep links.
class ConfigGate extends ConsumerStatefulWidget {
  const ConfigGate({required this.child, super.key});
  final Widget child;
  @override
  ConsumerState<ConfigGate> createState() => _ConfigGateState();
}

class _ConfigGateState extends ConsumerState<ConfigGate> {
  bool storeFailed = false;
  Future<void> openStore() async {
    var opened = false;
    try {
      opened = await ref.read(androidAppInfoProvider).openStore();
    } catch (_) {/* Safe localized failure. */}
    if (mounted) setState(() => storeFailed = !opened);
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configProvider);
    if (config.ready && !config.forceUpdate) return widget.child;
    final l10n = context.l10n;
    return PopScope(
        canPop: false,
        child: Scaffold(
            body: SafeArea(
                child: Center(
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (config.forceUpdate) ...[
                    Semantics(
                        header: true,
                        child: Text(l10n.routeUpdate,
                            style: Theme.of(context).textTheme.headlineSmall)),
                    const SizedBox(height: 16),
                    Text(l10n.updateRequired, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: FilledButton(
                            onPressed: openStore,
                            child: Text(l10n.updateAction))),
                    if (storeFailed)
                      Text(l10n.updateStoreUnavailable,
                          textAlign: TextAlign.center),
                  ] else if (config.loading) ...[
                    const CircularProgressIndicator(),
                    Text(l10n.routeLoading),
                  ] else
                    Text(l10n.configUnavailable, textAlign: TextAlign.center),
                  if (!config.loading)
                    ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: TextButton(
                            onPressed: () =>
                                ref.read(configProvider.notifier).load(),
                            child: Text(l10n.authRetry))),
                ],
              )),
        ))));
  }
}
