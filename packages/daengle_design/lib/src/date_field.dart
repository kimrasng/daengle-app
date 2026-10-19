import 'package:flutter/material.dart';

import 'fields.dart';
import 'pickers.dart';
import 'tokens.dart';

String dsKoreanDate(DateTime value) =>
    '${value.year}년 ${value.month}월 ${value.day}일';
Future<DateTime?> showDsDatePicker(
  BuildContext context, {
  required String title,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  bool birthday = false,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return Navigator.of(context).push<DateTime>(
    MaterialPageRoute(
      builder: (_) => DsDatePicker(
        title: title,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        birthday: birthday,
      ),
    ),
  );
}

Future<TimeOfDay?> showDsTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return Navigator.of(context).push<TimeOfDay>(
    MaterialPageRoute(builder: (_) => DsTimePicker(initialTime: initialTime)),
  );
}

/// Controlled date value. Cancellation does not call [onChanged].
class DsDateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?>? onChanged;
  final DateTime firstDate, lastDate;
  final DateTime? initialDate;
  final bool birthday, optional;
  final String? helper;
  final FormFieldValidator<DateTime>? validator;
  const DsDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.initialDate,
    this.birthday = false,
    this.optional = false,
    this.helper,
    this.validator,
  });
  @override
  Widget build(BuildContext context) => FormField<DateTime>(
    initialValue: value,
    validator: (_) => validator?.call(value),
    builder: (state) => DsField(
      label: label,
      optional: optional,
      helper: helper,
      error: state.errorText,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: label,
              child: OutlinedButton(
                key: ValueKey('date:$label'),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  minimumSize: const Size(0, 56),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                  foregroundColor: value == null
                      ? DsColors.muted
                      : DsColors.ink,
                  backgroundColor: DsColors.field,
                  side: BorderSide(
                    color: state.hasError
                        ? DsColors.critical
                        : Colors.transparent,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DsRadius.control),
                  ),
                ),
                onPressed: onChanged == null
                    ? null
                    : () async {
                        final picked = await showDsDatePicker(
                          context,
                          title: label,
                          initialDate: value ?? initialDate ?? lastDate,
                          firstDate: firstDate,
                          lastDate: lastDate,
                          birthday: birthday,
                        );
                        if (picked != null && context.mounted) {
                          state.didChange(picked);
                          onChanged!(picked);
                        }
                      },
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value == null
                            ? (birthday ? '생년월일을 선택해주세요' : '날짜를 선택해주세요')
                            : dsKoreanDate(value!),
                      ),
                    ),
                    const Icon(Icons.expand_more_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ),
          if (optional && value != null)
            IconButton(
              tooltip: '$label 지우기',
              onPressed: onChanged == null
                  ? null
                  : () {
                      state.didChange(null);
                      onChanged!(null);
                    },
              icon: const Icon(Icons.close_rounded, size: 20),
            ),
        ],
      ),
    ),
  );
}
