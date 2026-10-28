import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui_kit/ui_kit.dart';

Future<void> loadTestLocalizations() async {
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
  for (final family in ['NotoSans', 'NotoSansDevanagari']) {
    final loader = FontLoader('packages/ui_kit/$family');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(
          rootBundle.load('packages/ui_kit/assets/fonts/$family-$weight.ttf'));
    }
    await loader.load();
  }
  for (final locale in SbLocalizations.supportedLocales) {
    for (final delegate in SbLocalizations.delegates) {
      await delegate.load(locale);
    }
  }
}

Widget testApp(Widget child, {String language = 'en', double scale = 1}) =>
    MaterialApp(
      locale: Locale(language),
      supportedLocales: SbLocalizations.supportedLocales,
      localizationsDelegates: SbLocalizations.delegates,
      theme: sbLightTheme(Locale(language)),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );

List<Widget> catalog(String language) {
  final hi = language == 'hi';
  final label = hi ? 'जारी रखें' : 'Continue';
  final name = hi ? 'गाय का दूध' : 'Cow milk';
  return [
    for (final variant in SbButtonVariant.values)
      SbButton(label: label, onPressed: () {}, variant: variant),
    for (final size in SbButtonSize.values)
      SbButton(
          label: label,
          onPressed: () {},
          size: size,
          variant: size == SbButtonSize.small
              ? SbButtonVariant.secondary
              : SbButtonVariant.primary),
    SbButton(label: label, onPressed: () {}, loading: true),
    SbButton(label: label, onPressed: null),
    SbIconButton(
      icon: Icons.add_rounded,
      semanticLabel: label,
      onPressed: () {},
    ),
    SbTextField(label: name, helper: label),
    SbTextField(label: name, error: label, kind: SbTextFieldKind.amount),
    SbTextField(label: name, kind: SbTextFieldKind.numeric, maxLength: 4),
    SbOtpField(onChanged: (_) {}),
    SbQuantityStepper(value: 2, max: 5, onChanged: (_) {}),
    SbFilterChips(
      labels: [name, label],
      counts: const [3, 1],
      selected: 0,
      onSelected: (_) {},
    ),
    for (final status in SbStatus.values) SbStatusBadge(status),
    SbMetricTile(label: name, value: '₹1,20,000', delta: '+2'),
    SbCard(child: Text(name)),
    SbListTile(title: name, subtitle: label, onTap: () {}),
    SbProductRow(
      name: name,
      unit: '1 L',
      pricePaise: 5050,
      quantity: 2,
      onChanged: (_) {},
    ),
    SbProductRow(
      name: name,
      unit: '1 L',
      pricePaise: 5000,
      quantity: 0,
      onChanged: (_) {},
    ),
    const SbAmountText(12000000),
    const SbAmountText(-5050),
    SbDateSelector(
      value: DateTime(2026, 10, 28),
      firstDate: DateTime(2026),
      lastDate: DateTime(2027),
      onChanged: (_) {},
    ),
    SbMonthSelector(
      value: DateTime(2026, 10),
      months: [DateTime(2026, 10), DateTime(2026, 11)],
      onChanged: (_) {},
    ),
    SbTimeSlotPicker(
      slots: const ['07:00–09:00', '09:00–11:00'],
      selected: 0,
      onSelected: (_) {},
    ),
    SbWeekdayPicker(
      labels: hi
          ? const [
              'सोमवार',
              'मंगलवार',
              'बुधवार',
              'गुरुवार',
              'शुक्रवार',
              'शनिवार',
              'रविवार',
            ]
          : const [
              'Monday',
              'Tuesday',
              'Wednesday',
              'Thursday',
              'Friday',
              'Saturday',
              'Sunday',
            ],
      selected: const {1, 3},
      onChanged: (_) {},
    ),
    SbBottomSheet(child: Text(name)),
    Builder(
        builder: (context) => SbDialog.adaptive(
            context: context, title: name, message: label, destructive: true)),
    SbSearchBar(onChanged: (_) {}),
    SbEmpty(actionLabel: label, onAction: () {}),
    SbError(onRetry: () {}),
    const SbSkeleton(),
    const SbOfflineBanner(),
    SbLockedFeature(onUpgrade: () {}, child: Text(name)),
    const SbSyncChip(pendingCount: 2),
    const SbSyncChip(pendingCount: 0),
    SbStepper(steps: [name, label], currentStep: 1),
    SbStepper.horizontal(steps: [name, label], currentStep: 0),
    SbUploadField(
      label: name,
      pickFile: () async => null,
      onSelected: (_) {},
      allowedTypes: const {'image/png'},
      maxBytes: 1024,
      progress: 0.5,
    ),
    for (final kind in SbChartKind.values)
      SbChart(
        kind: kind,
        data: [SbChartDatum(label: name, value: 10, formattedValue: '10')],
      ),
    SbBottomNav(
      items: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          label: name,
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          label: label,
        ),
      ],
      selectedIndex: 0,
      onSelected: (_) {},
    ),
  ];
}
