// S-V-22 / T-077. Open-ended pause follows FR-084 and the T-074 contract.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supplybiz_api_client/supplybiz_api_client.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import '../subscriptions/vendor_subscriptions_controller.dart'
    show subscriptionDate, subscriptionParseDate;
import 'availability_controller.dart';

class AvailabilityPage extends ConsumerStatefulWidget {
  const AvailabilityPage({super.key});
  @override
  ConsumerState<AvailabilityPage> createState() => _AvailabilityState();
}

class _AvailabilityState extends ConsumerState<AvailabilityPage>
    with WidgetsBindingObserver {
  AvailabilityController? initialized;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) ref.read(availabilityProvider).load();
  }

  @override
  Widget build(BuildContext context) {
    final m = ref.watch(availabilityProvider), l = context.l10n, s = m.state;
    if (initialized != m) {
      initialized = m;
      Future.microtask(m.load);
    }
    final error = switch (m.failure?.code) {
      'PLAN_FEATURE_LOCKED' => l.availabilityPlanLocked,
      'VERSION_CONFLICT' => l.availabilityConflict,
      'HOLIDAY_EXISTS' => l.availabilityExists,
      'HOLIDAY_NOT_FUTURE' => l.availabilityFutureOnly,
      _ => m.failure?.toMessage(l)
    };
    return Scaffold(
        appBar: AppBar(title: Text(l.availabilityTitle)),
        body: SafeArea(
            child: RefreshIndicator(
                onRefresh: m.load,
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (m.busy) const SbSkeleton(lines: 2),
                      if (error != null)
                        Semantics(liveRegion: true, child: Text(error)),
                      if (m.stale) Text(l.subOffline),
                      if (m.pending != null) ...[
                        Text(l.subSaved),
                        SbButton(
                            label: l.subRetry,
                            onPressed: m.busy ? null : m.retry)
                      ],
                      if (m.completed)
                        Semantics(
                            liveRegion: true,
                            child: Text(m.cancelledOrders == null
                                ? l.availabilitySaved
                                : l.availabilityCancelled(m.cancelledOrders!))),
                      SbButton(
                          label: l.authRetry,
                          onPressed: m.busy ? null : m.load),
                      if (s != null) ...[
                        Text(l.availabilityBusinessDate(
                            subscriptionDate(s.businessDate))),
                        SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(l.availabilityAccepting),
                            subtitle: Text(l.availabilityAcceptingInfo),
                            value: s.acceptingToday,
                            onChanged:
                                (s.acceptingToday ? m.canReduce : m.canResume)
                                    ? (v) => _accepting(m, v)
                                    : null),
                        Text(
                            s.deliveryPaused
                                ? l.availabilityPaused
                                : l.availabilityRunning,
                            style: Theme.of(context).textTheme.titleMedium),
                        if (s.deliveryPausedUntil != null)
                          Text(l.availabilityLegacyEnd(
                              DateFormat('yMMMd HH:mm', 'en').format(
                                  s.deliveryPausedUntil!.toUtc().add(
                                      const Duration(hours: 5, minutes: 30))))),
                        Text(l.availabilityPauseInfo),
                        SbButton(
                            label: l.availabilityPause,
                            onPressed: m.canReduce && !s.deliveryPaused
                                ? () => _pause(m)
                                : null),
                        SbButton(
                            label: l.availabilityResume,
                            onPressed: m.canResume && s.deliveryPaused
                                ? () => _resume(m)
                                : null),
                        if (!s.canResume) Text(l.availabilityPlanLocked),
                        SbButton(
                            label: l.availabilityMarkHoliday,
                            onPressed: m.canReduce ? () => _holiday(m) : null),
                        Text(l.discoveryHolidays,
                            style: Theme.of(context).textTheme.titleLarge),
                        if (m.holidays.isEmpty)
                          SbEmpty(message: l.discoveryNoHolidays),
                        for (final h in m.visible)
                          Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(subscriptionDate(h.date)),
                                        Text(h.reason),
                                        if (!m.future(h))
                                          Text(l.availabilityFutureOnly),
                                        SbButton(
                                            label: l.availabilityDelete,
                                            onPressed:
                                                m.canResume && m.future(h)
                                                    ? () => _delete(m, h)
                                                    : null)
                                      ]))),
                        if (m.visible.length < m.holidays.length)
                          SbButton(label: l.customerSubMore, onPressed: m.more),
                      ],
                    ]))));
  }

  bool current(AvailabilityController m) =>
      mounted && identical(m, ref.read(availabilityProvider)) && m.canWrite;
  Future<bool> _confirm(String title, String message) {
    final l = context.l10n;
    return showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: Text(title),
                content: SingleChildScrollView(child: Text(message)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: Text(l.productsCancel)),
                  TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: Text(l.customersConfirm))
                ])).then((v) => v == true);
  }

  Future<void> _accepting(AvailabilityController m, bool value) async {
    final version = m.state!.version, l = context.l10n;
    if (await _confirm(l.availabilityAccepting, l.availabilityAcceptingInfo) &&
        current(m) &&
        m.state!.version == version) {
      await m.submit('PATCH', {'version': version, 'acceptingToday': value});
    }
  }

  Future<void> _pause(AvailabilityController m) async {
    final version = m.state!.version;
    final l = context.l10n;
    final impact = await m.impact();
    if (impact == null || !current(m)) return;
    if (await _confirm(l.availabilityPause,
            '${l.availabilityImpact(impact.affectedOrders)}\n${l.availabilityPauseInfo}\n${l.availabilityImpactInfo}') &&
        current(m) &&
        m.state!.version == version) {
      await m.submit('PATCH', {'version': version, 'deliveryPaused': true});
    }
  }

  Future<void> _resume(AvailabilityController m) async {
    final version = m.state!.version, l = context.l10n;
    if (await _confirm(l.availabilityResume, l.availabilityResumeInfo) &&
        current(m) &&
        m.state!.version == version) {
      await m.submit('PATCH', {'version': version, 'deliveryPaused': false});
    }
  }

  Future<void> _delete(AvailabilityController m, HolidayRecord h) async {
    if (await _confirm(context.l10n.availabilityDelete,
            context.l10n.availabilityResumeInfo) &&
        current(m) &&
        m.canResume &&
        m.future(h)) {
      await m.submit('DELETE', {}, id: h.id);
    }
  }

  Future<void> _holiday(AvailabilityController m) async {
    final l = context.l10n;
    final businessDate = m.state!.businessDate;
    final input = await showDialog<({String date, String reason})>(
        context: context,
        builder: (_) => _HolidayEditor(
            businessDate: businessDate, canChoose: () => current(m)));
    if (input == null || !current(m)) return;
    final impact = await m.impact(date: input.date);
    if (impact == null || !current(m)) return;
    if (await _confirm(l.availabilityMarkHoliday,
            '${input.date}\n${input.reason}\n${l.availabilityImpact(impact.affectedOrders)}\n${l.availabilityImpactInfo}') &&
        current(m) &&
        m.canReduce) {
      await m.submit('HOLIDAY', {'date': input.date, 'reason': input.reason});
    }
  }
}

// The dialog owns its fields until its closing animation has unmounted them.
class _HolidayEditor extends StatefulWidget {
  const _HolidayEditor({required this.businessDate, required this.canChoose});
  final DateTime businessDate;
  final bool Function() canChoose;
  @override
  State<_HolidayEditor> createState() => _HolidayEditorState();
}

class _HolidayEditorState extends State<_HolidayEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController date;
  final reason = TextEditingController();
  @override
  void initState() {
    super.initState();
    date = TextEditingController(text: subscriptionDate(widget.businessDate));
  }

  @override
  void dispose() {
    date.dispose();
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
        title: Text(l.availabilityMarkHoliday),
        content: SingleChildScrollView(
            child: Form(
                key: form,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextFormField(
                      controller: date,
                      readOnly: true,
                      decoration:
                          InputDecoration(labelText: l.availabilityDate),
                      onTap: () async {
                        if (!widget.canChoose()) return;
                        final first = DateTime(
                                widget.businessDate.year,
                                widget.businessDate.month,
                                widget.businessDate.day),
                            selected = subscriptionParseDate(date.text)!;
                        final chosen = await showDatePicker(
                            context: context,
                            initialDate: DateTime(
                                selected.year, selected.month, selected.day),
                            firstDate: first,
                            lastDate: DateTime(9999, 12, 31));
                        if (chosen != null && mounted && widget.canChoose()) {
                          date.text = subscriptionDate(chosen);
                        }
                      },
                      validator: (v) => subscriptionParseDate(v ?? '') ==
                                  null ||
                              v!.compareTo(
                                      subscriptionDate(widget.businessDate)) <
                                  0
                          ? l.subInvalid
                          : null),
                  TextFormField(
                      controller: reason,
                      maxLength: 100,
                      decoration: InputDecoration(labelText: l.subReason),
                      validator: (v) =>
                          v == null || v.trim().isEmpty || v.trim().length > 100
                              ? l.subInvalid
                              : null),
                ]))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.productsCancel)),
          TextButton(
              onPressed: () {
                if (widget.canChoose() && form.currentState!.validate()) {
                  Navigator.pop(
                      context, (date: date.text, reason: reason.text.trim()));
                }
              },
              child: Text(l.notificationsContinue))
        ]);
  }
}
