import 'package:flutter/material.dart';

import 'tokens.dart';

class DsChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  const DsChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });
  @override
  Widget build(BuildContext context) => FilterChip(
    label: Text(label),
    selected: selected,
    onSelected: onSelected,
    selectedColor: DsColors.selected,
    backgroundColor: DsColors.field,
    showCheckmark: false,
    side: BorderSide(color: selected ? DsColors.moss : Colors.transparent),
    labelPadding: const EdgeInsets.symmetric(horizontal: 10),
    labelStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: selected ? DsColors.moss : DsColors.ink,
    ),
  );
}

/// Controlled weekday selection. Values use Sunday 0 through Saturday 6.
/// Keeps seven equal cells when they fit; narrow views use balanced rows.
class DsWeekdayPicker extends StatelessWidget {
  final Set<int> value;
  final ValueChanged<Set<int>>? onChanged;
  const DsWeekdayPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final minCell = MediaQuery.textScalerOf(context).scale(16) + 28;
      final cell = minCell < 48 ? 48.0 : minCell;
      final columns = constraints.maxWidth >= cell * 7 + 12
          ? 7
          : (constraints.maxWidth >= cell * 4 + 12 ? 4 : 3);
      final gap = columns == 7 ? 2.0 : 4.0;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: 8,
        children: [
          for (var day = 0; day < 7; day++)
            SizedBox(
              width: width,
              child: Semantics(
                label: '${['일', '월', '화', '수', '목', '금', '토'][day]}요일',
                selected: value.contains(day),
                child: TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: value.contains(day)
                        ? DsColors.moss
                        : DsColors.ink,
                    backgroundColor: value.contains(day)
                        ? DsColors.selected
                        : DsColors.field,
                    side: BorderSide(
                      color: value.contains(day)
                          ? DsColors.moss
                          : Colors.transparent,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onChanged == null
                      ? null
                      : () {
                          final next = Set<int>.from(value);
                          next.contains(day) ? next.remove(day) : next.add(day);
                          onChanged!(next);
                        },
                  child: Text(['일', '월', '화', '수', '목', '금', '토'][day]),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class DsChoiceGroup<T> extends StatelessWidget {
  final Map<T, String> options;
  final T? value;
  final ValueChanged<T>? onChanged;
  const DsChoiceGroup({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final entry in options.entries)
        ChoiceChip(
          label: Text(entry.value),
          selected: value == entry.key,
          selectedColor: DsColors.selected,
          backgroundColor: DsColors.field,
          labelStyle: TextStyle(
            color: value == entry.key ? DsColors.moss : DsColors.ink,
          ),
          onSelected: onChanged == null ? null : (_) => onChanged!(entry.key),
        ),
    ],
  );
}

class DsSwitch extends StatelessWidget {
  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool>? onChanged;
  const DsSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
  });
  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: description == null ? null : Text(description!),
    value: value,
    onChanged: onChanged,
  );
}

class DsCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  const DsCheckbox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => CheckboxListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    value: value,
    onChanged: onChanged == null ? null : (v) => onChanged!(v ?? false),
    controlAffinity: ListTileControlAffinity.leading,
  );
}
