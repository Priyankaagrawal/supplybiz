import 'package:flutter/material.dart';
import '../tokens/sb_tokens.dart';

/// Always-labelled bottom navigation, with at most five destinations.
class SbBottomNav extends StatelessWidget {
  const SbBottomNav({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  }) : assert(items.length >= 2 && items.length <= 5);
  final List<NavigationDestination> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => Material(
        elevation: 2,
        color: SbColors.surface,
        child: SafeArea(
          top: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(
                  child: Semantics(
                    selected: index == selectedIndex,
                    button: true,
                    child: InkWell(
                      onTap: () => onSelected(index),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              index == selectedIndex
                                  ? (items[index].selectedIcon ??
                                      items[index].icon)
                                  : items[index].icon,
                              Text(
                                items[index].label,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}

/// Ordered steps; vertical layout allows labels to wrap at large text scales.
class SbStepper extends StatelessWidget {
  const SbStepper({
    required this.steps,
    required this.currentStep,
    this.horizontal = false,
    super.key,
  });
  const SbStepper.horizontal({
    required this.steps,
    required this.currentStep,
    super.key,
  }) : horizontal = true;
  final List<String> steps;
  final int currentStep;
  final bool horizontal;
  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      for (var i = 0; i < steps.length; i++)
        Semantics(
          selected: i == currentStep,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              children: [
                Icon(
                  i < currentStep
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_checked_rounded,
                  color: SbColors.primaryStrong,
                ),
                Text(steps[i]),
              ],
            ),
          ),
        ),
    ];
    return horizontal
        ? Wrap(children: children)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          );
  }
}
