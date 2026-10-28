import 'package:flutter/material.dart';
import '../sb_localizations.dart';
import '../tokens/sb_tokens.dart';
import 'sb_controls.dart';

/// Empty state with an optional localized recovery action.
class SbEmpty extends StatelessWidget {
  const SbEmpty({this.message, this.actionLabel, this.onAction, super.key});
  final String? message, actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 32),
            Text(
              message ?? SbLocalizations.of(context).text('empty'),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionLabel != null)
              SbButton(label: actionLabel!, onPressed: onAction),
          ],
        ),
      );
}

/// Recoverable inline error announced without moving focus.
class SbError extends StatelessWidget {
  const SbError({required this.onRetry, this.message, super.key});
  final String? message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message ?? SbLocalizations.of(context).text('error')),
            SbButton(
              label: SbLocalizations.of(context).text('retry'),
              onPressed: onRetry,
            ),
          ],
        ),
      );
}

/// Static layout placeholder: no decorative motion, including reduced-motion mode.
class SbSkeleton extends StatelessWidget {
  const SbSkeleton({this.lines = 3, super.key}) : assert(lines > 0);
  final int lines;
  @override
  Widget build(BuildContext context) => Semantics(
        label: SbLocalizations.of(context).text('loading'),
        child: ExcludeSemantics(
          child: Column(
            children: [
              for (var i = 0; i < lines; i++)
                Container(
                  height: 20,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: SbColors.outline,
                    borderRadius: BorderRadius.circular(SbRadius.input),
                  ),
                ),
            ],
          ),
        ),
      );
}

/// Cached-data banner; caller may supply localized last-update information.
class SbOfflineBanner extends StatelessWidget {
  const SbOfflineBanner({this.message, super.key});
  final String? message;
  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Container(
          width: double.infinity,
          color: SbColors.warningContainer,
          padding: const EdgeInsets.all(12),
          child: Text(
            message ?? SbLocalizations.of(context).text('offline'),
            style: const TextStyle(color: SbColors.onSurface),
          ),
        ),
      );
}

/// Plan-gated preview disables input and hides inaccessible content semantics.
class SbLockedFeature extends StatelessWidget {
  const SbLockedFeature({
    required this.child,
    required this.onUpgrade,
    this.message,
    super.key,
  });
  final Widget child;
  final String? message;
  final VoidCallback onUpgrade;
  @override
  Widget build(BuildContext context) => Column(
        children: [
          ExcludeSemantics(
            child: IgnorePointer(child: Opacity(opacity: 0.3, child: child)),
          ),
          const Icon(Icons.lock_outline_rounded),
          Text(message ?? SbLocalizations.of(context).text('locked')),
          SbButton(
            label: SbLocalizations.of(context).text('upgrade'),
            onPressed: onUpgrade,
          ),
        ],
      );
}

/// Offline mutation queue state, expressed with icon and text.
class SbSyncChip extends StatelessWidget {
  const SbSyncChip({required this.pendingCount, super.key})
      : assert(pendingCount >= 0);
  final int pendingCount;
  @override
  Widget build(BuildContext context) => Chip(
        avatar: Icon(
          pendingCount == 0
              ? Icons.cloud_done_outlined
              : Icons.cloud_upload_outlined,
        ),
        label: Text(
          pendingCount == 0
              ? SbLocalizations.of(context).text('synced')
              : '${SbLocalizations.of(context).text('sync')} ($pendingCount)',
        ),
      );
}
