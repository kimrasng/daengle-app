import 'package:flutter/material.dart';

import '../core/api.dart';
import '../ui/shared.dart';
import '../ui/collection.dart';
import 'chat.dart';
import 'readiness.dart';

String _recommendationReasonLabel(dynamic reason) => reason is Map
    ? label(reason['label'])
    : reason is String
    ? reason
    : '';

Future<List<String>?> selectDogs(
  BuildContext context,
  Api api, {
  String title = '함께할 강아지 선택',
}) async {
  final dogs = items(await api.call('/dogs'))
      .where((d) => d['canParticipate'] == true)
      .toList();
  if (!context.mounted) return null;
  if (dogs.isEmpty) {
    throw const ApiFailure('승인된 강아지가 필요해요. 마이에서 건강 심사를 확인해주세요.');
  }
  final selected = <String>{};
  return showDialog<List<String>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, update) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final dog in dogs)
                DsCheckbox(
                  label: label(dog['name']),
                  value: selected.contains(dog['id']),
                  onChanged: (v) => update(() {
                    v == true
                        ? selected.add(dog['id'])
                        : selected.remove(dog['id']);
                  }),
                ),
            ],
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
            label: '선택 완료',
            onPressed: selected.isEmpty
                ? null
                : () => Navigator.pop(context, selected.toList()),
          ),
        ],
      ),
    ),
  );
}

Future<void> report(
  BuildContext context,
  Api api,
  String type,
  String id,
) async {
  final reason = await askText(context, '신고 사유를 입력해주세요.');
  if (reason == null) return;
  await api.call(
    '/reports',
    method: 'POST',
    data: {
      'targetType': type,
      'targetId': id,
      'reason': reason,
      'description': '',
    },
  );
  if (context.mounted) toast(context, '신고가 접수되었어요.');
}

class DogCard extends StatelessWidget {
  final Api api;
  final Json dog;
  final bool linkToDetail;
  const DogCard(this.api, this.dog, {super.key, this.linkToDetail = true});
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(24),
    onTap: linkToDetail
        ? () => openScreen(context, PublicDogScreen(api, label(dog['id'])))
        : null,
    child: Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 31,
                backgroundColor: tintBackground,
                child: Icon(Icons.pets, color: tint, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label(dog['name']),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 23,
                      ),
                    ),
                    Text('${dog['breed']} · ${statusText(dog['size'])}'),
                  ],
                ),
              ),
              if (dog['distanceMeters'] != null)
                Text(
                  '${(dog['distanceMeters'] as num) / 1000}km 이내',
                  style: const TextStyle(fontSize: 12, color: tint),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final trait in (dog['traits'] as List? ?? []).take(4))
                Chip(
                  label: Text(label(trait)),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          for (final reason
              in (dog['reasons'] as List? ?? [])
                  .map(_recommendationReasonLabel)
                  .where((text) => text.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('✓ $reason', style: const TextStyle(color: tint)),
            ),
          const SizedBox(height: 6),
          if (linkToDetail)
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                '친구 알아보기 →',
                style: TextStyle(fontWeight: FontWeight.w700, color: tint),
              ),
            ),
        ],
      ),
    ),
  );
}

class DiscoveryScreen extends StatefulWidget {
  final Api api;
  final bool embedded;
  const DiscoveryScreen(this.api, {super.key, this.embedded = false});
  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  int radius = 5000, revision = 0;
  String? size, period;
  @override
  Widget build(BuildContext context) => CollectionScreen(
    key: ValueKey(revision),
    api: widget.api,
    title: '우리 아이의 새로운 친구',
    embedded: widget.embedded,
    path: '/discovery/dogs',
    query: {
      'radiusMeters': radius,
      if (size != null) 'size': size,
      if (period != null) 'walkPeriod': period,
    },
    empty: '이 조건에 맞는 친구를 기다리고 있어요.',
    row: (dog, _) => DogCard(widget.api, dog),
    errorBuilder: (error, retry) =>
        activityRecovery(context, widget.api, error),
    emptyAction: radius < 30000
        ? DsButton(
            onPressed: () => setState(() {
              radius = 30000;
              revision++;
            }),
            icon: Icons.travel_explore_rounded,
            label: '30km까지 넓혀보기',
            variant: DsButtonVariant.secondary,
          )
        : null,
    header: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageIntro('내 주변 강아지', '함께 걷기 좋은 친구를 찾아보세요.'),
        Row(
          children: [
            const Icon(Icons.near_me_rounded, size: 16, color: tint),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${radius ~/ 1000}km 이내 · ${size == null ? '모든 크기' : statusText(size)}',
                style: const TextStyle(fontSize: 13, color: secondaryLabel),
              ),
            ),
            DsButton(
              icon: Icons.tune_rounded,
              label: '조건 설정',
              onPressed: () async {
                var draftRadius = radius;
                var draftSize = size;
                var draftPeriod = period;
                final applied = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => SafeArea(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.viewInsetsOf(context).bottom,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: StatefulBuilder(
                          builder: (context, update) => Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '어떤 친구를 만나볼까요?',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 18),
                              DsSelectField<int>(
                                initialValue: draftRadius,
                                label: '검색 거리',
                                items: [
                                  for (final r in [
                                    1000,
                                    3000,
                                    5000,
                                    10000,
                                    30000,
                                    100000,
                                  ])
                                    DropdownMenuItem(
                                      value: r,
                                      child: Text('${r ~/ 1000}km'),
                                    ),
                                ],
                                onChanged: (v) =>
                                    update(() => draftRadius = v!),
                              ),
                              const SizedBox(height: 14),
                              DsSelectField<String>(
                                initialValue: draftSize ?? '',
                                label: '강아지 크기',
                                items: [
                                  const DropdownMenuItem(
                                    value: '',
                                    child: Text('모두'),
                                  ),
                                  for (final s in ['SMALL', 'MEDIUM', 'LARGE'])
                                    DropdownMenuItem(
                                      value: s,
                                      child: Text(statusText(s)),
                                    ),
                                ],
                                onChanged: (v) =>
                                    draftSize = v == '' ? null : v,
                              ),
                              const SizedBox(height: 14),
                              DsSelectField<String>(
                                initialValue: draftPeriod ?? '',
                                label: '산책 시간',
                                items: [
                                  const DropdownMenuItem(
                                    value: '',
                                    child: Text('모두'),
                                  ),
                                  for (final p in [
                                    'DAWN',
                                    'MORNING',
                                    'AFTERNOON',
                                    'EVENING',
                                    'NIGHT',
                                  ])
                                    DropdownMenuItem(
                                      value: p,
                                      child: Text(statusText(p)),
                                    ),
                                ],
                                onChanged: (v) =>
                                    draftPeriod = v == '' ? null : v,
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: DsButton(
                                  label: '친구 찾아보기',
                                  onPressed: () => Navigator.pop(context, true),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
                if (applied == true && mounted) {
                  setState(() {
                    radius = draftRadius;
                    size = draftSize;
                    period = draftPeriod;
                    revision++;
                  });
                }
              },
              variant: DsButtonVariant.ghost,
              size: DsButtonSize.compact,
            ),
          ],
        ),
        const SizedBox(height: 14),
      ],
    ),
    emptyDetail: '조건을 조금 넓히거나,\n새로운 친구가 올 때 다시 찾아주세요.',
    emptyIcon: Icons.pets_rounded,
  );
}

class PublicDogScreen extends StatelessWidget {
  final Api api;
  final String id;
  const PublicDogScreen(this.api, this.id, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppTopBar(
      title: const Text('친구 알아보기'),
      actions: [
        IconButton(
          icon: const Icon(Icons.flag_outlined),
          onPressed: () =>
              action(context, () => report(context, api, 'DOG', id)),
        ),
      ],
    ),
    body: AsyncView(
      load: () => api.call('/dogs/$id/public-profile'),
      builder: (data, reload) {
        final dog = object(data), owners = records(object(data)['owners']);
        return PageBody(
          children: [
            for (final photo in records(dog['photos']))
              MediaPhoto(api, label(photo['uploadId'])),
            DogCard(api, dog, linkToDetail: false),
            if (label(dog['precautions']).isNotEmpty)
              Panel(child: Text('알아두면 좋아요\n${dog['precautions']}')),
            const Section('함께 산책하는 보호자'),
            for (final owner in owners)
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guardianNameText(owner['displayName']),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      '산책 ${owner['maxWalkMinutes']}분 · ${(owner['walkPeriods'] as List? ?? []).map(statusText).join(', ')}',
                    ),
                    if (owner['ageBand'] != null)
                      Text('나이대 ${owner['ageBand']}'),
                    Wrap(
                      spacing: 8,
                      children: [
                        DsButton(
                          label: '함께하자고 제안',
                          onPressed: () => openScreen(
                            context,
                            ProposalComposer(api, dog, owner),
                          ),
                        ),
                        DsButton(
                          label: '친구 요청',
                          onPressed: () => action(context, () async {
                            await api.call(
                              '/friend-requests',
                              method: 'POST',
                              data: {'recipientId': owner['userId']},
                            );
                            if (context.mounted) toast(context, '친구 요청을 보냈어요.');
                          }),
                          variant: DsButtonVariant.ghost,
                          size: DsButtonSize.compact,
                        ),
                        DsButton(
                          label: '차단',
                          onPressed: () => action(context, () async {
                            if (!await confirm(
                              context,
                              '사용자 차단',
                              '서로 추천과 교류가 제한됩니다. 차단할까요?',
                            )) {
                              return;
                            }
                            await api.call(
                              '/blocks',
                              method: 'POST',
                              data: {'userId': owner['userId']},
                            );
                            if (context.mounted) Navigator.pop(context);
                          }),
                          variant: DsButtonVariant.ghost,
                          size: DsButtonSize.compact,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    ),
  );
}

class ProposalComposer extends StatefulWidget {
  final Api api;
  final Json dog, owner;
  const ProposalComposer(this.api, this.dog, this.owner, {super.key});
  @override
  State<ProposalComposer> createState() => _ProposalComposerState();
}

class _ProposalComposerState extends State<ProposalComposer> {
  List<String> dogs = [];
  final activities = <String>{'WALK'};
  final key = uuid.v4();
  Json? preview, frozenBody;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppTopBar(title: const Text('함께할 시간을 제안해요')),
    body: PageBody(
      children: [
        Text(
          '${widget.dog['name']}와 무엇을 할까요?',
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            for (final a in ['WALK', 'CAFE', 'FRIEND'])
              DsChip(
                label: statusText(a),
                selected: activities.contains(a),
                onSelected: preview != null
                    ? null
                    : (v) => setState(() {
                        v ? activities.add(a) : activities.remove(a);
                      }),
              ),
          ],
        ),
        const SizedBox(height: 14),
        DsButton(
          label: dogs.isEmpty ? '함께 나갈 강아지 선택' : '강아지 ${dogs.length}마리 선택됨',
          onPressed: preview != null
              ? null
              : () => action(context, () async {
                  final selected = await selectDogs(context, widget.api);
                  if (mounted && selected != null) {
                    setState(() => dogs = selected);
                  }
                }),
          variant: DsButtonVariant.secondary,
        ),
        const SizedBox(height: 14),
        if (preview == null)
          SubmitButton(
            '제안 카드 미리보기',
            onPressed: () async {
              if (dogs.isEmpty || activities.isEmpty) {
                throw const ApiFailure('강아지와 활동을 선택해주세요.');
              }
              final body = {
                'recipientId': widget.owner['userId'],
                'targetDogId': widget.dog['id'],
                'dogIds': List.of(dogs),
                'activities': activities.toList(),
              };
              final card = object(
                await widget.api.call(
                  '/proposal-previews',
                  method: 'POST',
                  data: body,
                ),
              );
              if (mounted) {
                setState(() {
                  preview = card;
                  frozenBody = body;
                });
              }
            },
          )
        else ...[
          Panel(
            color: tintBackground,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.mail_outline, size: 38, color: tint),
                const SizedBox(height: 12),
                Text(
                  label(preview!['title']),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                for (final reason in preview!['reasons'] as List? ?? [])
                  Text(label(reason)),
                Text(activities.map(statusText).join(' · ')),
              ],
            ),
          ),
          SubmitButton(
            '제안 보내기',
            onPressed: () async {
              await widget.api.call(
                '/proposals',
                method: 'POST',
                data: frozenBody,
                idempotencyKey: key,
              );
              if (context.mounted) {
                toast(context, '제안을 보냈어요!');
                Navigator.pop(context);
              }
            },
          ),
        ],
      ],
    ),
  );
}

class ProposalsScreen extends StatefulWidget {
  final Api api;
  const ProposalsScreen(this.api, {super.key});
  @override
  State<ProposalsScreen> createState() => _ProposalsScreenState();
}

class _ProposalsScreenState extends State<ProposalsScreen> {
  bool sent = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppTopBar(
      title: const Text('활동 제안함'),
      actions: [
        DsButton(
          label: sent ? '받은 제안 보기' : '보낸 제안 보기',
          onPressed: () => setState(() => sent = !sent),
          variant: DsButtonVariant.ghost,
          size: DsButtonSize.compact,
        ),
      ],
    ),
    body: CollectionScreen(
      key: ValueKey(sent),
      api: widget.api,
      title: sent ? '내가 보낸 제안' : '나에게 온 제안',
      path: '/proposals',
      query: {'direction': sent ? 'SENT' : 'RECEIVED'},
      row: (row, _) => Panel(
        child: ListTile(
          title: Text(label(object(row['card'])['title'])),
          subtitle: Text(
            '${statusText(row['status'])} · ${dateText(row['expiresAt'])}까지',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () =>
              openScreen(context, ProposalScreen(widget.api, label(row['id']))),
        ),
      ),
    ),
  );
}

class ProposalScreen extends StatelessWidget {
  final Api api;
  final String id;
  const ProposalScreen(this.api, this.id, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppTopBar(title: const Text('함께하자는 제안')),
    body: AsyncView(
      load: () => api.call('/proposals/$id'),
      builder: (value, reload) {
        final proposal = object(value), card = object(object(value)['card']);
        final received = proposal['recipientId'] == api.userId;
        return PageBody(
          children: [
            Panel(
              color: tintBackground,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label(card['title']),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    (proposal['activities'] as List? ?? [])
                        .map(statusText)
                        .join(' · '),
                  ),
                  const SizedBox(height: 12),
                  Text(statusText(proposal['status'])),
                  Text('${dateText(proposal['expiresAt'])}까지'),
                ],
              ),
            ),
            if (proposal['status'] == 'PENDING') ...[
              if (received)
                SubmitButton(
                  '제안 수락하기',
                  onPressed: () async {
                    final dogs = await selectDogs(context, api);
                    if (dogs == null) return;
                    final result = object(
                      await api.call(
                        '/proposals/$id/accept',
                        method: 'POST',
                        data: {'dogIds': dogs},
                      ),
                    );
                    reload();
                    if (context.mounted && result['roomId'] != null) {
                      openScreen(
                        context,
                        ChatScreen(api, label(result['roomId'])),
                      );
                    }
                  },
                ),
              const SizedBox(height: 10),
              SubmitButton(
                received ? '거절하기' : '제안 취소',
                onPressed: () async {
                  await api.call(
                    '/proposals/$id/${received ? 'decline' : 'cancel'}',
                    method: 'POST',
                  );
                  reload();
                },
              ),
            ],
            if (proposal['roomId'] != null)
              DsButton(
                label: '대화 시작하기',
                onPressed: () => openScreen(
                  context,
                  ChatScreen(api, label(proposal['roomId'])),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class FriendsScreen extends StatelessWidget {
  final Api api;
  const FriendsScreen(this.api, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppTopBar(
      title: const Text('함께하는 친구'),
      actions: [
        IconButton(
          icon: const Icon(Icons.person_add_outlined),
          onPressed: () => openScreen(
            context,
            CollectionScreen(
              api: api,
              title: '친구 요청',
              path: '/friend-requests',
              row: (row, reload) => Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row['senderId'] == api.userId ? '보낸 친구 요청' : '받은 친구 요청',
                    ),
                    Text(statusText(row['status'])),
                    if (row['status'] == 'PENDING')
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final a
                              in row['senderId'] == api.userId
                                  ? ['cancel']
                                  : ['accept', 'reject'])
                            DsButton(
                              label: {
                                'cancel': '취소',
                                'accept': '수락',
                                'reject': '거절',
                              }[a]!,
                              onPressed: () => action(context, () async {
                                await api.call(
                                  '/friend-requests/${row['id']}/$a',
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
        ),
      ],
    ),
    body: AsyncView(
      load: () => api.call('/friends'),
      builder: (data, reload) => PageBody(
        children: [
          if (items(data).isEmpty)
            const Empty('아직 연결된 친구가 없어요.', '친구 찾기에서 마음에 맞는 친구에게 다가가보세요.'),
          for (final friend in items(data))
            Panel(
              child: ListTile(
                title: Text(label(friend['displayName'])),
                leading: const Icon(Icons.pets),
                trailing: DsButton(
                  label: '친구 해제',
                  onPressed: () => action(context, () async {
                    if (!await confirm(context, '친구 해제', '친구 연결을 해제할까요?')) {
                      return;
                    }
                    await api.call(
                      '/friends/${friend['userId']}',
                      method: 'DELETE',
                    );
                    reload();
                  }),
                  variant: DsButtonVariant.ghost,
                  size: DsButtonSize.compact,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
