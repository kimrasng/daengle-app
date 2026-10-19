import 'package:flutter/material.dart';

import 'layout.dart';
import 'tokens.dart';

class DsField extends StatelessWidget {
  final String label;
  final Widget child;
  final bool optional;
  final String? helper, error;
  const DsField({
    super.key,
    required this.label,
    required this.child,
    this.optional = false,
    this.helper,
    this.error,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: ExcludeSemantics(
            child: Text.rich(
              TextSpan(
                text: label,
                children: [
                  if (optional)
                    const TextSpan(
                      text: '  선택',
                      style: TextStyle(
                        color: DsColors.muted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: DsColors.ink,
              ),
            ),
          ),
        ),
        child,
        if (error != null || helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              liveRegion: error != null,
              child: Text(
                error ?? helper!,
                style: TextStyle(
                  color: error != null ? DsColors.critical : DsColors.muted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class DsTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? initialValue, hint, helper, error;
  final bool optional, enabled, readOnly, obscureText;
  final int minLines, maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged, onSubmitted;
  final TapRegionCallback? onTapOutside;
  final EdgeInsets scrollPadding;
  final InputDecoration decoration;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode autovalidateMode;
  const DsTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.hint,
    this.helper,
    this.error,
    this.optional = false,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.minLines = 1,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onTapOutside,
    this.scrollPadding = const EdgeInsets.all(32),
    this.decoration = const InputDecoration(),
    this.validator,
    this.autovalidateMode = AutovalidateMode.disabled,
  }) : assert(controller == null || initialValue == null),
       assert(minLines > 0 && maxLines >= minLines),
       assert(!obscureText || maxLines == 1);
  @override
  Widget build(BuildContext context) {
    assert(
      decoration.labelText == null && decoration.label == null,
      'Use the fixed label property.',
    );
    final lines = dsInputMaxLines(context, maxLines);
    return DsField(
      label: label,
      optional: optional,
      child: Semantics(
        label: label,
        child: TextFormField(
          key: ValueKey('input:$label'),
          controller: controller,
          initialValue: initialValue,
          minLines: minLines.clamp(1, lines),
          maxLines: lines,
          keyboardType:
              keyboardType ??
              (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
          textInputAction:
              textInputAction ??
              (maxLines > 1 ? TextInputAction.newline : TextInputAction.next),
          focusNode: focusNode,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          onTapOutside:
              onTapOutside ??
              (_) => FocusManager.instance.primaryFocus?.unfocus(),
          scrollPadding: scrollPadding,
          enabled: enabled,
          readOnly: readOnly,
          obscureText: obscureText,
          autovalidateMode: autovalidateMode,
          decoration: decoration.copyWith(
            hintText: hint ?? decoration.hintText,
            helperText: helper ?? decoration.helperText,
            errorText: error ?? decoration.errorText,
          ),
          validator: validator,
        ),
      ),
    );
  }
}

class DsTextArea extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? hint, helper;
  final bool optional;
  final int maxLines;
  final FormFieldValidator<String>? validator;
  const DsTextArea({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.optional = false,
    this.maxLines = 5,
    this.validator,
  });
  @override
  Widget build(BuildContext context) => DsTextField(
    label: label,
    controller: controller,
    hint: hint,
    helper: helper,
    optional: optional,
    maxLines: maxLines,
    minLines: 2,
    keyboardType: TextInputType.multiline,
    validator: validator,
  );
}

class DsSelectField<T> extends StatelessWidget {
  final String label;
  final T? initialValue;
  final List<DropdownMenuItem<T>>? items;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final bool isExpanded, optional;
  final String? hint, helper;
  const DsSelectField({
    super.key,
    required this.label,
    this.initialValue,
    required this.items,
    required this.onChanged,
    this.validator,
    this.isExpanded = true,
    this.optional = false,
    this.hint,
    this.helper,
  });
  @override
  Widget build(BuildContext context) => DsField(
    label: label,
    optional: optional,
    child: Semantics(
      label: label,
      child: DropdownButtonFormField<T>(
        initialValue: initialValue,
        items: items,
        isExpanded: isExpanded,
        style: Theme.of(context).textTheme.bodyLarge,
        onChanged: onChanged,
        validator: validator,
        hint: hint == null ? null : Text(hint!),
        decoration: InputDecoration(helperText: helper),
        icon: const Icon(Icons.expand_more_rounded, size: 20),
      ),
    ),
  );
}
