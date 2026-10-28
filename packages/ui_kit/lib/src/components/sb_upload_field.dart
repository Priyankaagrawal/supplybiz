import 'package:flutter/material.dart';
import '../sb_localizations.dart';
import 'sb_controls.dart';

/// File metadata supplied by a platform picker. No bytes or PII are logged.
@immutable
class SbUploadFile {
  const SbUploadFile({
    required this.name,
    required this.mimeType,
    required this.sizeBytes,
  });
  final String name, mimeType;
  final int sizeBytes;
}

/// Validates before handing a picked file to the feature's upload service.
class SbUploadField extends StatefulWidget {
  const SbUploadField({
    required this.label,
    required this.pickFile,
    required this.onSelected,
    required this.allowedTypes,
    required this.maxBytes,
    this.preview,
    this.progress,
    this.error,
    this.onRetry,
    super.key,
  })  : assert(maxBytes > 0),
        assert(progress == null || (progress >= 0 && progress <= 1));
  final String label;
  final Future<SbUploadFile?> Function() pickFile;
  final ValueChanged<SbUploadFile> onSelected;
  final Set<String> allowedTypes;
  final int maxBytes;
  final Widget? preview;
  final double? progress;
  final String? error;
  final VoidCallback? onRetry;
  @override
  State<SbUploadField> createState() => _SbUploadFieldState();
}

class _SbUploadFieldState extends State<SbUploadField> {
  bool _invalid = false, _picking = false, _pickerFailed = false;
  String? _name;
  Future<void> _pick() async {
    setState(() {
      _picking = true;
      _pickerFailed = false;
    });
    try {
      final file = await widget.pickFile();
      if (!mounted || file == null) return;
      final valid = file.sizeBytes > 0 &&
          file.sizeBytes <= widget.maxBytes &&
          widget.allowedTypes.contains(file.mimeType);
      setState(() {
        _invalid = !valid;
        if (valid) _name = file.name;
      });
      if (valid) widget.onSelected(file);
    } catch (_) {
      // A picker failure is recoverable without exposing platform error details.
      if (mounted) setState(() => _pickerFailed = true);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label),
          if (_name != null) Text(_name!),
          if (widget.preview != null) widget.preview!,
          if (widget.progress != null)
            LinearProgressIndicator(
              value: widget.progress,
              semanticsLabel: widget.label,
            ),
          SbButton(
            label: SbLocalizations.of(context).text('upload'),
            loading: _picking,
            onPressed:
                widget.progress != null && widget.progress! < 1 ? null : _pick,
          ),
          if (_invalid || _pickerFailed || widget.error != null)
            Semantics(
              liveRegion: true,
              child: Text(
                widget.error ??
                    SbLocalizations.of(context)
                        .text(_pickerFailed ? 'error' : 'invalidFile'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (widget.error != null && widget.onRetry != null)
            SbButton(
              label: SbLocalizations.of(context).text('retry'),
              onPressed: widget.onRetry,
            ),
        ],
      );
}
