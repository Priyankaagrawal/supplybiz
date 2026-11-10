import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/l10n/l10n.dart';

/// Manual masking fallback; no unmasked bytes leave memory or enter local drafts.
class MaskDocument extends StatefulWidget {
  const MaskDocument(
      {required this.bytes, required this.pdf, required this.label, super.key});
  final Uint8List bytes;
  final bool pdf;
  final String label;
  @override
  State<MaskDocument> createState() => _MaskDocumentState();
}

class _MaskDocumentState extends State<MaskDocument> {
  bool masking = false, confirmed = false;
  double x = .1, y = .7, width = .6, height = .1;
  bool busy = false, failed = false;
  Future<void> finish() async {
    if (!confirmed) return;
    setState(() {
      busy = true;
      failed = false;
    });
    var bytes = widget.bytes;
    try {
      if (masking && !widget.pdf) {
        bytes = await maskImage(bytes, Rect.fromLTWH(x, y, width, height));
      }
      if (mounted) Navigator.pop(context, bytes);
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
        title: Text(widget.label),
        content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(l.onboardingMaskGuide),
              if (failed) Text(l.onboardingFileError),
              if (!widget.pdf) ...[
                Stack(children: [
                  Image.memory(widget.bytes, semanticLabel: widget.label),
                  if (masking)
                    Positioned.fill(
                        child: LayoutBuilder(
                            builder: (_, c) => Stack(children: [
                                  Positioned(
                                      left: x * c.maxWidth,
                                      top: y * c.maxHeight,
                                      width: width * c.maxWidth,
                                      height: height * c.maxHeight,
                                      child:
                                          const ColoredBox(color: Colors.black))
                                ])))
                ]),
                SwitchListTile(
                    title: Text(l.onboardingMaskTool),
                    value: masking,
                    onChanged: busy
                        ? null
                        : (value) => setState(() {
                              masking = value;
                              confirmed = false;
                            })),
                if (masking) ...[
                  Text(l.onboardingMaskX),
                  Slider(
                      value: x,
                      max: 1 - width,
                      divisions: 100,
                      semanticFormatterCallback: (v) =>
                          '${l.onboardingMaskX}: ${(v * 100).round()}%',
                      onChanged: busy
                          ? null
                          : (v) => setState(() {
                                x = v;
                                confirmed = false;
                              })),
                  Text(l.onboardingMaskY),
                  Slider(
                      value: y,
                      max: 1 - height,
                      divisions: 100,
                      semanticFormatterCallback: (v) =>
                          '${l.onboardingMaskY}: ${(v * 100).round()}%',
                      onChanged: busy
                          ? null
                          : (v) => setState(() {
                                y = v;
                                confirmed = false;
                              })),
                  Text(l.onboardingMaskWidth),
                  Slider(
                      value: width,
                      min: .01,
                      max: 1 - x,
                      divisions: 100,
                      semanticFormatterCallback: (v) =>
                          '${l.onboardingMaskWidth}: ${(v * 100).round()}%',
                      onChanged: busy
                          ? null
                          : (v) => setState(() {
                                width = v;
                                confirmed = false;
                              })),
                  Text(l.onboardingMaskHeight),
                  Slider(
                      value: height,
                      min: .01,
                      max: 1 - y,
                      divisions: 100,
                      semanticFormatterCallback: (v) =>
                          '${l.onboardingMaskHeight}: ${(v * 100).round()}%',
                      onChanged: busy
                          ? null
                          : (v) => setState(() {
                                height = v;
                                confirmed = false;
                              })),
                ],
              ] else
                Text(l.onboardingMaskedPdf),
              CheckboxListTile(
                  title: Text(l.onboardingMaskConfirm),
                  value: confirmed,
                  onChanged: busy
                      ? null
                      : (value) => setState(() => confirmed = value!)),
            ]))),
        actions: [
          TextButton(
              onPressed: busy ? null : () => Navigator.pop(context),
              child: Text(l.onboardingClose)),
          FilledButton(
              onPressed: busy || !confirmed ? null : finish,
              child: Text(l.onboardingUseDocument))
        ]);
  }
}

/// Flatten masking into encoded pixels; hidden text cannot be recovered as a layer.
Future<Uint8List> maskImage(Uint8List bytes, Rect region) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final image = (await codec.getNextFrame()).image;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..drawImage(image, Offset.zero, Paint());
  canvas.drawRect(
      Rect.fromLTWH(region.left * image.width, region.top * image.height,
          region.width * image.width, region.height * image.height),
      Paint()..color = Colors.black);
  final picture = recorder.endRecording();
  final masked = await picture.toImage(image.width, image.height);
  final encoded = (await masked.toByteData(format: ui.ImageByteFormat.png))!
      .buffer
      .asUint8List();
  masked.dispose();
  picture.dispose();
  image.dispose();
  codec.dispose();
  return encoded;
}
