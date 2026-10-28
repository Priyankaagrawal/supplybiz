import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../sb_localizations.dart';
import '../tokens/sb_tokens.dart';

enum SbButtonVariant { primary, secondary, tertiary, destructive }

enum SbButtonSize { large, medium, small }

/// Scalable button with a minimum 48dp hit area and a busy state.
class SbButton extends StatelessWidget {
  const SbButton({
    required this.label,
    required this.onPressed,
    this.variant = SbButtonVariant.primary,
    this.size = SbButtonSize.large,
    this.loading = false,
    super.key,
  }) : assert(size != SbButtonSize.small || variant != SbButtonVariant.primary);
  final String label;
  final VoidCallback? onPressed;
  final SbButtonVariant variant;
  final SbButtonSize size;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final minimum = switch (size) {
      SbButtonSize.large => 52.0,
      SbButtonSize.medium => 44.0,
      SbButtonSize.small => 36.0,
    };
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(48, minimum)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(
            horizontal: 16, vertical: size == SbButtonSize.small ? 8 : 12),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SbRadius.button),
        ),
      ),
    );
    final child = Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        if (loading)
          const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        Text(label, textAlign: TextAlign.center),
      ],
    );
    final action = loading ? null : onPressed;
    final button = switch (variant) {
      SbButtonVariant.primary => FilledButton(
          style: style.copyWith(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? null
                  : SbColors.accent,
            ),
          ),
          onPressed: action,
          child: child,
        ),
      SbButtonVariant.destructive => FilledButton(
          style: style.copyWith(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) =>
                  states.contains(WidgetState.disabled) ? null : SbColors.error,
            ),
          ),
          onPressed: action,
          child: child,
        ),
      SbButtonVariant.secondary => OutlinedButton(
          style: style,
          onPressed: action,
          child: child,
        ),
      SbButtonVariant.tertiary => TextButton(
          style: style,
          onPressed: action,
          child: child,
        ),
    };
    return Semantics(
      liveRegion: loading,
      value: loading ? SbLocalizations.of(context).text('loading') : null,
      child: SizedBox(
        width: size == SbButtonSize.large ? double.infinity : null,
        child: button,
      ),
    );
  }
}

/// Icon action with a required localized tooltip and 48dp target.
class SbIconButton extends StatelessWidget {
  const SbIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    super.key,
  });
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: semanticLabel,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        onPressed: onPressed,
        icon: Icon(icon),
      );
}

enum SbTextFieldKind { text, numeric, amount }

/// Form field retaining native focus, helper, counter and error semantics.
class SbTextField extends StatelessWidget {
  const SbTextField({
    required this.label,
    this.controller,
    this.helper,
    this.error,
    this.prefix,
    this.maxLength,
    this.onChanged,
    this.validator,
    this.kind = SbTextFieldKind.text,
    super.key,
  });
  final String label;
  final TextEditingController? controller;
  final String? helper, error, prefix;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final SbTextFieldKind kind;
  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        onChanged: onChanged,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        maxLength: maxLength,
        keyboardType: kind == SbTextFieldKind.text
            ? TextInputType.text
            : TextInputType.numberWithOptions(
                decimal: kind == SbTextFieldKind.amount,
              ),
        inputFormatters: kind == SbTextFieldKind.numeric
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          errorText: error,
          prefixText: prefix ?? (kind == SbTextFieldKind.amount ? '₹ ' : null),
        ),
      );
}

/// One accessible autofill input with a six-digit visual layout.
class SbOtpField extends StatefulWidget {
  const SbOtpField({required this.onChanged, this.error, super.key});
  final ValueChanged<String> onChanged;
  final String? error;
  @override
  State<SbOtpField> createState() => _SbOtpFieldState();
}

class _SbOtpFieldState extends State<SbOtpField> {
  final _controller = TextEditingController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(SbLocalizations.of(context).text('otp')),
          Stack(
            alignment: Alignment.center,
            children: [
              TextField(
                controller: _controller,
                onChanged: (value) {
                  setState(() {});
                  widget.onChanged(value);
                },
                autofillHints: const [AutofillHints.oneTimeCode],
                keyboardType: TextInputType.number,
                maxLength: 6,
                showCursor: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: Colors.transparent),
                decoration: InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  labelText: SbLocalizations.of(context).text('otp'),
                ),
              ),
              IgnorePointer(
                child: ExcludeSemantics(
                  child: Row(
                    children: [
                      for (var index = 0; index < 6; index++)
                        Expanded(
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 48),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: SbColors.onSurfaceVariant),
                              borderRadius:
                                  BorderRadius.circular(SbRadius.input),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              index < _controller.text.length
                                  ? _controller.text[index]
                                  : ' ',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (widget.error != null)
            Semantics(
              liveRegion: true,
              child: Text(
                widget.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      );
}

/// Controlled integer pack stepper; bounded long-press repeat and live value.
class SbQuantityStepper extends StatefulWidget {
  const SbQuantityStepper({
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 999,
    super.key,
  })  : assert(min <= max),
        assert(value >= min && value <= max);
  final int value, min, max;
  final ValueChanged<int>? onChanged;
  @override
  State<SbQuantityStepper> createState() => _SbQuantityStepperState();
}

class _SbQuantityStepperState extends State<SbQuantityStepper> {
  Timer? _repeat;
  int? _heldValue;
  void _change(int delta) {
    final value = ((_heldValue ?? widget.value) + delta).clamp(
      widget.min,
      widget.max,
    );
    if (value == (_heldValue ?? widget.value) || widget.onChanged == null)
      return;
    if (_repeat != null) _heldValue = value;
    widget.onChanged!(value);
  }

  void _stop() {
    _repeat?.cancel();
    _repeat = null;
    _heldValue = null;
  }

  Widget _action(BuildContext context, int delta) {
    final enabled = widget.onChanged != null &&
        (delta < 0 ? widget.value > widget.min : widget.value < widget.max);
    return GestureDetector(
      // The labelled native icon button owns accessibility actions.
      excludeFromSemantics: true,
      onLongPressStart: enabled
          ? (_) {
              _heldValue = widget.value;
              _repeat = Timer.periodic(
                const Duration(milliseconds: 150),
                (_) => _change(delta),
              );
            }
          : null,
      onLongPressEnd: (_) => _stop(),
      onLongPressCancel: _stop,
      child: SbIconButton(
        icon: delta < 0 ? Icons.remove_rounded : Icons.add_rounded,
        semanticLabel: SbLocalizations.of(
          context,
        ).text(delta < 0 ? 'decrease' : 'increase'),
        onPressed: enabled ? () => _change(delta) : null,
      ),
    );
  }

  @override
  void didUpdateWidget(SbQuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onChanged == null) _stop();
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _action(context, -1),
          Semantics(
            liveRegion: true,
            label: SbLocalizations.of(context).text('quantity'),
            value: '${widget.value}',
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text('${widget.value}'),
              ),
            ),
          ),
          _action(context, 1),
        ],
      );
}
