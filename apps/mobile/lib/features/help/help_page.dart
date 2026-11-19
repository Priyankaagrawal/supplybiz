// T-107 / FR-133/134/296. Read-only English CMS; contacts intentionally unpublished.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import 'help_controller.dart';

String helpTopic(AppLocalizations l, String topic) => switch (topic) {
      'orders' => l.helpOrders,
      'payments' => l.helpPayments,
      'delivery' => l.helpDelivery,
      'account' => l.helpAccount,
      'kyc' => l.helpKyc,
      'general' => l.helpGeneral,
      _ => topic.replaceAll('-', ' '),
    };

class HelpPage extends ConsumerStatefulWidget {
  const HelpPage({super.key});
  @override
  ConsumerState<HelpPage> createState() => _HelpState();
}

class _HelpState extends ConsumerState<HelpPage> {
  HelpController? initialized;
  @override
  Widget build(BuildContext context) {
    final m = ref.watch(helpProvider), l = context.l10n, v = m.value;
    if (initialized != m) {
      initialized = m;
      if (v == null || m.stale) Future.microtask(m.load);
    }
    Widget topic(String? slug) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: FilterChip(
            label: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.6),
                child: Text(slug == null ? l.helpAll : helpTopic(l, slug))),
            selected: m.topic == slug,
            materialTapTargetSize: MaterialTapTargetSize.padded,
            onSelected: m.busy
                ? null
                : (_) => m.load(topic: slug, offset: 0, all: slug == null)));
    return Scaffold(
        appBar: AppBar(title: Text(l.helpTitle)),
        body: SafeArea(
            child: RefreshIndicator(
                onRefresh: m.load,
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (m.busy) const SbSkeleton(lines: 3),
                      if (m.failure != null)
                        Semantics(
                            liveRegion: true, child: Text(l.helpUnavailable)),
                      if (m.stale && v != null) Text(l.helpOffline),
                      if (m.cacheUnavailable) Text(l.helpCacheUnavailable),
                      if (m.downloadedAt != null)
                        Text(l.helpDownloaded(m.downloadedAt!
                            .toUtc()
                            .toIso8601String()
                            .replaceFirst('T', ' ')
                            .substring(0, 16))),
                      SbButton(
                          label: l.authRetry,
                          onPressed: m.busy ? null : m.load),
                      Text(l.helpTopics,
                          style: Theme.of(context).textTheme.titleLarge),
                      Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [topic(null), ...m.topics.map(topic)]),
                      Text(l.helpFaqs,
                          style: Theme.of(context).textTheme.titleLarge),
                      if (v != null) ...[
                        if (v.items.isEmpty) Text(l.helpEmpty),
                        for (final row in v.items)
                          Card(
                              child: ExpansionTile(
                                  key: ValueKey(
                                      '${m.topic}:${m.offset}:${row.id}:${row.updatedAt}'),
                                  title: Text(row.question),
                                  subtitle: Text(helpTopic(l, row.topic)),
                                  childrenPadding: const EdgeInsets.all(16),
                                  expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [SelectableText(row.answer)])),
                        Text(l.helpCount(
                            (m.offset + v.items.length)
                                .clamp(0, v.total)
                                .toInt(),
                            v.total)),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          SbButton(
                              label: l.reportsPrevious,
                              onPressed: m.busy || m.offset == 0
                                  ? null
                                  : () => m.load(
                                      offset: (m.offset - 20)
                                          .clamp(0, 100000)
                                          .toInt())),
                          SbButton(
                              label: l.reportsNext,
                              onPressed: m.busy ||
                                      m.offset + 20 >= v.total ||
                                      m.offset + 20 > 100000
                                  ? null
                                  : () => m.load(offset: m.offset + 20)),
                        ]),
                      ],
                      const SizedBox(height: 16),
                      Text(l.helpContact,
                          style: Theme.of(context).textTheme.titleLarge),
                      Text(l.helpContactsUnavailable),
                      // TODO(Q-30): publish verified phone/email/hours before wiring contact intents.
                      // User explicitly requested TBD; never use fabricated numbers or email addresses.
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        SbButton(label: l.helpCall, onPressed: null),
                        SbButton(label: l.helpEmail, onPressed: null)
                      ]),
                      Text(l.helpLegal,
                          style: Theme.of(context).textTheme.titleLarge),
                      SbButton(
                          label: l.authTerms,
                          onPressed: () =>
                              context.push('/account/legal/TERMS')),
                      SbButton(
                          label: l.authPrivacy,
                          onPressed: () =>
                              context.push('/account/legal/PRIVACY')),
                    ]))));
  }
}
