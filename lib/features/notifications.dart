import 'package:flutter/material.dart';

import '../core/api.dart';
import '../ui/shared.dart';
import '../ui/collection.dart';
import 'social.dart';
import 'profile.dart';
import 'chat.dart';
import 'community.dart';

class NotificationBell extends StatefulWidget {
  final Api api;
  final Object refreshKey;
  const NotificationBell(this.api, {super.key, required this.refreshKey});
  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with WidgetsBindingObserver {
  int unread = 0, generation = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    refresh();
  }

  @override
  void didUpdateWidget(covariant NotificationBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey ||
        oldWidget.api != widget.api) {
      refresh();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  @override
  void dispose() {
    generation++;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> refresh() async {
    final request = ++generation;
    try {
      final data = object(await widget.api.call('/notifications/summary'));
      if (mounted && request == generation) {
        setState(() => unread = (data['unreadCount'] as num?)?.toInt() ?? 0);
      }
    } catch (_) {
      // Keep the last known count during a transient connection failure.
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: '알림',
    onPressed: () async {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => NotificationsScreen(widget.api),
        ),
      );
      if (mounted) await refresh();
    },
    icon: Semantics(
      label: unread == 0 ? '새 알림 없음' : '읽지 않은 알림 $unread개',
      child: Badge.count(
        count: unread,
        isLabelVisible: unread > 0,
        child: const Icon(Icons.notifications_none_rounded),
      ),
    ),
  );
}

class NotificationsScreen extends StatefulWidget {
  final Api api;
  const NotificationsScreen(this.api, {super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with WidgetsBindingObserver {
  Json? summary;
  bool unreadOnly = false, marking = false, summaryCurrent = false;
  int revision = 0, generation = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    refreshSummary();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() => revision++);
      refreshSummary();
    }
  }

  @override
  void dispose() {
    generation++;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> refreshSummary() async {
    if (!mounted) return;
    final request = ++generation;
    setState(() => summaryCurrent = false);
    try {
      final data = object(await widget.api.call('/notifications/summary'));
      if (mounted && request == generation) {
        setState(() {
          summary = data;
          summaryCurrent = true;
        });
      }
    } catch (_) {
      // The list retains its own retry control when the API is unavailable.
    }
  }

  Future<void> markAll() async {
    final before = summary?['asOf'];
    if (before == null || marking || !summaryCurrent) return;
    setState(() => marking = true);
    try {
      await widget.api.call(
        '/notifications/read-all',
        method: 'PUT',
        data: {'before': before},
      );
      if (!mounted) return;
      setState(() => revision++);
      await refreshSummary();
    } catch (error) {
      if (mounted) toast(context, error);
    } finally {
      if (mounted) setState(() => marking = false);
    }
  }

  Future<void> openNotification(Json notification, VoidCallback reload) async {
    await action(context, () async {
      await widget.api.call(
        '/notifications/${notification['id']}/read',
        method: 'PUT',
      );
      if (!mounted) return;
      reload();
      await refreshSummary();
      if (!mounted || notification['resourceId'] == null) return;
      final id = label(notification['resourceId']);
      final target = switch (notification['kind']) {
        'proposals' => ProposalScreen(widget.api, id),
        'messages' => ChatScreen(widget.api, id),
        'meetups' => MeetupScreen(widget.api, id),
        'reviews' => Scaffold(
          appBar: const AppTopBar(title: Text('우리 강아지 관리')),
          body: ProfileScreen(widget.api),
        ),
        'friends' => FriendsScreen(widget.api),
        _ => null,
      };
      if (target != null) {
        await Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => target));
        if (mounted) await refreshSummary();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final unread = (summary?['unreadCount'] as num?)?.toInt() ?? 0;
    return CollectionScreen(
      key: ValueKey('$unreadOnly-$revision'),
      api: widget.api,
      title: '댕글의 소식',
      path: '/notifications',
      query: {'unreadOnly': '$unreadOnly'},
      onRefresh: refreshSummary,
      actions: [
        DsButton(
          label: marking ? '처리 중' : '모두 읽기',
          onPressed: unread == 0 || marking || !summaryCurrent ? null : markAll,
          variant: DsButtonVariant.ghost,
          size: DsButtonSize.compact,
        ),
      ],
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageIntro(
            '반가운 소식을 모았어요',
            summary == null
                ? '제안과 모임, 친구의 소식을 확인해요.'
                : '읽지 않은 소식이 $unread개 있어요.',
          ),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: false, label: Text('전체')),
              ButtonSegment(value: true, label: Text('안 읽음')),
            ],
            selected: {unreadOnly},
            onSelectionChanged: (values) {
              setState(() => unreadOnly = values.first);
              refreshSummary();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
      empty: unreadOnly ? '안 읽은 알림이 없어요' : '아직 도착한 소식이 없어요',
      emptyIcon: Icons.notifications_none_rounded,
      emptyDetail: '새로운 제안과 모임 소식이 오면 알려드릴게요.',
      row: (notification, reload) => Panel(
        color: notification['readAt'] == null ? tintBackground : Colors.white,
        child: ListTile(
          leading: FeatureIcon(switch (notification['kind']) {
            'meetups' => Icons.event_rounded,
            'messages' => Icons.chat_bubble_rounded,
            'reviews' => Icons.verified_user_rounded,
            'friends' => Icons.people_rounded,
            _ => Icons.mail_rounded,
          }),
          title: Text(label(notification['title'])),
          subtitle: Text(dateText(notification['created_at'])),
          trailing: notification['readAt'] == null
              ? const Icon(Icons.circle, size: 7, color: tint)
              : null,
          onTap: () => openNotification(notification, reload),
        ),
      ),
    );
  }
}
