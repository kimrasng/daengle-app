import 'package:flutter/material.dart';

import 'tokens.dart';

/// Screen body is scrollable and provides its post-keyboard height to fields.
class DsPage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final List<Widget>? actions;
  final Widget? footer;
  final double maxWidth;
  const DsPage({
    super.key,
    required this.title,
    required this.children,
    this.actions,
    this.footer,
    this.maxWidth = 560,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), actions: actions),
    body: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: LayoutBuilder(
            builder: (context, constraints) => DsViewport(
              height: constraints.maxHeight,
              child: Column(
                children: [
                  Expanded(child: DsPageBody(children: children)),
                  if (footer != null)
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: constraints.maxHeight * .5,
                      ),
                      child: SingleChildScrollView(
                        child: DsFooter(child: footer!),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class DsViewport extends InheritedWidget {
  final double height;
  const DsViewport({super.key, required this.height, required super.child});
  @override
  bool updateShouldNotify(DsViewport oldWidget) => height != oldWidget.height;
}

int dsInputMaxLines(BuildContext context, int requested) {
  assert(requested > 0);
  final media = MediaQuery.of(context);
  final height =
      context.dependOnInheritedWidgetOfExactType<DsViewport>()?.height ??
      media.size.height -
          View.of(context).viewInsets.bottom / media.devicePixelRatio -
          media.padding.vertical -
          kToolbarHeight;
  return ((height - 120) / media.textScaler.scale(24)).floor().clamp(
    1,
    requested,
  );
}

class DsPageBody extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  const DsPageBody({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(24, 20, 24, 32),
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => DsViewport(
      height: constraints.maxHeight,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: children,
      ),
    ),
  );
}

class DsFooter extends StatelessWidget {
  final Widget child;
  final String? notice;
  const DsFooter({super.key, required this.child, this.notice});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        child,
        if (notice != null) ...[
          const SizedBox(height: 12),
          Text(
            notice!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: DsColors.muted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ],
    ),
  );
}

class DsSection extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const DsSection({super.key, required this.title, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 16),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?trailing,
      ],
    ),
  );
}

class DsPanel extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  const DsPanel({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(20),
  });
  @override
  Widget build(BuildContext context) => Material(
    color: color ?? DsColors.field,
    borderRadius: BorderRadius.circular(DsRadius.panel),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding, child: child),
  );
}

class DsListTile extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? leading, trailing;
  final VoidCallback? onTap;
  const DsListTile({
    super.key,
    required this.title,
    this.description,
    this.leading,
    this.trailing,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 8),
    leading: leading,
    title: Text(title),
    subtitle: description == null ? null : Text(description!),
    trailing:
        trailing ??
        (onTap == null ? null : const Icon(Icons.chevron_right_rounded)),
    onTap: onTap,
  );
}
