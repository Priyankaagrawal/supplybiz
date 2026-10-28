import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../sb_localizations.dart';
import '../tokens/sb_tokens.dart';
import 'sb_controls.dart';
import 'sb_filters.dart';

/// Date selection with native locale labels; dates represent calendar dates.
class SbDateSelector extends StatelessWidget {
  const SbDateSelector({
    required this.value,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
    super.key,
  });
  final DateTime value, firstDate, lastDate;
  final ValueChanged<DateTime> onChanged;
  @override
  Widget build(BuildContext context) => SbButton(
        label: MaterialLocalizations.of(context).formatMediumDate(value),
        variant: SbButtonVariant.secondary,
        onPressed: () async {
          if (Theme.of(context).platform == TargetPlatform.iOS) {
            var selected = value;
            final result = await showCupertinoModalPopup<DateTime>(
              context: context,
              builder: (sheetContext) => Material(
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 216,
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.date,
                          initialDateTime: value,
                          minimumDate: firstDate,
                          maximumDate: lastDate,
                          onDateTimeChanged: (date) => selected = date,
                        ),
                      ),
                      SbButton(
                        label: SbLocalizations.of(context).text('confirm'),
                        onPressed: () => Navigator.pop(sheetContext, selected),
                      ),
                    ],
                  ),
                ),
              ),
            );
            if (result != null) onChanged(result);
            return;
          }
          final result = await showDatePicker(
            context: context,
            initialDate: value,
            firstDate: firstDate,
            lastDate: lastDate,
          );
          if (result != null) onChanged(result);
        },
      );
}

/// Month selection bounded to an explicitly provided range.
class SbMonthSelector extends StatelessWidget {
  const SbMonthSelector({
    required this.value,
    required this.months,
    required this.onChanged,
    super.key,
  });
  final DateTime value;
  final List<DateTime> months;
  final ValueChanged<DateTime> onChanged;
  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        children: [
          for (final month in months)
            SbChip(
              label: MaterialLocalizations.of(context).formatMonthYear(month),
              selected: month.year == value.year && month.month == value.month,
              onSelected: (_) => onChanged(month),
            ),
        ],
      );
}

/// Server-provided time-slot labels with wrapping selection.
class SbTimeSlotPicker extends StatelessWidget {
  const SbTimeSlotPicker({
    required this.slots,
    required this.selected,
    required this.onSelected,
    super.key,
  });
  final List<String> slots;
  final int selected;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) =>
      SbFilterChips(labels: slots, selected: selected, onSelected: onSelected);
}

/// ISO weekday selection (Monday = 1); labels come from the caller's l10n.
class SbWeekdayPicker extends StatelessWidget {
  const SbWeekdayPicker({
    required this.labels,
    required this.selected,
    required this.onChanged,
    super.key,
  }) : assert(labels.length == 7);
  final List<String> labels;
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;
  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        children: [
          for (var day = 1; day <= 7; day++)
            SbChip(
              label: labels[day - 1],
              selected: selected.contains(day),
              onSelected: (enabled) {
                final next = {...selected};
                enabled ? next.add(day) : next.remove(day);
                onChanged(Set.unmodifiable(next));
              },
            ),
        ],
      );
}

/// Scrollable safe-area bottom sheet with keyboard insets.
class SbBottomSheet extends StatelessWidget {
  const SbBottomSheet({required this.child, super.key});
  final Widget child;
  static Future<T?> show<T>(BuildContext context, Widget child) =>
      showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(SbRadius.sheet),
          ),
        ),
        builder: (_) => SbBottomSheet(child: child),
      );
  @override
  Widget build(BuildContext context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      );
}

/// Adaptive confirm/destructive dialog naming the affected object in its title.
class SbDialog {
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    bool destructive = false,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => SbDialog.adaptive(
          context: dialogContext,
          title: title,
          message: message,
          destructive: destructive,
        ),
      ) ??
      false;

  static Widget adaptive({
    required BuildContext context,
    required String title,
    required String message,
    bool destructive = false,
  }) {
    final strings = SbLocalizations.of(context);
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.text('cancel')),
          ),
          CupertinoDialogAction(
            isDestructiveAction: destructive,
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.text('confirm')),
          ),
        ],
      );
    }
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      scrollable: true,
      actions: [
        SbButton(
          label: strings.text('cancel'),
          size: SbButtonSize.medium,
          variant: SbButtonVariant.tertiary,
          onPressed: () => Navigator.pop(context, false),
        ),
        SbButton(
          label: strings.text('confirm'),
          size: SbButtonSize.medium,
          variant: destructive
              ? SbButtonVariant.destructive
              : SbButtonVariant.primary,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}
