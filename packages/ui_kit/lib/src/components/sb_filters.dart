import 'dart:async';
import 'package:flutter/material.dart';
import '../sb_localizations.dart';

/// Wrapping filter chip with optional result count.
class SbChip extends StatelessWidget {
  const SbChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.count,
    super.key,
  });
  final String label;
  final int? count;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  @override
  Widget build(BuildContext context) => FilterChip(
        label: Text(count == null ? label : '$label ($count)'),
        selected: selected,
        onSelected: onSelected,
        materialTapTargetSize: MaterialTapTargetSize.padded,
      );
}

/// Wrapping filters; callers own selection and localized labels.
class SbFilterChips extends StatelessWidget {
  const SbFilterChips({
    required this.labels,
    required this.selected,
    required this.onSelected,
    this.counts,
    super.key,
  });
  final List<String> labels;
  final int selected;
  final List<int>? counts;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        children: [
          for (var i = 0; i < labels.length; i++)
            SbChip(
              label: labels[i],
              count: counts?[i],
              selected: selected == i,
              onSelected: (_) => onSelected(i),
            ),
        ],
      );
}

/// Search input that cancels pending callbacks on disposal.
class SbSearchBar extends StatefulWidget {
  const SbSearchBar({required this.onChanged, super.key});
  final ValueChanged<String> onChanged;
  @override
  State<SbSearchBar> createState() => _SbSearchBarState();
}

class _SbSearchBarState extends State<SbSearchBar> {
  Timer? _debounce;
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        decoration: InputDecoration(
          labelText: SbLocalizations.of(context).text('search'),
          prefixIcon: const Icon(Icons.search_rounded),
        ),
        onChanged: (value) {
          _debounce?.cancel();
          _debounce = Timer(
            const Duration(milliseconds: 300),
            () => widget.onChanged(value),
          );
        },
      );
}
