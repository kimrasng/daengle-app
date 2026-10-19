import 'package:flutter/material.dart';

import 'package:daengle_design/daengle_design.dart';
export 'package:daengle_design/daengle_design.dart'
    hide buildAppTheme, DaengleTheme;

import '../core/api.dart';

final routeObserver = RouteObserver<ModalRoute<dynamic>>();

const labelColor = DsColors.ink;
const secondaryLabel = DsColors.muted;
const brandColor = DsColors.sage;
const tint = DsColors.moss;
const groupedBackground = DsColors.canvas;
const fieldBackground = DsColors.field;
const tintBackground = DsColors.selected;
const separator = DsColors.line;

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  const AppTopBar({super.key, required this.title, this.actions});
  @override
  Size get preferredSize => const Size.fromHeight(60);
  @override
  Widget build(BuildContext context) => AppBar(
    title: title,
    actions: actions,
    centerTitle: false,
    toolbarHeight: 60,
  );
}

String statusText(dynamic value) =>
    const {
      'NOT_SUBMITTED': '서류 미제출',
      'UNDER_REVIEW': '심사 중',
      'APPROVED': '승인됨',
      'NEEDS_SUPPLEMENT': '보완 필요',
      'RESTRICTED': '이용 제한',
      'NONE': '미승인',
      'PENDING': '대기 중',
      'ACCEPTED': '수락됨',
      'DECLINED': '거절됨',
      'CANCELLED': '취소됨',
      'EXPIRED': '만료됨',
      'ACTIVE': '활성',
      'OPEN': '모집 중',
      'CLOSED': '모집 마감',
      'COMPLETED': '종료',
      'REJECTED': '거절됨',
      'SMALL': '소형견',
      'MEDIUM': '중형견',
      'LARGE': '대형견',
      'WALK': '산책',
      'CAFE': '애견카페',
      'FRIEND': '친구 만들기',
      'DAWN': '새벽',
      'MORNING': '아침',
      'AFTERNOON': '오후',
      'EVENING': '저녁',
      'NIGHT': '밤',
      'DM': '친구와 대화',
      'CHANNEL': '동네 채널',
      'MEETUP': '모임 대화',
    }[value] ??
    label(value);
String guardianNameText(dynamic value) => switch (label(value)) {
  '' || '새로운 견주' => '보호자',
  '탈퇴한 견주' => '탈퇴한 보호자',
  final name => name,
};

String dateText(dynamic value) {
  final date = DateTime.tryParse(label(value))?.toLocal();
  if (date == null) return '';
  return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

void toast(BuildContext context, Object message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text('$message')));
}

Future<void> action(BuildContext context, Future<void> Function() work) async {
  try {
    await work();
  } catch (e) {
    if (context.mounted) toast(context, e);
  }
}

void openScreen(BuildContext context, Widget child) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => child));

class PageBody extends StatelessWidget {
  final List<Widget> children;
  const PageBody({super.key, required this.children});
  @override
  Widget build(BuildContext context) =>
      SafeArea(top: false, child: DsPageBody(children: children));
}

class Section extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const Section(this.title, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) =>
      DsSection(title: title, trailing: trailing);
}

class PageIntro extends StatelessWidget {
  final String title, subtitle;
  const PageIntro(this.title, this.subtitle, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: secondaryLabel, height: 1.6),
          ),
        ],
      ],
    ),
  );
}

class FeatureIcon extends StatelessWidget {
  final IconData icon;
  final Color color, background;
  const FeatureIcon(
    this.icon, {
    super.key,
    this.color = tint,
    this.background = tintBackground,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Icon(icon, color: color, size: 23),
  );
}

class Panel extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  const Panel({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(20),
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: DsPanel(color: color, padding: padding, child: child),
  );
}

class GroupedRows extends StatelessWidget {
  final List<Widget> children;
  const GroupedRows({super.key, required this.children});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(height: 4),
        children[i],
      ],
    ],
  );
}

class Empty extends StatelessWidget {
  final String title, detail;
  final IconData icon;
  const Empty(
    this.title,
    this.detail, {
    super.key,
    this.icon = Icons.pets_rounded,
  });
  @override
  Widget build(BuildContext context) =>
      DsEmptyState(title: title, description: detail, icon: icon);
}

class AsyncView extends StatefulWidget {
  final Future<dynamic> Function() load;
  final Widget Function(dynamic data, VoidCallback reload) builder;
  const AsyncView({super.key, required this.load, required this.builder});
  @override
  State<AsyncView> createState() => _AsyncViewState();
}

class _AsyncViewState extends State<AsyncView> with RouteAware {
  ModalRoute<dynamic>? route;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = ModalRoute.of(context);
    if (route != next && next != null) {
      routeObserver.unsubscribe(this);
      route = next;
      routeObserver.subscribe(this, next);
    }
  }

  @override
  void didPopNext() => reload();
  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  late Future<dynamic> future;
  @override
  void initState() {
    super.initState();
    future = widget.load();
  }

  void reload() {
    if (mounted) {
      setState(() {
        future = widget.load();
      });
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<dynamic>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 42, color: tint),
                const SizedBox(height: 16),
                Text('${snapshot.error}', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                DsButton(label: '다시 시도', onPressed: reload),
              ],
            ),
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: () async {
          reload();
          try {
            await future;
          } catch (_) {
            /* FutureBuilder displays the failure. */
          }
        },
        child: widget.builder(snapshot.data, reload),
      );
    },
  );
}

// App adapter: the package owns button states; the app owns error presentation.
class SubmitButton extends StatelessWidget {
  final String text;
  final Future<void> Function() onPressed;
  final bool secondary;
  const SubmitButton(
    this.text, {
    super.key,
    required this.onPressed,
    this.secondary = false,
  });
  @override
  Widget build(BuildContext context) => DsAsyncButton(
    label: text,
    onPressed: onPressed,
    variant: secondary ? DsButtonVariant.secondary : DsButtonVariant.primary,
    onError: (error, _) => toast(context, error),
  );
}

int inputMaxLines(BuildContext context, int requested) =>
    dsInputMaxLines(context, requested);

class Input extends StatelessWidget {
  final TextEditingController controller;
  final String title;
  final String? hint, suffix;
  final int lines;
  final TextInputType? keyboard;
  const Input(
    this.controller,
    this.title, {
    super.key,
    this.lines = 1,
    this.keyboard,
    this.hint,
    this.suffix,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 0),
    child: DsTextField(
      label: title,
      controller: controller,
      minLines: lines > 1 ? 3.clamp(1, inputMaxLines(context, lines)) : 1,
      maxLines: inputMaxLines(context, lines),
      scrollPadding: const EdgeInsets.all(32),
      textInputAction: lines == 1
          ? TextInputAction.next
          : TextInputAction.newline,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      keyboardType:
          keyboard ??
          (lines > 1 ? TextInputType.multiline : TextInputType.text),
      decoration: InputDecoration(hintText: hint, suffixText: suffix),
      validator: (value) =>
          value == null || value.trim().isEmpty ? '$title 입력해주세요.' : null,
    ),
  );
}

Future<bool> confirm(BuildContext context, String title, String message) =>
    showDsConfirm(context, title: title, description: message);
Future<String?> askText(
  BuildContext context,
  String title, {
  String initial = '',
}) async {
  final controller = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      title: Text(title),
      content: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.multiline,
          minLines: 1,
          maxLines: inputMaxLines(context, 3),
          scrollPadding: const EdgeInsets.all(32),
        ),
      ),
      actions: [
        DsButton(
          label: '취소',
          onPressed: () => Navigator.pop(context),
          variant: DsButtonVariant.ghost,
          size: DsButtonSize.compact,
        ),
        DsButton(
          label: '확인',
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              Navigator.pop(context, controller.text.trim());
            }
          },
          variant: DsButtonVariant.ghost,
          size: DsButtonSize.compact,
        ),
      ],
    ),
  );
  // The dialog route may still animate while disposing its TextField.
  Future<void>.delayed(const Duration(seconds: 1), controller.dispose);
  return result;
}

/// Stores the API date internally; people choose and read a localized birthday.
class BirthdayField extends StatelessWidget {
  final TextEditingController controller;
  final String title;
  final bool optional;
  const BirthdayField(
    this.controller, {
    super.key,
    this.title = '생일',
    this.optional = false,
  });

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<TextEditingValue>(
    valueListenable: controller,
    builder: (context, value, _) {
      final now = DateTime.now();
      return DsDateField(
        label: title,
        value: DateTime.tryParse(value.text),
        birthday: true,
        optional: optional,
        firstDate: DateTime(optional ? 1970 : 1900),
        lastDate: now,
        initialDate: DateTime(
          now.year - (optional ? 3 : 26),
          now.month,
          now.day,
        ),
        validator: (date) => !optional && date == null ? '생일을 선택해주세요' : null,
        onChanged: (date) {
          controller.text = date == null
              ? ''
              : '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        },
      );
    },
  );
}

class TraitPicker extends StatelessWidget {
  final TextEditingController controller;
  final List<String> choices;
  const TraitPicker(this.controller, {super.key, required this.choices});
  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final selected = value.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toSet();
          return DsField(
            label: '성격',
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final choice in {...choices, ...selected})
                  DsChip(
                    label: choice,
                    selected: selected.contains(choice),
                    onSelected: (v) {
                      if (v && selected.length >= 10) return;
                      v ? selected.add(choice) : selected.remove(choice);
                      controller.text = selected.join(', ');
                    },
                  ),
              ],
            ),
          );
        },
      );
}
