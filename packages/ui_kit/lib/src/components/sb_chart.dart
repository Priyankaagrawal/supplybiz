import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../sb_localizations.dart';
import '../tokens/sb_tokens.dart';
import 'sb_controls.dart';

enum SbChartKind { bar, pie }

/// Display data only; callers format monetary values from integer paise.
@immutable
class SbChartDatum {
  const SbChartDatum({
    required this.label,
    required this.value,
    required this.formattedValue,
  }) : assert(value >= 0);
  final String label, formattedValue;
  final int value;
}

/// Bar/pie chart with an equivalent accessible table and no decorative animation.
class SbChart extends StatefulWidget {
  const SbChart({required this.data, this.kind = SbChartKind.bar, super.key});
  final List<SbChartDatum> data;
  final SbChartKind kind;
  @override
  State<SbChart> createState() => _SbChartState();
}

class _SbChartState extends State<SbChart> {
  bool _table = false;
  @override
  Widget build(BuildContext context) {
    final strings = SbLocalizations.of(context);
    return Column(
      children: [
        SbButton(
          label: strings.text(_table ? 'chart' : 'table'),
          variant: SbButtonVariant.tertiary,
          onPressed: () => setState(() => _table = !_table),
        ),
        if (_table)
          Table(
            columnWidths: const {0: FlexColumnWidth(), 1: FlexColumnWidth()},
            children: [
              TableRow(
                children: [
                  Text(strings.text('category')),
                  Text(strings.text('value')),
                ],
              ),
              for (final item in widget.data)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(item.label),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(item.formattedValue),
                    ),
                  ],
                ),
            ],
          )
        else
          Semantics(
            label: widget.data
                .map((d) => '${d.label}: ${d.formattedValue}')
                .join('; '),
            excludeSemantics: true,
            child: SizedBox(
              height: 200,
              child: widget.kind == SbChartKind.bar
                  ? BarChart(
                      BarChartData(
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: const FlTitlesData(show: false),
                        barGroups: [
                          for (var i = 0; i < widget.data.length; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: widget.data[i].value.toDouble(),
                                  color: SbColors.primaryStrong,
                                ),
                              ],
                            ),
                        ],
                      ),
                      duration: Duration.zero,
                    )
                  : PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(enabled: false),
                        sections: [
                          for (var i = 0; i < widget.data.length; i++)
                            PieChartSectionData(
                              value: widget.data[i].value.toDouble(),
                              showTitle: false,
                              color: [
                                SbColors.primaryStrong,
                                SbColors.accent,
                                SbColors.warning,
                                SbColors.error,
                              ][i % 4],
                            ),
                        ],
                      ),
                      duration: Duration.zero,
                    ),
            ),
          ),
      ],
    );
  }
}
