import 'package:flutter/material.dart';
import '../sb_localizations.dart';
import '../tokens/sb_tokens.dart';
import 'sb_controls.dart';

/// RULE-01 integer-only Indian grouping; paise appear only when nonzero.
String formatInr(int paise) {
  final absolute = paise.abs();
  final digits = (absolute ~/ 100).toString();
  final groups = <String>[];
  var end = digits.length;
  if (end > 3) {
    groups.insert(0, digits.substring(end - 3));
    end -= 3;
    while (end > 2) {
      groups.insert(0, digits.substring(end - 2, end));
      end -= 2;
    }
  }
  groups.insert(0, digits.substring(0, end));
  final fraction = absolute % 100;
  return '${paise < 0 ? '-' : ''}₹${groups.join(',')}'
      '${fraction == 0 ? '' : '.${fraction.toString().padLeft(2, '0')}'}';
}

/// Tabular amount display with localized currency semantics.
class SbAmountText extends StatelessWidget {
  const SbAmountText(this.paise, {this.style, this.semanticLabel, super.key});
  final int paise;
  final TextStyle? style;
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) {
    final strings = SbLocalizations.of(context);
    final absolute = paise.abs();
    final spoken =
        '${paise < 0 ? '-' : ''}${absolute ~/ 100} ${strings.text('rupees')}'
        '${absolute % 100 == 0 ? '' : ' ${absolute % 100} ${strings.text('paise')}'}';
    return Semantics(
      label: semanticLabel ?? spoken,
      excludeSemantics: true,
      child: Text(
        formatInr(paise),
        softWrap: true,
        style:
            (style ?? SbTypography.amountLarge(Localizations.localeOf(context)))
                .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
  }
}

enum SbStatus {
  NEW,
  PENDING,
  PENDING_APPROVAL,
  LOW_STOCK,
  ACCEPTED,
  PREPARING,
  OUT_FOR_DELIVERY,
  SCHEDULED,
  DELIVERED,
  ACTIVE,
  VERIFIED,
  PAID,
  SETTLED,
  CANCELLED,
  REJECTED,
  FAILED,
  INACTIVE,
  PAYABLE,
  PAUSED,
}

/// Centralized status-to-colour, icon and localized-label mapping (§3.2).
class SbStatusBadge extends StatelessWidget {
  const SbStatusBadge(this.status, {super.key});
  final SbStatus status;
  @override
  Widget build(BuildContext context) {
    final (foreground, background, icon) = switch (status) {
      SbStatus.NEW ||
      SbStatus.PENDING ||
      SbStatus.PENDING_APPROVAL ||
      SbStatus.LOW_STOCK =>
        (
          SbColors.warning,
          SbColors.warningContainer,
          Icons.schedule_rounded,
        ),
      SbStatus.ACCEPTED => (
          SbColors.info,
          SbColors.infoContainer,
          Icons.check_circle_outline_rounded,
        ),
      SbStatus.PREPARING => (
          SbColors.info,
          SbColors.infoContainer,
          Icons.inventory_2_outlined,
        ),
      SbStatus.OUT_FOR_DELIVERY || SbStatus.SCHEDULED => (
          SbColors.info,
          SbColors.infoContainer,
          Icons.local_shipping_outlined,
        ),
      SbStatus.DELIVERED ||
      SbStatus.ACTIVE ||
      SbStatus.VERIFIED ||
      SbStatus.PAID ||
      SbStatus.SETTLED =>
        (
          SbColors.success,
          SbColors.successContainer,
          Icons.check_rounded,
        ),
      SbStatus.PAUSED => (
          SbColors.onSurfaceVariant,
          SbColors.neutralContainer,
          Icons.pause_rounded,
        ),
      _ => (SbColors.error, SbColors.errorContainer, Icons.cancel_outlined),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(SbRadius.chip),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ExcludeSemantics(child: Icon(icon, color: foreground, size: 18)),
            Text(
              SbLocalizations.of(context).text(status.name),
              style: Theme.of(
                context,
              )
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Flat reusable outlined surface for products, orders and ledger cards.
class SbCard extends StatelessWidget {
  const SbCard({required this.child, this.onTap, this.semanticLabel, super.key})
      : assert(onTap == null || semanticLabel != null);
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) => Material(
        color: SbColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SbRadius.card),
          side: const BorderSide(color: SbColors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          label: semanticLabel,
          button: onTap == null ? null : true,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.all(SbSpacing.card),
                child: child,
              ),
            ),
          ),
        ),
      );
}

/// A wrapping row whose trailing content moves below text on narrow screens.
class SbListTile extends StatelessWidget {
  const SbListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    super.key,
  });
  final String title;
  final String? subtitle;
  final Widget? leading, trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SbCard(
        onTap: onTap,
        semanticLabel: title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leading != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: leading,
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleMedium),
                      if (subtitle != null) Text(subtitle!),
                    ],
                  ),
                ),
              ],
            ),
            if (trailing != null)
              Padding(padding: const EdgeInsets.only(top: 8), child: trailing),
          ],
        ),
      );
}

/// Metric value and optional textual delta on a semantic tint.
class SbMetricTile extends StatelessWidget {
  const SbMetricTile({
    required this.label,
    required this.value,
    this.delta,
    this.tint = SbColors.primaryContainer,
    super.key,
  });
  final String label, value;
  final String? delta;
  final Color tint;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(SbRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            Text(
              value,
              style: SbTypography.amountLarge(Localizations.localeOf(context)),
            ),
            if (delta != null) Text(delta!),
          ],
        ),
      );
}

/// Product summary with optional decorative image and integer pack control.
class SbProductRow extends StatelessWidget {
  const SbProductRow({
    required this.name,
    required this.unit,
    required this.pricePaise,
    required this.quantity,
    required this.onChanged,
    this.image,
    this.max = 999,
    super.key,
  });
  final String name, unit;
  final int pricePaise, quantity, max;
  final ValueChanged<int>? onChanged;
  final Widget? image;
  @override
  Widget build(BuildContext context) => SbListTile(
        title: name,
        subtitle: unit,
        leading: image == null
            ? null
            : ExcludeSemantics(
                child: SizedBox.square(dimension: 48, child: image)),
        trailing: Wrap(
          spacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SbAmountText(pricePaise),
            if (quantity == 0)
              SbButton(
                label: SbLocalizations.of(context).text('add'),
                size: SbButtonSize.small,
                variant: SbButtonVariant.secondary,
                onPressed:
                    onChanged == null || max < 1 ? null : () => onChanged!(1),
              )
            else
              SbQuantityStepper(
                  value: quantity, max: max, onChanged: onChanged),
          ],
        ),
      );
}
