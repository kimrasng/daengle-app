import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../core/api.dart';
import '../core/chat_sync.dart';
import '../core/uploads.dart';
import '../ui/shared.dart';
import '../ui/collection.dart';
import 'social.dart';

class MediaPhoto extends StatefulWidget {
  final Api api;
  final String id;
  const MediaPhoto(this.api, this.id, {super.key});
  @override
  State<MediaPhoto> createState() => _MediaPhotoState();
}

class _MediaPhotoState extends State<MediaPhoto> {
  late Future<dynamic> bytes = widget.api.call(
    '/media/${widget.id}',
    responseType: ResponseType.bytes,
  );
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: FutureBuilder<dynamic>(
      future: bytes,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return DsButton(
            onPressed: () => setState(() {
              bytes = widget.api.call(
                '/media/${widget.id}',
                responseType: ResponseType.bytes,
              );
            }),
            icon: Icons.broken_image_outlined,
            label: '사진 다시 불러오기',
            variant: DsButtonVariant.ghost,
            size: DsButtonSize.compact,
          );
        }
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 90,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.memory(
            Uint8List.fromList(List<int>.from(snapshot.data as List)),
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => const Text('사진을 표시할 수 없어요.'),
          ),
        );
      },
    ),
  );
}

class RoomsScreen extends StatelessWidget {
  final Api api;
  final bool embedded;
  const RoomsScreen(this.api, {super.key, this.embedded = false});
  @override
  Widget build(BuildContext context) => CollectionScreen(
    api: api,
    title: '즐거운 대화',
    embedded: embedded,
    path: '/rooms',
    header: const PageIntro('가벼운 인사로\n산책이 시작돼요', '친구와 나눈 이야기를 한곳에서 확인해요.'),
    emptyIcon: Icons.chat_bubble_rounded,
    emptyDetail: '산책 친구와 연결되면\n여기서 편하게 이야기할 수 있어요.',
    empty: '아직 시작한 대화가 없어요.',
    row: (room, _) => Panel(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: tintBackground,
          child: Icon(Icons.chat_bubble_outline, color: tint),
        ),
        title: Text(statusText(room['type'])),
        subtitle: Text(dateText(room['updated_at'])),
        trailing:
            (num.tryParse(label(room['lastSeq'])) ?? 0) >
                (num.tryParse(label(room['lastReadSeq'])) ?? 0)
            ? const Badge(label: Text('새 대화'))
            : const Icon(Icons.chevron_right),
        onTap: () => openScreen(context, ChatScreen(api, label(room['id']))),
      ),
    ),
  );
}

class ChatScreen extends StatefulWidget {
  final Api api;
  final String roomId;
  const ChatScreen(this.api, this.roomId, {super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final text = TextEditingController();
  final scroll = ScrollController();
  MessageTimeline? timeline;
  Json? room, pending;
  List<String> attachments = [];
  Object? error;
  bool syncing = false,
      again = false,
      sending = false,
      foreground = true,
      accessLost = false;
  int readSeq = 0;
  io.Socket? socket;
  String? socketToken;
  Timer? poll;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    scroll.addListener(markRead);
    widget.api.addListener(tokenChanged);
    sync();
    poll = Timer.periodic(const Duration(seconds: 15), (_) {
      if (foreground) sync();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    if (foreground) {
      sync();
    } else {
      socket?.disconnect();
    }
  }

  void tokenChanged() {
    if (socketToken != widget.api.accessToken) connect();
  }

  void connect() {
    if (!mounted ||
        widget.api.accessToken == null ||
        !foreground ||
        accessLost) {
      return;
    }
    if (socketToken == widget.api.accessToken && socket?.connected == true) {
      return;
    }
    socket?.dispose();
    socketToken = widget.api.accessToken;
    socket = io.io(
      widget.api.origin,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNew()
          .setAuth({'accessToken': socketToken})
          .build(),
    );
    socket!.onConnect((_) {
      socket!.emitWithAck(
        'room.subscribe',
        {'roomId': widget.roomId},
        ack: (dynamic ack) {
          if (!mounted) return;
          if (object(ack)['ok'] == true) {
            sync();
          } else {
            setState(() => error = const ApiFailure('대화방 접근 권한을 다시 확인해주세요.'));
          }
        },
      );
    });
    socket!.on('message.created', (_) => sync());
    socket!.on('room.read-position.updated', (_) => sync());
    socket!.on('room.access.changed', (_) => sync());
    socket!.on('account.access.changed', (_) => sync());
    socket!.onDisconnect((_) {
      if (mounted && foreground) sync();
    });
    socket!.onConnectError((_) {
      /* REST recovery remains available when websocket is unavailable. */
    });
    socket!.connect();
  }

  Future<void> sync() async {
    if (!mounted || !foreground || accessLost) return;
    if (syncing) {
      again = true;
      return;
    }
    syncing = true;
    try {
      do {
        again = false;
        final detail = object(await widget.api.call('/rooms/${widget.roomId}'));
        if (!mounted || accessLost) return;
        room = detail;
        timeline ??= MessageTimeline(
          joinedSeq: (detail['joinedSeq'] as num).toInt(),
        );
        readSeq = (detail['lastReadSeq'] as num).toInt();
        while (true) {
          final before = timeline!.contiguous;
          final page = object(
            await widget.api.call(
              '/rooms/${widget.roomId}/messages',
              query: {'afterSeq': before, 'limit': 100},
            ),
          );
          if (!mounted || accessLost) return;
          timeline!.merge(items(page));
          if (page['hasMore'] != true) break;
          if (timeline!.contiguous == before) {
            throw const ApiFailure('대화 순번을 확인하지 못했어요. 다시 연결해주세요.');
          }
        }
      } while (again && mounted);
      if (mounted) {
        setState(() => error = null);
        connect();
        WidgetsBinding.instance.addPostFrameCallback((_) => markRead());
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e;
          if (e is ApiFailure && [401, 403, 404].contains(e.status)) {
            // A revoked room must not retain protected content on screen.
            accessLost = true;
            timeline = null;
            room = null;
            socket?.dispose();
            socket = null;
          }
        });
      }
    } finally {
      syncing = false;
    }
  }

  void markRead() {
    if (!mounted ||
        !foreground ||
        accessLost ||
        !(ModalRoute.of(context)?.isCurrent ?? false) ||
        timeline == null ||
        !scroll.hasClients ||
        scroll.offset > 80) {
      return;
    }
    final seq = timeline!.contiguous;
    if (seq <= readSeq) return;
    readSeq = seq;
    widget.api
        .call(
          '/rooms/${widget.roomId}/read-position',
          method: 'PUT',
          data: {'seq': seq},
        )
        .catchError((Object e) {
          readSeq = 0;
          return null;
        });
  }

  Future<void> send() async {
    if (sending || accessLost) return;
    if (pending == null && text.text.trim().isEmpty && attachments.isEmpty) {
      return;
    }
    pending ??= {
      'clientMessageId': uuid.v4(),
      'text': text.text.trim(),
      'uploadIds': List<String>.of(attachments),
    };
    setState(() => sending = true);
    try {
      await widget.api.call(
        '/rooms/${widget.roomId}/messages',
        method: 'POST',
        data: pending,
      );
      if (!mounted) return;
      setState(() {
        pending = null;
        text.clear();
        attachments.clear();
      });
      await sync();
    } catch (e) {
      if (mounted) toast(context, e);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  void dispose() {
    foreground = false;
    accessLost = true;
    socket?.clearListeners();
    poll?.cancel();
    widget.api.removeListener(tokenChanged);
    socket?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    text.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final members = records(room?['members']);
    final title = members
        .where((m) => m['userId'] != widget.api.userId)
        .map((m) => label(m['displayName']))
        .join(', ');
    final messages = timeline?.messages.reversed.toList() ?? [];
    return Scaffold(
      appBar: AppTopBar(
        title: Text(
          title.isEmpty ? '우리들의 대화' : title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => action(context, () async {
              if (v == 'mute' || v == 'unmute') {
                await widget.api.call(
                  '/rooms/${widget.roomId}/settings',
                  method: 'PATCH',
                  data: {'muted': v == 'mute'},
                );
                if (context.mounted) {
                  toast(context, v == 'mute' ? '알림을 껐어요.' : '알림을 켰어요.');
                }
              }
            }),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'mute', child: Text('알림 끄기')),
              PopupMenuItem(value: 'unmute', child: Text('알림 켜기')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            children: [
              if (error != null)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight * .25,
                  ),
                  child: SingleChildScrollView(
                    child: MaterialBanner(
                      content: Text('$error'),
                      actions: [
                        if (!accessLost)
                          DsButton(
                            label: '다시 연결',
                            onPressed: sync,
                            variant: DsButtonVariant.ghost,
                            size: DsButtonSize.compact,
                          )
                        else
                          DsButton(
                            label: '돌아가기',
                            onPressed: () => Navigator.pop(context),
                            variant: DsButtonVariant.ghost,
                            size: DsButtonSize.compact,
                          ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: timeline == null && error == null
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: scroll,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        reverse: true,
                        padding: const EdgeInsets.all(18),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index],
                              mine = message['senderId'] == widget.api.userId;
                          final seen = members
                              .where(
                                (m) =>
                                    m['userId'] != widget.api.userId &&
                                    (num.tryParse(label(m['lastReadSeq'])) ??
                                            0) >=
                                        (message['seq'] as num),
                              )
                              .length;
                          return Align(
                            alignment: mine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: GestureDetector(
                              onLongPress: () => action(
                                context,
                                () => report(
                                  context,
                                  widget.api,
                                  'MESSAGE',
                                  label(message['id']),
                                ),
                              ),
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.sizeOf(context).width * .78,
                                ),
                                padding: const EdgeInsets.all(14),
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: mine ? tintBackground : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!mine)
                                      Text(
                                        members
                                                .where(
                                                  (m) =>
                                                      m['userId'] ==
                                                      message['senderId'],
                                                )
                                                .map(
                                                  (m) =>
                                                      label(m['displayName']),
                                                )
                                                .firstOrNull ??
                                            '대화 참여자',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: tint,
                                        ),
                                      ),
                                    for (final photo in records(
                                      message['uploads'],
                                    ))
                                      MediaPhoto(
                                        widget.api,
                                        label(photo['id']),
                                      ),
                                    Text(
                                      message['status'] == 'VISIBLE'
                                          ? label(message['text'])
                                          : '숨김 처리된 메시지입니다.',
                                    ),
                                    Text(
                                      '${dateText(message['createdAt'])}${mine && seen > 0 ? ' · $seen명 읽음' : ''}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight * .65,
                ),
                child: SingleChildScrollView(
                  reverse: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (attachments.isNotEmpty)
                        Text('사진 ${attachments.length}장 첨부됨'),
                      if (pending != null && !sending)
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('전송을 확인하지 못했어요. 재시도하면 같은 메시지로 확인합니다.'),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed:
                                  pending != null || sending || accessLost
                                  ? null
                                  : () => action(context, () async {
                                      if (attachments.length >= 5) {
                                        throw const ApiFailure(
                                          '사진은 최대 5장까지 첨부할 수 있어요.',
                                        );
                                      }
                                      final id = await Uploads(widget.api).pick(
                                        'CHAT_IMAGE',
                                        resourceId: widget.roomId,
                                      );
                                      if (mounted && id != null) {
                                        setState(() => attachments.add(id));
                                      }
                                    }),
                              icon: const Icon(
                                Icons.add_photo_alternate_outlined,
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: text,
                                readOnly: pending != null || accessLost,
                                keyboardType: TextInputType.multiline,
                                maxLines: inputMaxLines(context, 4),
                                scrollPadding: const EdgeInsets.all(24),
                                minLines: 1,
                                maxLength: 4000,
                                decoration: const InputDecoration(
                                  hintText: '반가운 인사를 건네보세요',
                                  counterText: '',
                                ),
                              ),
                            ),
                            IconButton.filled(
                              onPressed: sending || accessLost ? null : send,
                              icon: Icon(
                                pending == null
                                    ? Icons.arrow_upward
                                    : Icons.refresh,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
