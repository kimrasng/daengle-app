import 'package:flutter/material.dart';

import 'package:daengle_design/daengle_design.dart';

/// Development catalog; the same components are used by product screens.
class DesignSystemGallery extends StatefulWidget {
  const DesignSystemGallery({super.key});
  @override
  State<DesignSystemGallery> createState() => _DesignSystemGalleryState();
}

class _DesignSystemGalleryState extends State<DesignSystemGallery> {
  final name = TextEditingController();
  final disabled = TextEditingController(text: '선택한 동네');
  final form = GlobalKey<FormState>();
  String? size = '작은 친구';
  bool selected = true;
  @override
  void dispose() {
    name.dispose();
    disabled.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('댕글 디자인 시스템')),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.all(DsSpace.xl),
        children: [
          Text(
            '편안하게 만나고,\n가볍게 걸어요',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 12),
          const Text(
            'Moss · Pretendard · 여백 중심',
            style: TextStyle(color: DsColors.muted),
          ),
          const SizedBox(height: DsSpace.xxl),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final entry in {
                '모스': DsColors.moss,
                '세이지': DsColors.sage,
                '선택': DsColors.selected,
                '입력': DsColors.field,
                '본문': DsColors.ink,
              }.entries)
                SizedBox(
                  width: 80,
                  child: Column(
                    children: [
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: entry.value,
                          borderRadius: BorderRadius.circular(DsRadius.control),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(entry.key),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: DsSpace.xxl),
          Text('입력과 선택', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          Form(
            key: form,
            child: DsTextField(
              label: '강아지 이름',
              controller: name,
              decoration: const InputDecoration(hintText: '예: 두부'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? '강아지 이름을 입력해주세요.' : null,
            ),
          ),
          DsTextField(label: '비활성 상태', controller: disabled, enabled: false),
          DsSelectField<String>(
            label: '몸집',
            initialValue: size,
            items: [
              for (final s in ['작은 친구', '중간 친구', '큰 친구'])
                DropdownMenuItem(value: s, child: Text(s)),
            ],
            onChanged: (v) => setState(() => size = v),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: DsChip(
              label: '차분해요',
              selected: selected,
              onSelected: (v) => setState(() => selected = v),
            ),
          ),
          const SizedBox(height: 24),
          DsButton(
            label: '입력 확인하기',
            onPressed: () => form.currentState!.validate(),
          ),
          const SizedBox(height: 12),
          DsButton(
            label: '생일 선택해보기',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DsDatePicker(
                  title: '생일',
                  birthday: true,
                  initialDate: DateTime(2023, 4, 12),
                  firstDate: DateTime(1970),
                  lastDate: DateTime.now(),
                ),
              ),
            ),
            variant: DsButtonVariant.secondary,
          ),
          const SizedBox(height: 12),
          const DsButton(label: '비활성 버튼', onPressed: null),
        ],
      ),
    ),
  );
}
