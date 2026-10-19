import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/uploads.dart';
import '../ui/shared.dart';
import '../ui/collection.dart';
import 'social.dart';
import 'chat.dart';

String personalMeetupStatus(Json meetup) {
  if (meetup['status'] == 'CANCELLED') return '취소된 모임';
  if (meetup['status'] == 'COMPLETED') return '지난 모임';
  if (meetup['role'] == 'HOST') return '내가 연 모임';
  return switch (meetup['participationStatus']) {
    'ACTIVE' => '참여 확정',
    'PENDING' => '승인 대기',
    'REMOVED' => '참여 종료',
    'CANCELLED' => '참여 취소',
    _ => statusText(meetup['participationStatus']),
  };
}

class MyMeetupsScreen extends StatefulWidget {
  final Api api;
  const MyMeetupsScreen(this.api, {super.key});
  @override
  State<MyMeetupsScreen> createState() => _MyMeetupsScreenState();
}

class _MyMeetupsScreenState extends State<MyMeetupsScreen> {
  String scope = 'UPCOMING';
  @override
  Widget build(BuildContext context) => CollectionScreen(
    key: ValueKey(scope),
    api: widget.api,
    title: '나의 모임',
    path: '/me/meetups',
    query: {'scope': scope},
    header: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageIntro('함께 걷기로 한 약속', '참여 일정과 신청 결과를 한곳에서 확인해요.'),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFE9EDE5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'UPCOMING', label: Text('다가오는 모임')),
              ButtonSegment(value: 'PENDING', label: Text('신청 중')),
              ButtonSegment(value: 'HISTORY', label: Text('지난 내역')),
            ],
            selected: {scope},
            onSelectionChanged: (values) =>
                setState(() => scope = values.first),
          ),
        ),
        const SizedBox(height: 20),
      ],
    ),
    empty: switch (scope) {
      'PENDING' => '결과를 기다리는 신청이 없어요',
      'HISTORY' => '아직 지난 모임이 없어요',
      _ => '다가오는 산책 약속이 없어요',
    },
    emptyDetail: scope == 'UPCOMING'
        ? '동네에서 마음에 드는 산책 모임에 참여해보세요.'
        : '모임에 참여하면 이곳에서 내역을 볼 수 있어요.',
    emptyIcon: Icons.event_rounded,
    row: (meetup, _) => Panel(
      child: ListTile(
        leading: const FeatureIcon(Icons.event_rounded),
        title: Text(label(meetup['title'])),
        subtitle: Text(
          '${personalMeetupStatus(meetup)}\n${dateText(meetup['startsAt'])}\n${label(meetup['placeName'])}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: () =>
            openScreen(context, MeetupScreen(widget.api, label(meetup['id']))),
      ),
    ),
  );
}

class NeighborhoodScreen extends StatefulWidget {
  final Api api;
  const NeighborhoodScreen(this.api, {super.key});
  @override
  State<NeighborhoodScreen> createState() => _NeighborhoodScreenState();
}

class _NeighborhoodScreenState extends State<NeighborhoodScreen> {
  int tab = 0, revision = 0;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: DsButton(
            onPressed: () => openScreen(context, MyMeetupsScreen(widget.api)),
            icon: Icons.event_rounded,
            label: '나의 모임',
            variant: DsButtonVariant.ghost,
            size: DsButtonSize.compact,
          ),
        ),
      ),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFE9EDE5),
            borderRadius: BorderRadius.circular(16),
          ),
          width: double.infinity,
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 0, label: Text('동네 채널')),
              ButtonSegment(value: 1, label: Text('산책 모임')),
              ButtonSegment(value: 2, label: Text('지금 동행')),
            ],
            selected: {tab},
            onSelectionChanged: (values) => setState(() => tab = values.first),
          ),
        ),
      ),
      Expanded(
        child: CollectionScreen(
          key: ValueKey('$tab-$revision'),
          api: widget.api,
          title: ['우리 동네 이야기', '함께 걷는 약속', '지금, 같이 걸어요'][tab],
          embedded: true,
          empty: ['아직 동네 이야기가 없어요', '첫 산책 모임을 기다려요', '지금 함께 걸을 이웃을 찾아요'][tab],
          emptyDetail: [
            '우리 동네의 첫 이야기를 들려주세요.',
            '가벼운 산책 약속을 먼저 만들어보세요.',
            '산책을 나설 때 동행을 제안해보세요.',
          ][tab],
          emptyIcon: tab == 0
              ? Icons.forum_rounded
              : Icons.directions_walk_rounded,
          path: tab == 0 ? '/channels' : '/meetups',
          query: tab == 0 ? null : {'kind': tab == 1 ? 'SCHEDULED' : 'INSTANT'},
          row: (row, _) => Panel(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                tab == 0 ? Icons.forum_outlined : Icons.directions_walk,
                color: tint,
              ),
              title: Text(
                label(row[tab == 0 ? 'name' : 'title']),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                tab == 0
                    ? label(row['description'])
                    : '${row['placeName']}\n${dateText(row['startsAt'])} · ${statusText(row['status'])}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openScreen(
                context,
                tab == 0
                    ? ChannelScreen(widget.api, label(row['id']))
                    : MeetupScreen(widget.api, label(row['id'])),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              await Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => tab == 0
                      ? ChannelEditor(widget.api)
                      : MeetupEditor(widget.api, instant: tab == 2),
                ),
              );
              if (mounted) setState(() => revision++);
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    ],
  );
}

class ChannelEditor extends StatefulWidget {
  final Api api;
  const ChannelEditor(this.api, {super.key});
  @override
  State<ChannelEditor> createState() => _ChannelEditorState();
}

class _ChannelEditorState extends State<ChannelEditor> {
  final name = TextEditingController(), description = TextEditingController();
  final form = GlobalKey<FormState>();
  String key = uuid.v4();
  String type = 'NEIGHBORHOOD', join = 'OPEN', visibility = 'PUBLIC';
  String? region;
  Json? submitted;
  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppTopBar(title: const Text('우리 동네 채널 만들기')),
    body: AsyncView(
      load: () => widget.api.call('/regions'),
      builder: (data, reload) => Form(
        key: form,
        child: PageBody(
          children: [
            Input(name, '채널 이름'),
            Input(description, '채널 소개', lines: 3),
            DsSelectField<String>(
              initialValue: region,
              label: '활동 동네',
              items: [
                for (final r in items(data))
                  DropdownMenuItem(
                    value: label(r['id']),
                    child: Text(label(r['name'])),
                  ),
              ],
              onChanged: (v) => region = v,
            ),
            const SizedBox(height: 14),
            DsSelectField<String>(
              initialValue: type,
              label: '채널 종류',
              items: const [
                DropdownMenuItem(value: 'NEIGHBORHOOD', child: Text('동네')),
                DropdownMenuItem(value: 'RESIDENCE', child: Text('주거지')),
                DropdownMenuItem(value: 'INTEREST', child: Text('관심사')),
              ],
              onChanged: (v) => type = v!,
            ),
            const SizedBox(height: 14),
            DsSelectField<String>(
              initialValue: join,
              label: '가입 방법',
              items: const [
                DropdownMenuItem(value: 'OPEN', child: Text('바로 가입')),
                DropdownMenuItem(value: 'APPROVAL', child: Text('승인 후 가입')),
              ],
              onChanged: (v) => join = v!,
            ),
            const SizedBox(height: 14),
            DsSelectField<String>(
              initialValue: visibility,
              label: '공개 범위',
              items: const [
                DropdownMenuItem(value: 'PUBLIC', child: Text('전체 공개')),
                DropdownMenuItem(value: 'MEMBERS', child: Text('멤버 공개')),
              ],
              onChanged: (v) => visibility = v!,
            ),
            const SizedBox(height: 20),
            SubmitButton(
              '채널 만들기',
              onPressed: () async {
                if (!form.currentState!.validate()) return;
                if (region == null) throw const ApiFailure('활동 동네를 선택해주세요.');
                submitted ??= {
                  'name': name.text.trim(),
                  'description': description.text.trim(),
                  'type': type,
                  'joinMode': join,
                  'visibility': visibility,
                  'regionId': region,
                };
                final result = object(
                  await submitSnapshot(
                    widget.api,
                    '/channels',
                    method: 'POST',
                    data: submitted,
                    idempotencyKey: key,
                    onRejected: () {
                      submitted = null;
                      key = uuid.v4();
                    },
                  ),
                );
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ChannelScreen(widget.api, label(result['id'])),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class ChannelScreen extends StatelessWidget {
  final Api api;
  final String id;
  const ChannelScreen(this.api, this.id, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppTopBar(title: const Text('동네 채널')),
    body: AsyncView(
      load: () => api.call('/channels/$id'),
      builder: (data, reload) {
        final ch = object(data),
            member = ch['isMember'] == true,
            manager = ['OWNER', 'MODERATOR'].contains(ch['role']);
        return PageBody(
          children: [
            Panel(
              color: tintBackground,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.forum_outlined, size: 40, color: tint),
                  const SizedBox(height: 12),
                  Text(
                    label(ch['name']),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(label(ch['description'])),
                  if (ch['type'] == 'RESIDENCE')
                    const Text('주민 인증 여부는 별도로 확인되지 않았습니다.'),
                ],
              ),
            ),
            if (!member)
              SubmitButton(
                ch['joinMode'] == 'OPEN' ? '채널 가입하기' : '가입 승인 요청',
                onPressed: () async {
                  final result = object(
                    await api.call('/channels/$id/memberships', method: 'POST'),
                  );
                  reload();
                  if (context.mounted) {
                    toast(
                      context,
                      result['status'] == 'PENDING'
                          ? '가입 승인을 기다려주세요.'
                          : '채널에 가입했어요.',
                    );
                  }
                },
              ),
            const SizedBox(height: 12),
            DsButton(
              onPressed: () => openScreen(context, PostsScreen(api, id)),
              icon: Icons.article_outlined,
              label: '우리 동네 게시글',
            ),
            if (ch['roomId'] != null)
              DsButton(
                label: '채널 대화방',
                onPressed: () =>
                    openScreen(context, ChatScreen(api, label(ch['roomId']))),
                variant: DsButtonVariant.secondary,
              ),
            if (member) ...[
              DsButton(
                label: '채널 멤버',
                onPressed: () =>
                    openScreen(context, ChannelMembersScreen(api, ch)),
                variant: DsButtonVariant.secondary,
              ),
              if (manager)
                DsButton(
                  label: '가입 요청 관리',
                  onPressed: () => openScreen(
                    context,
                    CollectionScreen(
                      api: api,
                      title: '가입 승인 요청',
                      path: '/channels/$id/join-requests',
                      row: (row, reload) => Panel(
                        child: Column(
                          children: [
                            Text(label(row['displayName'])),
                            for (final a in ['approve', 'reject'])
                              DsButton(
                                label: a == 'approve' ? '가입 승인' : '가입 거절',
                                onPressed: () => action(context, () async {
                                  await api.call(
                                    '/channels/$id/join-requests/${row['id']}/$a',
                                    method: 'POST',
                                  );
                                  reload();
                                }),
                                variant: DsButtonVariant.ghost,
                                size: DsButtonSize.compact,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  variant: DsButtonVariant.secondary,
                ),
              DsButton(
                label: '채널 탈퇴',
                onPressed: () => action(context, () async {
                  if (!await confirm(
                    context,
                    '채널 탈퇴',
                    '채널을 떠날까요? 대표 관리자는 먼저 권한을 이전해야 합니다.',
                  )) {
                    return;
                  }
                  await api.call('/channels/$id/memberships', method: 'DELETE');
                  reload();
                }),
                variant: DsButtonVariant.ghost,
                size: DsButtonSize.compact,
              ),
            ],
            if (ch['role'] == 'OWNER')
              DsButton(
                label: '채널 보관',
                onPressed: () => action(context, () async {
                  if (!await confirm(
                    context,
                    '채널 보관',
                    '채널의 새로운 활동을 중단하고 보관할까요?',
                  )) {
                    return;
                  }
                  await api.call('/channels/$id/archive', method: 'POST');
                  if (context.mounted) Navigator.pop(context);
                }),
                variant: DsButtonVariant.ghost,
                size: DsButtonSize.compact,
              ),
          ],
        );
      },
    ),
  );
}

class ChannelMembersScreen extends StatelessWidget {
  final Api api;
  final Json channel;
  const ChannelMembersScreen(this.api, this.channel, {super.key});
  @override
  Widget build(BuildContext context) => CollectionScreen(
    api: api,
    title: '채널 멤버',
    path: '/channels/${channel['id']}/members',
    row: (row, reload) => Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${row['displayName']} · ${row['role']}'),
          if (channel['role'] == 'OWNER' && row['role'] != 'OWNER')
            Wrap(
              children: [
                DsButton(
                  label: '대표 이전',
                  onPressed: () => action(context, () async {
                    if (!await confirm(
                      context,
                      '대표 권한 이전',
                      '이 멤버에게 채널 대표 권한을 이전할까요?',
                    )) {
                      return;
                    }
                    await api.call(
                      '/channels/${channel['id']}/transfer-ownership',
                      method: 'POST',
                      data: {'userId': row['userId']},
                    );
                    if (context.mounted) Navigator.pop(context);
                  }),
                  variant: DsButtonVariant.ghost,
                  size: DsButtonSize.compact,
                ),
                DsButton(
                  label: '내보내기',
                  onPressed: () => action(context, () async {
                    if (!await confirm(
                      context,
                      '멤버 내보내기',
                      '이 멤버를 채널에서 내보낼까요?',
                    )) {
                      return;
                    }
                    await api.call(
                      '/channels/${channel['id']}/members/${row['userId']}',
                      method: 'DELETE',
                    );
                    reload();
                  }),
                  variant: DsButtonVariant.ghost,
                  size: DsButtonSize.compact,
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

class PostsScreen extends StatefulWidget {
  final Api api;
  final String channelId;
  const PostsScreen(this.api, this.channelId, {super.key});
  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  int revision = 0;
  @override
  Widget build(BuildContext context) => CollectionScreen(
    key: ValueKey(revision),
    api: widget.api,
    title: '동네 이야기',
    path: '/posts',
    query: {'channelId': widget.channelId},
    row: (row, _) => Panel(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label(row['title'])),
        subtitle: Text('${row['authorName']} · ${dateText(row['created_at'])}'),
        onTap: () =>
            openScreen(context, PostScreen(widget.api, label(row['id']))),
      ),
    ),
    floatingActionButton: FloatingActionButton(
      child: const Icon(Icons.edit_outlined),
      onPressed: () async {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => PostEditor(widget.api, widget.channelId),
          ),
        );
        if (mounted) setState(() => revision++);
      },
    ),
  );
}

class PostEditor extends StatefulWidget {
  final Api api;
  final String channelId;
  final Json? post;
  const PostEditor(this.api, this.channelId, {super.key, this.post});
  @override
  State<PostEditor> createState() => _PostEditorState();
}

class _PostEditorState extends State<PostEditor> {
  final form = GlobalKey<FormState>();
  late final title = TextEditingController(text: label(widget.post?['title']));
  late final body = TextEditingController(text: label(widget.post?['body']));
  String key = uuid.v4();
  final photos = <String>[];
  Json? submitted;
  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppTopBar(
      title: Text(widget.post == null ? '동네 이야기 쓰기' : '이야기 수정'),
    ),
    body: Form(
      key: form,
      child: PageBody(
        children: [
          Input(title, '제목'),
          Input(body, '이야기를 나눠주세요', lines: 10),
          if (widget.post == null)
            SubmitButton(
              '사진 첨부 (${photos.length}/10)',
              onPressed: () async {
                if (photos.length >= 10) {
                  throw const ApiFailure('사진은 최대 10장까지 등록할 수 있어요.');
                }
                final id = await Uploads(widget.api).pick('POST_IMAGE');
                if (mounted && id != null) setState(() => photos.add(id));
              },
            ),
          const SizedBox(height: 14),
          SubmitButton(
            '저장하기',
            onPressed: () async {
              if (!form.currentState!.validate()) return;
              submitted ??= {
                'title': title.text.trim(),
                'body': body.text.trim(),
                if (widget.post == null) ...{
                  'channelId': widget.channelId,
                  'uploadIds': List.of(photos),
                } else
                  'version': widget.post!['version'],
              };
              await submitSnapshot(
                widget.api,
                widget.post == null ? '/posts' : '/posts/${widget.post!['id']}',
                method: widget.post == null ? 'POST' : 'PATCH',
                data: submitted,
                idempotencyKey: widget.post == null ? key : null,
                onRejected: () {
                  submitted = null;
                  key = uuid.v4();
                },
              );
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}

class PostScreen extends StatelessWidget {
  final Api api;
  final String id;
  const PostScreen(this.api, this.id, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppTopBar(
      title: const Text('동네 이야기'),
      actions: [
        IconButton(
          icon: const Icon(Icons.flag_outlined),
          onPressed: () =>
              action(context, () => report(context, api, 'POST', id)),
        ),
      ],
    ),
    body: AsyncView(
      load: () => api.call('/posts/$id'),
      builder: (data, reload) {
        final post = object(data);
        return PageBody(
          children: [
            Text(
              label(post['title']),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            Text(dateText(post['createdAt'])),
            const SizedBox(height: 22),
            SelectableText(
              label(post['body']),
              style: const TextStyle(height: 1.7, fontSize: 16),
            ),
            const SizedBox(height: 20),
            for (final image in records(post['uploads']))
              MediaPhoto(api, label(image['id'])),
            if (post['authorId'] == api.userId)
              Wrap(
                children: [
                  DsButton(
                    label: '수정',
                    onPressed: () async {
                      await Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostEditor(
                            api,
                            label(post['channelId']),
                            post: post,
                          ),
                        ),
                      );
                      reload();
                    },
                    variant: DsButtonVariant.ghost,
                    size: DsButtonSize.compact,
                  ),
                  DsButton(
                    label: '삭제',
                    onPressed: () => action(context, () async {
                      if (!await confirm(context, '게시글 삭제', '이 이야기를 삭제할까요?')) {
                        return;
                      }
                      await api.call('/posts/$id', method: 'DELETE');
                      if (context.mounted) Navigator.pop(context);
                    }),
                    variant: DsButtonVariant.ghost,
                    size: DsButtonSize.compact,
                  ),
                ],
              ),
            DsButton(
              label: '댓글 보기 · 작성',
              onPressed: () => openScreen(context, CommentsScreen(api, id)),
            ),
          ],
        );
      },
    ),
  );
}

class CommentsScreen extends StatefulWidget {
  final Api api;
  final String postId;
  const CommentsScreen(this.api, this.postId, {super.key});
  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  int revision = 0;
  @override
  Widget build(BuildContext context) => CollectionScreen(
    key: ValueKey(revision),
    api: widget.api,
    title: '댓글',
    path: '/posts/${widget.postId}/comments',
    row: (row, reload) => Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label(row['authorName']),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(label(row['body'])),
          Wrap(
            children: [
              if (row['authorId'] == widget.api.userId) ...[
                DsButton(
                  label: '수정',
                  onPressed: () => action(context, () async {
                    final body = await askText(
                      context,
                      '댓글 수정',
                      initial: label(row['body']),
                    );
                    if (body == null) return;
                    await widget.api.call(
                      '/comments/${row['id']}',
                      method: 'PATCH',
                      data: {'body': body, 'version': row['version']},
                    );
                    reload();
                  }),
                  variant: DsButtonVariant.ghost,
                  size: DsButtonSize.compact,
                ),
                DsButton(
                  label: '삭제',
                  onPressed: () => action(context, () async {
                    if (!await confirm(context, '댓글 삭제', '댓글을 삭제할까요?')) return;
                    await widget.api.call(
                      '/comments/${row['id']}',
                      method: 'DELETE',
                    );
                    reload();
                  }),
                  variant: DsButtonVariant.ghost,
                  size: DsButtonSize.compact,
                ),
              ],
              DsButton(
                label: '신고',
                onPressed: () => action(
                  context,
                  () =>
                      report(context, widget.api, 'COMMENT', label(row['id'])),
                ),
                variant: DsButtonVariant.ghost,
                size: DsButtonSize.compact,
              ),
            ],
          ),
        ],
      ),
    ),
    floatingActionButton: FloatingActionButton(
      child: const Icon(Icons.add_comment_outlined),
      onPressed: () => action(context, () async {
        final body = await askText(context, '따뜻한 댓글을 남겨주세요.');
        if (body == null) return;
        await widget.api.call(
          '/posts/${widget.postId}/comments',
          method: 'POST',
          data: {'body': body},
        );
        if (mounted) setState(() => revision++);
      }),
    ),
  );
}

class MeetupEditor extends StatefulWidget {
  final Api api;
  final bool instant;
  const MeetupEditor(this.api, {super.key, this.instant = false});
  @override
  State<MeetupEditor> createState() => _MeetupEditorState();
}

class _MeetupEditorState extends State<MeetupEditor> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController(),
      description = TextEditingController(),
      capacity = TextEditingController(text: '4');
  late DateTime start = DateTime.now().add(
    Duration(minutes: widget.instant ? 1 : 60),
  );
  int duration = 60;
  String? place;
  List<String> dogs = [];
  final activities = <String>{'WALK'};
  final sizes = <String>{'SMALL', 'MEDIUM', 'LARGE'};
  String key = uuid.v4();
  Json? submitted;
  @override
  void dispose() {
    title.dispose();
    description.dispose();
    capacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppTopBar(title: Text(widget.instant ? '지금 함께 걸어요' : '산책 모임 만들기')),
    body: AsyncView(
      load: () => widget.api.call('/places'),
      builder: (data, reload) => Form(
        key: form,
        child: PageBody(
          children: [
            Input(title, '모임 이름'),
            Input(description, '모임 소개', lines: 3),
            DsSelectField<String>(
              initialValue: place,
              isExpanded: true,
              label: '공개 장소',
              items: [
                for (final p in items(data))
                  DropdownMenuItem(
                    value: label(p['id']),
                    child: Text(
                      label(p['name']),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => place = v,
            ),
            const SizedBox(height: 12),
            if (!widget.instant)
              DsButton(
                label: '시작: ${dateText(start.toIso8601String())}',
                onPressed: () async {
                  final date = await showDsDatePicker(
                    context,
                    title: '산책 날짜',
                    initialDate: start,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 180)),
                  );
                  if (date == null || !context.mounted) return;
                  final time = await showDsTimePicker(
                    context,
                    initialTime: TimeOfDay.fromDateTime(start),
                  );
                  if (time != null && mounted) {
                    setState(
                      () => start = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      ),
                    );
                  }
                },
                variant: DsButtonVariant.secondary,
              ),
            DsSelectField<int>(
              initialValue: duration,
              label: '모임 시간',
              items: [
                for (final d in [30, 60, 90, 120])
                  DropdownMenuItem(value: d, child: Text('$d분')),
              ],
              onChanged: (v) => duration = v!,
            ),
            const SizedBox(height: 12),
            Input(
              capacity,
              '함께할 인원',
              keyboard: TextInputType.number,
              suffix: '명',
            ),
            const Section('함께할 활동'),
            Wrap(
              spacing: 6,
              children: [
                for (final a in ['WALK', 'CAFE', 'FRIEND'])
                  DsChip(
                    label: statusText(a),
                    selected: activities.contains(a),
                    onSelected: (v) => setState(() {
                      v ? activities.add(a) : activities.remove(a);
                    }),
                  ),
              ],
            ),
            const Section('참여할 수 있는 크기'),
            Wrap(
              spacing: 6,
              children: [
                for (final s in ['SMALL', 'MEDIUM', 'LARGE'])
                  DsChip(
                    label: statusText(s),
                    selected: sizes.contains(s),
                    onSelected: (v) => setState(() {
                      v ? sizes.add(s) : sizes.remove(s);
                    }),
                  ),
              ],
            ),
            DsButton(
              label: '동행 강아지 ${dogs.length}마리',
              onPressed: () => action(context, () async {
                final selected = await selectDogs(context, widget.api);
                if (mounted && selected != null) {
                  setState(() => dogs = selected);
                }
              }),
              variant: DsButtonVariant.secondary,
            ),
            const SizedBox(height: 14),
            SubmitButton(
              '모임 만들기',
              onPressed: () async {
                if (!form.currentState!.validate()) return;
                final count = int.tryParse(capacity.text);
                if (place == null ||
                    dogs.isEmpty ||
                    activities.isEmpty ||
                    sizes.isEmpty) {
                  throw const ApiFailure('장소·강아지·활동·참여 크기를 선택해주세요.');
                }
                if (count == null || count < 2 || count > 50) {
                  throw const ApiFailure('정원은 2~50명으로 입력해주세요.');
                }
                final begins = widget.instant ? DateTime.now() : start;
                if (!widget.instant && begins.isBefore(DateTime.now())) {
                  throw const ApiFailure('미래의 시작 시간을 선택해주세요.');
                }
                submitted ??= {
                  'title': title.text.trim(),
                  'description': description.text.trim(),
                  'kind': widget.instant ? 'INSTANT' : 'SCHEDULED',
                  'activities': activities.toList(),
                  'placeId': place,
                  'startsAt': begins.toUtc().toIso8601String(),
                  'endsAt': begins
                      .add(Duration(minutes: duration))
                      .toUtc()
                      .toIso8601String(),
                  'capacity': count,
                  'dogIds': List.of(dogs),
                  'allowedSizes': sizes.toList(),
                };
                final result = object(
                  await submitSnapshot(
                    widget.api,
                    '/meetups',
                    method: 'POST',
                    data: submitted,
                    idempotencyKey: key,
                    onRejected: () {
                      submitted = null;
                      key = uuid.v4();
                    },
                  ),
                );
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          MeetupScreen(widget.api, label(result['id'])),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class MeetupScreen extends StatelessWidget {
  final Api api;
  final String id;
  const MeetupScreen(this.api, this.id, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppTopBar(
      title: const Text('함께 걷는 모임'),
      actions: [
        IconButton(
          onPressed: () =>
              action(context, () => report(context, api, 'MEETUP', id)),
          icon: const Icon(Icons.flag_outlined),
        ),
      ],
    ),
    body: AsyncView(
      load: () => api.call('/meetups/$id'),
      builder: (data, reload) {
        final meetup = object(data),
            application = object(object(data)['application']);
        final host = meetup['hostId'] == api.userId;
        return PageBody(
          children: [
            Panel(
              color: tintBackground,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.directions_walk, size: 48, color: tint),
                  const SizedBox(height: 12),
                  Text(
                    label(meetup['title']),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(statusText(meetup['status'])),
                  const SizedBox(height: 12),
                  Text(label(meetup['description'])),
                ],
              ),
            ),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('장소: ${object(meetup['place'])['name']}'),
                  Text(label(object(meetup['place'])['address'])),
                  Text(
                    '${dateText(meetup['startsAt'])} ~ ${dateText(meetup['endsAt'])}',
                  ),
                  Text('보호자 정원 ${meetup['capacity']}명'),
                  Text(
                    (meetup['allowedSizes'] as List? ?? [])
                        .map(statusText)
                        .join(' · '),
                  ),
                ],
              ),
            ),
            if (meetup['roomId'] != null)
              DsButton(
                label: '모임 대화방',
                onPressed: () => openScreen(
                  context,
                  ChatScreen(api, label(meetup['roomId'])),
                ),
              ),
            if (!host &&
                meetup['status'] == 'OPEN' &&
                !['PENDING', 'APPROVED'].contains(application['status']))
              SubmitButton(
                '참여 신청하기',
                onPressed: () async {
                  final dogs = await selectDogs(context, api);
                  if (dogs == null) return;
                  await api.call(
                    '/meetups/$id/applications',
                    method: 'POST',
                    data: {'dogIds': dogs},
                  );
                  reload();
                },
              ),
            if (!host &&
                ['PENDING', 'APPROVED'].contains(application['status'])) ...[
              Text('나의 참여 상태: ${statusText(application['status'])}'),
              SubmitButton(
                '참여 취소',
                onPressed: () async {
                  await api.call(
                    '/meetup-applications/${application['id']}/cancel',
                    method: 'POST',
                  );
                  reload();
                },
              ),
            ],
            const Section('함께하는 보호자'),
            for (final member in records(meetup['participants']))
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(label(member['displayName'])),
                trailing: host && member['userId'] != api.userId
                    ? IconButton(
                        icon: const Icon(Icons.person_remove_outlined),
                        onPressed: () => action(context, () async {
                          if (!await confirm(
                            context,
                            '참여자 내보내기',
                            '모임에서 이 참여자를 내보낼까요?',
                          )) {
                            return;
                          }
                          await api.call(
                            '/meetups/$id/participants/${member['userId']}',
                            method: 'DELETE',
                          );
                          reload();
                        }),
                      )
                    : null,
              ),
            if (host) ...[
              DsButton(
                label: '참여 신청 관리',
                onPressed: () => openScreen(
                  context,
                  CollectionScreen(
                    api: api,
                    title: '참여 신청 관리',
                    path: '/meetups/$id/applications',
                    row: (row, reload) => Panel(
                      child: Column(
                        children: [
                          Text(
                            '${row['displayName']} · ${statusText(row['status'])}',
                          ),
                          if (row['status'] == 'PENDING')
                            Wrap(
                              children: [
                                for (final a in ['approve', 'reject'])
                                  DsButton(
                                    label: a == 'approve' ? '승인' : '거절',
                                    onPressed: () => action(context, () async {
                                      await api.call(
                                        '/meetup-applications/${row['id']}/$a',
                                        method: 'POST',
                                      );
                                      reload();
                                    }),
                                    variant: DsButtonVariant.ghost,
                                    size: DsButtonSize.compact,
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                variant: DsButtonVariant.secondary,
              ),
              if (meetup['kind'] == 'INSTANT' && meetup['status'] == 'OPEN')
                SubmitButton(
                  '동행 30분 연장',
                  onPressed: () async {
                    final end = DateTime.parse(label(meetup['endsAt']))
                        .add(const Duration(minutes: 30));
                    await api.call(
                      '/meetups/$id',
                      method: 'PATCH',
                      data: {
                        'version': meetup['version'],
                        'endsAt': end.toUtc().toIso8601String(),
                      },
                    );
                    reload();
                  },
                ),
              DsButton(
                label: '모임 취소',
                onPressed: () => action(context, () async {
                  if (!await confirm(context, '모임 취소', '이 모임을 취소할까요?')) return;
                  await api.call('/meetups/$id/cancel', method: 'POST');
                  reload();
                }),
                variant: DsButtonVariant.ghost,
                size: DsButtonSize.compact,
              ),
            ],
          ],
        );
      },
    ),
  );
}
