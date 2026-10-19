import 'package:flutter/material.dart';

import 'tokens.dart';

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
DateTime boundedDate(
  int year,
  int month,
  int day,
  DateTime first,
  DateTime last,
) {
  final result = DateTime(
    year,
    month,
    day.clamp(1, DateTime(year, month + 1, 0).day),
  );
  return result.isBefore(dateOnly(first))
      ? dateOnly(first)
      : result.isAfter(dateOnly(last))
      ? dateOnly(last)
      : result;
}

/// A page for a deliberate choice; no platform calendar or date format entry.
class DsPickerPage extends StatelessWidget {
  final String title, description;
  final Widget child;
  final VoidCallback onConfirm;
  const DsPickerPage({
    super.key,
    required this.title,
    required this.description,
    required this.child,
    required this.onConfirm,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      leading: IconButton(
        tooltip: '취소',
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    body: SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(DsSpace.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      description,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: DsSpace.xxl),
                    child,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onConfirm,
                  child: const Text('선택'),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class DsWheel extends StatefulWidget {
  final String label;
  final int first, last, value;
  final ValueChanged<int> onChanged;
  const DsWheel({
    super.key,
    required this.label,
    required this.first,
    required this.last,
    required this.value,
    required this.onChanged,
  });
  @override
  State<DsWheel> createState() => _DsWheelState();
}

class _DsWheelState extends State<DsWheel> {
  late final FixedExtentScrollController controller;
  @override
  void initState() {
    super.initState();
    controller = FixedExtentScrollController(
      initialItem: widget.value - widget.first,
    );
  }

  @override
  void didUpdateWidget(DsWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        controller.hasClients &&
        controller.selectedItem != widget.value - widget.first) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && controller.hasClients) {
          controller.jumpToItem(widget.value - widget.first);
        }
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final extent = MediaQuery.textScalerOf(context).scale(20) + 28;
    return Expanded(
      child: Semantics(
        label: widget.label,
        value: '${widget.value}',
        child: SizedBox(
          height: extent * 5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: extent,
                decoration: BoxDecoration(
                  color: DsColors.selected,
                  borderRadius: BorderRadius.circular(DsRadius.control),
                ),
              ),
              ListWheelScrollView.useDelegate(
                controller: controller,
                itemExtent: extent,
                physics: const FixedExtentScrollPhysics(),
                diameterRatio: 1.8,
                onSelectedItemChanged: (index) {
                  final value = index + widget.first;
                  if (value == widget.value) return;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted &&
                        value >= widget.first &&
                        value <= widget.last &&
                        value != widget.value) {
                      widget.onChanged(value);
                    }
                  });
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: widget.last - widget.first + 1,
                  builder: (context, index) {
                    final value = index + widget.first;
                    return Center(
                      child: Text(
                        '$value${widget.label}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: value == widget.value
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: value == widget.value
                              ? DsColors.moss
                              : DsColors.muted,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DsDatePicker extends StatefulWidget {
  final String title;
  final DateTime initialDate, firstDate, lastDate;
  final bool birthday;
  const DsDatePicker({
    super.key,
    required this.title,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.birthday = false,
  });
  @override
  State<DsDatePicker> createState() => _DsDatePickerState();
}

class _DsDatePickerState extends State<DsDatePicker> {
  late DateTime selected, month;
  @override
  void initState() {
    super.initState();
    selected = boundedDate(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
      widget.firstDate,
      widget.lastDate,
    );
    month = DateTime(selected.year, selected.month);
  }

  void change(int y, int m, int d) => setState(
    () => selected = boundedDate(y, m, d, widget.firstDate, widget.lastDate),
  );
  @override
  Widget build(BuildContext context) => DsPickerPage(
    title: widget.title,
    description: widget.birthday ? '태어난 날을 알려주세요' : '언제 함께 걸을까요?',
    onConfirm: () => Navigator.pop(context, selected),
    child: widget.birthday
        ? Column(
            children: [
              Text(
                '${selected.year}년 ${selected.month}월 ${selected.day}일',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  DsWheel(
                    label: '년',
                    first: widget.firstDate.year,
                    last: widget.lastDate.year,
                    value: selected.year,
                    onChanged: (v) => change(v, selected.month, selected.day),
                  ),
                  const SizedBox(width: 8),
                  DsWheel(
                    label: '월',
                    first: selected.year == widget.firstDate.year
                        ? widget.firstDate.month
                        : 1,
                    last: selected.year == widget.lastDate.year
                        ? widget.lastDate.month
                        : 12,
                    value: selected.month,
                    onChanged: (v) => change(selected.year, v, selected.day),
                  ),
                  const SizedBox(width: 8),
                  DsWheel(
                    label: '일',
                    first:
                        selected.year == widget.firstDate.year &&
                            selected.month == widget.firstDate.month
                        ? widget.firstDate.day
                        : 1,
                    last:
                        selected.year == widget.lastDate.year &&
                            selected.month == widget.lastDate.month
                        ? widget.lastDate.day
                        : DateTime(selected.year, selected.month + 1, 0).day,
                    value: selected.day,
                    onChanged: (v) => change(selected.year, selected.month, v),
                  ),
                ],
              ),
            ],
          )
        : calendar(context),
  );
  Widget calendar(BuildContext context) {
    final offset = month.weekday % 7;
    final count = DateTime(month.year, month.month + 1, 0).day;
    final previous = DateTime(month.year, month.month - 1);
    final next = DateTime(month.year, month.month + 1);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${month.year}년 ${month.month}월',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: '이전 달',
              onPressed:
                  DateTime(
                    month.year,
                    month.month,
                    0,
                  ).isBefore(dateOnly(widget.firstDate))
                  ? null
                  : () => setState(() => month = previous),
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: '다음 달',
              onPressed: next.isAfter(dateOnly(widget.lastDate))
                  ? null
                  : () => setState(() => month = next),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (final day in ['일', '월', '화', '수', '목', '금', '토'])
              Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(color: DsColors.muted),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: MediaQuery.textScalerOf(context).scale(16) + 32,
          ),
          itemCount: ((offset + count) / 7).ceil() * 7,
          itemBuilder: (context, index) {
            final day = index - offset + 1;
            if (day < 1 || day > count) return const SizedBox.shrink();
            final date = DateTime(month.year, month.month, day);
            final enabled =
                !date.isBefore(dateOnly(widget.firstDate)) &&
                !date.isAfter(dateOnly(widget.lastDate));
            final active = date == selected;
            return Semantics(
              selected: active,
              label: '${month.month}월 $day일',
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: active ? DsColors.moss : null,
                  foregroundColor: active ? Colors.white : DsColors.ink,
                ),
                onPressed: enabled
                    ? () => setState(() => selected = date)
                    : null,
                child: Text('$day'),
              ),
            );
          },
        ),
      ],
    );
  }
}

class DsTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;
  const DsTimePicker({super.key, required this.initialTime});
  @override
  State<DsTimePicker> createState() => _DsTimePickerState();
}

class _DsTimePickerState extends State<DsTimePicker> {
  late TimeOfDay time = widget.initialTime;
  @override
  Widget build(BuildContext context) => DsPickerPage(
    title: '산책 시간',
    description: '몇 시에 만날까요?',
    onConfirm: () => Navigator.pop(context, time),
    child: Row(
      children: [
        DsWheel(
          label: '시',
          first: 0,
          last: 23,
          value: time.hour,
          onChanged: (v) =>
              setState(() => time = TimeOfDay(hour: v, minute: time.minute)),
        ),
        const SizedBox(width: 12),
        DsWheel(
          label: '분',
          first: 0,
          last: 59,
          value: time.minute,
          onChanged: (v) =>
              setState(() => time = TimeOfDay(hour: time.hour, minute: v)),
        ),
      ],
    ),
  );
}
