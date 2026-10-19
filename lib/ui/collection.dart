import 'package:flutter/material.dart';

import '../core/api.dart';
import 'shared.dart';

class CollectionScreen extends StatefulWidget {
  final Api api;
  final String title, path, empty;
  final Json? query;
  final Widget Function(Json row, VoidCallback reload) row;
  final Widget? floatingActionButton;
  final bool embedded;
  final Widget? header;
  final String emptyDetail;
  final IconData emptyIcon;
  final Widget? emptyAction;
  final Widget? Function(Object error, VoidCallback retry)? errorBuilder;
  final List<Widget>? actions;
  final Future<void> Function()? onRefresh;
  const CollectionScreen({
    super.key,
    required this.api,
    required this.title,
    required this.path,
    required this.row,
    this.query,
    this.empty = '아직 등록된 내용이 없어요.',
    this.floatingActionButton,
    this.embedded = false,
    this.header,
    this.emptyDetail = '새 소식이 생기면 여기에 보여드릴게요.',
    this.emptyIcon = Icons.inbox_rounded,
    this.emptyAction,
    this.errorBuilder,
    this.actions,
    this.onRefresh,
  });
  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> with RouteAware {
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
  void didPopNext() {
    load(reset: true);
  }

  @override
  void dispose() {
    generation++;
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  List<Json> rows = [];
  String? cursor;
  Object? error;
  bool loading = false;
  int generation = 0;
  @override
  void initState() {
    super.initState();
    load(reset: true);
  }

  Future<void> load({bool reset = false}) async {
    if (!mounted || (loading && !reset)) return;
    final request = reset ? ++generation : generation;
    setState(() {
      loading = true;
      error = null;
      if (reset) {
        rows = [];
        cursor = null;
      }
    });
    try {
      final data = object(
        await widget.api.call(
          widget.path,
          query: {...?widget.query, if (cursor != null) 'cursor': cursor},
        ),
      );
      if (!mounted || request != generation) return;
      setState(() {
        rows.addAll(items(data));
        cursor = data['nextCursor'] as String?;
      });
    } catch (e) {
      if (mounted && request == generation) setState(() => error = e);
    } finally {
      if (mounted && request == generation) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: widget.embedded
        ? null
        : AppTopBar(title: Text(widget.title), actions: widget.actions),
    floatingActionButton: widget.floatingActionButton,
    body: RefreshIndicator(
      onRefresh: () async {
        await load(reset: true);
        await widget.onRefresh?.call();
      },
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
        children: [
          ?widget.header,
          if (!loading && error == null && rows.isEmpty)
            Column(
              children: [
                Empty(widget.empty, widget.emptyDetail, icon: widget.emptyIcon),
                if (widget.emptyAction != null) ...[
                  widget.emptyAction!,
                  const SizedBox(height: 12),
                ],
              ],
            ),
          for (final row in rows) widget.row(row, () => load(reset: true)),
          if (error != null)
            widget.errorBuilder?.call(
                  error!,
                  () => load(reset: rows.isEmpty),
                ) ??
                Panel(
                  child: Column(
                    children: [
                      Text('$error'),
                      DsButton(
                        label: '다시 시도',
                        onPressed: () => load(reset: rows.isEmpty),
                        variant: DsButtonVariant.ghost,
                        size: DsButtonSize.compact,
                      ),
                    ],
                  ),
                ),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (cursor != null && !loading)
            DsButton(
              label: '더 보기',
              onPressed: load,
              variant: DsButtonVariant.secondary,
            ),
        ],
      ),
    ),
  );
}
