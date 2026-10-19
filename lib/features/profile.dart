import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../ui/design_system/gallery.dart';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../core/api.dart';
import '../core/uploads.dart';
import '../ui/shared.dart';
import '../ui/collection.dart';
import 'social.dart';
import 'community.dart';
import 'readiness.dart';

class ProfileScreen extends StatelessWidget {
  final Api api;
  const ProfileScreen(this.api, {super.key});
  @override
  Widget build(BuildContext context) => AsyncView(
    load: () => api.call('/me'),
    builder: (data, reload) {
      final me = object(data), profile = object(me['profile']);
      return PageBody(
        children: [
          Panel(
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: groupedBackground,
                  child: Icon(
                    Icons.person_rounded,
                    color: secondaryLabel,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guardianNameText(profile['displayName']),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${profile['maxWalkMinutes']}분의 즐거운 산책',
                        style: const TextStyle(
                          color: secondaryLabel,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '보호자 정보 수정',
                  onPressed: () =>
                      openScreen(context, OwnerEditor(api, profile)),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ),
          const Section('우리 집 강아지'),
          for (final dog in records(me['dogs']))
            Panel(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const FeatureIcon(
                  Icons.pets_rounded,
                  color: Color(0xFF8B775C),
                  background: Color(0xFFF5F1E9),
                ),
                title: Text(label(dog['name'])),
                subtitle: Text(
                  '${dog['breed']} · ${statusText(dog['reviewStatus'])}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    openScreen(context, DogScreen(api, label(dog['id']))),
              ),
            ),
          DsButton(
            onPressed: () => openScreen(context, DogEditor(api)),
            icon: Icons.add,
            label: '강아지 등록',
            variant: DsButtonVariant.secondary,
          ),
          const Section('나의 댕글'),
          Panel(
            child: GroupedRows(
              children: [
                ListTile(
                  leading: const FeatureIcon(
                    Icons.near_me_rounded,
                    color: Color(0xFF5B7559),
                    background: Color(0xFFEEF2EB),
                  ),
                  title: const Text('동네 인증'),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  subtitle: Text(
                    label(object(me['regionVerification'])['name']).isEmpty
                        ? '현재 위치로 활동 동네를 인증해주세요.'
                        : label(object(me['regionVerification'])['name']),
                  ),
                  onTap: () => openScreen(context, RegionScreen(api)),
                ),
                ListTile(
                  leading: const FeatureIcon(Icons.fact_check_rounded),
                  title: const Text('산책 준비 상태'),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () =>
                      openScreen(context, ActivityReadinessScreen(api)),
                ),
                ListTile(
                  leading: const FeatureIcon(Icons.people_rounded),
                  title: const Text('친구와 요청'),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () => openScreen(context, FriendsScreen(api)),
                ),
                ListTile(
                  leading: const FeatureIcon(Icons.event_rounded),
                  title: const Text('나의 모임'),
                  subtitle: const Text('참여 일정과 신청 내역'),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () => openScreen(context, MyMeetupsScreen(api)),
                ),
                ListTile(
                  leading: const FeatureIcon(
                    Icons.mail_rounded,
                    color: Color(0xFF8B775C),
                    background: Color(0xFFF5F1E9),
                  ),
                  title: const Text('활동 제안함'),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () => openScreen(context, ProposalsScreen(api)),
                ),
                ListTile(
                  leading: const FeatureIcon(Icons.group_add_rounded),
                  title: const Text('가족 초대 수락'),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () => action(context, () async {
                    final token = await askText(context, '받은 가족 초대 코드');
                    if (token == null) return;
                    await api.call(
                      '/dog-invitations/${Uri.encodeComponent(token)}/accept',
                      method: 'POST',
                    );
                    reload();
                    if (context.mounted) toast(context, '가족으로 연결했어요.');
                  }),
                ),
                ListTile(
                  leading: const FeatureIcon(
                    Icons.settings_rounded,
                    color: secondaryLabel,
                    background: groupedBackground,
                  ),
                  title: const Text('설정 및 계정'),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () => openScreen(context, SettingsScreen(api)),
                ),
              ],
            ),
          ),
          DsButton(
            label: '정보 새로고침',
            onPressed: reload,
            variant: DsButtonVariant.ghost,
            size: DsButtonSize.compact,
          ),
        ],
      );
    },
  );
}

class OwnerEditor extends StatefulWidget {
  final Api api;
  final Json profile;
  const OwnerEditor(this.api, this.profile, {super.key});
  @override
  State<OwnerEditor> createState() => _OwnerEditorState();
}

class _OwnerEditorState extends State<OwnerEditor> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(
    text: label(widget.profile['displayName']) == '새로운 견주'
        ? ''
        : label(widget.profile['displayName']),
  );
  late final minutes = TextEditingController(
    text: label(widget.profile['maxWalkMinutes']),
  );
  late final traits = TextEditingController(
    text: (widget.profile['traits'] as List? ?? []).join(', '),
  );
  late final days = Set<int>.from(widget.profile['walkDays'] as List? ?? []);
  late final periods = Set<String>.from(
    widget.profile['walkPeriods'] as List? ?? [],
  );
  String? photo;
  @override
  void dispose() {
    name.dispose();
    minutes.dispose();
    traits.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppTopBar(title: const Text('보호자 정보')),
    body: Form(
      key: form,
      child: PageBody(
        children: [
          const PageIntro('보호자님의 정보를 입력해주세요', '이웃에게 보여줄 닉네임과 산책 취향을 알려주세요.'),
          Input(name, '닉네임', hint: '동네에서 사용할 이름'),
          TraitPicker(
            traits,
            choices: const [
              '느긋해요',
              '활동적이에요',
              '낯을 가려요',
              '친구를 좋아해요',
              '조용한 산책이 좋아요',
            ],
          ),
          DsField(
            label: '주로 산책하는 날',
            child: DsWeekdayPicker(
              value: days,
              onChanged: (value) => setState(() {
                days
                  ..clear()
                  ..addAll(value);
              }),
            ),
          ),
          DsField(
            label: '좋아하는 산책 시간',
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final p in [
                  'DAWN',
                  'MORNING',
                  'AFTERNOON',
                  'EVENING',
                  'NIGHT',
                ])
                  DsChip(
                    label: statusText(p),
                    selected: periods.contains(p),
                    onSelected: (v) => setState(() {
                      v ? periods.add(p) : periods.remove(p);
                    }),
                  ),
              ],
            ),
          ),
          Input(
            minutes,
            '한 번에 걷는 시간',
            keyboard: TextInputType.number,
            suffix: '분',
          ),
          SubmitButton(
            photo == null ? '프로필 사진 선택' : '사진 선택 완료 · 다시 선택',
            secondary: true,
            onPressed: () async {
              final id = await Uploads(widget.api).pick('PROFILE_IMAGE');
              if (mounted && id != null) setState(() => photo = id);
            },
          ),
          const SizedBox(height: 12),
          SubmitButton(
            '저장하기',
            onPressed: () async {
              if (!form.currentState!.validate()) return;
              final value = int.tryParse(minutes.text);
              if (value == null || value < 5 || value > 300) {
                throw const ApiFailure('산책 시간은 5~300분으로 입력해주세요.');
              }
              await widget.api.call(
                '/me/profile',
                method: 'PATCH',
                data: {
                  'displayName': name.text.trim(),
                  'version': widget.profile['version'],
                  'walkDays': days.toList(),
                  'walkPeriods': periods.toList(),
                  'maxWalkMinutes': value,
                  'traits': traits.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList(),
                  if (photo != null) 'photoUploadId': photo,
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

class DogEditor extends StatefulWidget {
  final Api api;
  final Json? dog;
  const DogEditor(this.api, {super.key, this.dog});
  @override
  State<DogEditor> createState() => _DogEditorState();
}

class _DogEditorState extends State<DogEditor> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: label(widget.dog?['name']));
  late final breed = TextEditingController(text: label(widget.dog?['breed']));
  late final birth = TextEditingController(
    text: label(widget.dog?['birthDate']),
  );
  late final traits = TextEditingController(
    text: (widget.dog?['traits'] as List? ?? []).join(', '),
  );
  late final precautions = TextEditingController(
    text: label(widget.dog?['precautions']),
  );
  late String size = widget.dog?['size'] as String? ?? 'SMALL';
  late bool estimated = widget.dog?['birthIsEstimated'] == true;
  late List<String> photos = records(widget.dog?['photos'])
      .map((p) => label(p['uploadId']))
      .toList();
  bool photoChanged = false;
  bool restored = false;
  int draftVersion = 0;
  @override
  void initState() {
    super.initState();
    if (widget.dog == null) restoreDraft();
  }

  Future<void> restoreDraft() async {
    try {
      final draft = object(await widget.api.call('/me/onboarding-draft'));
      draftVersion = (draft['version'] as num?)?.toInt() ?? 0;
      final dog = object(object(draft['payload'])['dog']);
      if (!mounted || dog.isEmpty) return;
      // Do not overwrite edits made while the request was pending.
      if ([
        name,
        breed,
        birth,
        traits,
        precautions,
      ].any((c) => c.text.isNotEmpty)) {
        return;
      }
      setState(() {
        name.text = label(dog['name']);
        breed.text = label(dog['breed']);
        birth.text = label(dog['birthDate']);
        traits.text = (dog['traits'] as List? ?? []).join(', ');
        precautions.text = label(dog['precautions']);
        size = dog['size'] as String? ?? 'SMALL';
        estimated = dog['birthIsEstimated'] == true;
        photos = List<String>.from(dog['photoUploadIds'] as List? ?? []);
        restored = true;
      });
    } catch (_) {
      /* Explicit draft save reports errors; registration remains usable. */
    }
  }

  Json payload() => {
    'name': name.text.trim(),
    'breed': breed.text.trim(),
    'birthDate': birth.text.trim().isEmpty ? null : birth.text.trim(),
    'birthIsEstimated': estimated,
    'size': size,
    'traits': traits.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(),
    'precautions': precautions.text.trim(),
    'photoUploadIds': photos,
  };
  @override
  void dispose() {
    for (final c in [name, breed, birth, traits, precautions]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppTopBar(title: Text(widget.dog == null ? '강아지 등록' : '강아지 정보 수정')),
    body: Form(
      key: form,
      child: PageBody(
        children: [
          if (restored)
            const Panel(
              color: tintBackground,
              child: Text('저장해둔 작성 내용을 불러왔어요.'),
            ),
          Input(name, '강아지 이름', hint: '예: 두부'),
          Input(breed, '견종', hint: '예: 말티즈, 믹스견'),
          BirthdayField(birth, title: '강아지 생일', optional: true),
          DsSwitch(
            label: '추정 생일이에요',
            value: estimated,
            onChanged: (v) => setState(() => estimated = v),
          ),
          DsSelectField<String>(
            initialValue: size,
            label: '몸집',
            items: [
              for (final s in ['SMALL', 'MEDIUM', 'LARGE'])
                DropdownMenuItem(value: s, child: Text(statusText(s))),
            ],
            onChanged: (v) => size = v!,
          ),
          const SizedBox(height: 14),
          TraitPicker(
            traits,
            choices: const [
              '사교적이에요',
              '활발해요',
              '차분해요',
              '겁이 많아요',
              '호기심이 많아요',
              '천천히 친해져요',
            ],
          ),
          DsTextField(
            label: '미리 알아두면 좋아요',
            optional: true,
            controller: precautions,
            keyboardType: TextInputType.multiline,
            minLines: 1,
            maxLines: inputMaxLines(context, 3),
            scrollPadding: const EdgeInsets.all(32),
            decoration: const InputDecoration(
              hintText: '예: 큰 강아지를 만나면 조금 긴장해요',
            ),
          ),
          const SizedBox(height: 16),
          SubmitButton(
            photos.isEmpty ? '강아지 사진 선택' : '사진 ${photos.length}장 선택됨',
            secondary: true,
            onPressed: () async {
              if (photos.length >= 10) {
                throw const ApiFailure('사진은 최대 10장까지 등록할 수 있어요.');
              }
              final id = await Uploads(widget.api).pick('PROFILE_IMAGE');
              if (mounted && id != null) {
                setState(() {
                  photos.add(id);
                  photoChanged = true;
                });
              }
            },
          ),
          const SizedBox(height: 12),
          if (widget.dog == null) ...[
            SubmitButton(
              '작성 내용 임시 저장',
              secondary: true,
              onPressed: () async {
                final result = object(
                  await widget.api.call(
                    '/me/onboarding-draft',
                    method: 'PUT',
                    data: {
                      'stage': 'DOG',
                      'version': draftVersion,
                      'payload': {'dog': payload()},
                    },
                  ),
                );
                draftVersion = (result['version'] as num).toInt();
                if (context.mounted) toast(context, '작성 내용을 저장했어요.');
              },
            ),
            const SizedBox(height: 12),
          ],
          SubmitButton(
            '저장하기',
            onPressed: () async {
              if (!form.currentState!.validate()) return;
              final body = payload();
              if (widget.dog != null && !photoChanged) {
                body.remove('photoUploadIds');
              }
              final result = object(
                await widget.api.call(
                  widget.dog == null ? '/dogs' : '/dogs/${widget.dog!['id']}',
                  method: widget.dog == null ? 'POST' : 'PATCH',
                  data: {
                    ...body,
                    if (widget.dog != null) 'version': widget.dog!['version'],
                  },
                ),
              );
              if (widget.dog == null) {
                try {
                  await widget.api.call(
                    '/me/onboarding-draft',
                    method: 'DELETE',
                  );
                } catch (_) {
                  /* Dog already saved. */
                }
              }
              if (context.mounted) {
                if (widget.dog == null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          DogScreen(widget.api, label(result['id'])),
                    ),
                  );
                } else {
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
    ),
  );
}

class DogScreen extends StatelessWidget {
  final Api api;
  final String id;
  const DogScreen(this.api, this.id, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppTopBar(title: const Text('강아지 프로필')),
    body: AsyncView(
      load: () => api.call('/dogs/$id'),
      builder: (value, reload) {
        final dog = object(value);
        return PageBody(
          children: [
            Panel(
              color: tintBackground,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.pets, size: 52, color: tint),
                  const SizedBox(height: 16),
                  Text(
                    label(dog['name']),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text('${dog['breed']} · ${statusText(dog['size'])}'),
                  const SizedBox(height: 10),
                  Text((dog['traits'] as List? ?? []).join(' · ')),
                  Text(label(dog['precautions'])),
                ],
              ),
            ),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('서류 심사: ${statusText(dog['reviewStatus'])}'),
                  Text('현재 효력: ${statusText(dog['effectiveDecision'])}'),
                  if (dog['approvalExpiresAt'] != null)
                    Text('유효기간: ${dateText(dog['approvalExpiresAt'])}'),
                  const SizedBox(height: 12),
                  const Text('최종 활동 자격은 동네 인증과 계정 상태를 함께 확인해 서버가 판단합니다.'),
                ],
              ),
            ),
            DsButton(
              label: '건강 서류 제출 · 심사 내역',
              onPressed: () => openScreen(context, HealthScreen(api, id)),
            ),
            DsButton(
              label: '우리 강아지 성격 알아보기',
              onPressed: () => openScreen(context, PersonalityScreen(api, id)),
              variant: DsButtonVariant.secondary,
            ),
            DsButton(
              label: '프로필 수정',
              onPressed: () => openScreen(context, DogEditor(api, dog: dog)),
              variant: DsButtonVariant.secondary,
            ),
            DsButton(
              label: '가족 관리',
              onPressed: () => openScreen(context, FamilyScreen(api, id)),
              variant: DsButtonVariant.secondary,
            ),
            DsButton(
              label: '새로고침',
              onPressed: reload,
              variant: DsButtonVariant.ghost,
              size: DsButtonSize.compact,
            ),
            if (dog['role'] == 'OWNER')
              DsButton(
                label: '강아지 등록 보관',
                onPressed: () => action(context, () async {
                  if (!await confirm(
                    context,
                    '강아지 등록 보관',
                    '이 강아지의 교류 활동과 추천이 중단됩니다. 보관할까요?',
                  )) {
                    return;
                  }
                  await api.call('/dogs/$id/archive', method: 'POST');
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

class HealthScreen extends StatefulWidget {
  final Api api;
  final String dogId;
  const HealthScreen(this.api, this.dogId, {super.key});
  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  final uploadIds = <String>[];
  final note = TextEditingController();
  int revision = 0;
  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppTopBar(title: const Text('건강 서류와 심사')),
    body: AsyncView(
      key: ValueKey(revision),
      load: () => widget.api.call('/dogs/${widget.dogId}/health-review'),
      builder: (data, reload) => PageBody(
        children: [
          Panel(
            color: tintBackground,
            child: Text(
              '심사: ${statusText(object(data)['reviewStatus'])}\n현재 효력: ${statusText(object(data)['effectiveDecision'])}',
            ),
          ),
          const Text('예방접종 등 확인할 서류를 제출해주세요. 원본은 공개 프로필에 표시되지 않습니다.'),
          const SizedBox(height: 14),
          SubmitButton(
            '서류 선택 · 검사 (${uploadIds.length}/10)',
            secondary: true,
            onPressed: () async {
              if (uploadIds.length >= 10) {
                throw const ApiFailure('한 번에 최대 10개까지 제출할 수 있어요.');
              }
              final id = await Uploads(widget.api)
                  .pick('HEALTH_DOCUMENT', resourceId: widget.dogId);
              if (mounted && id != null) setState(() => uploadIds.add(id));
            },
          ),
          for (final id in uploadIds)
            ListTile(
              title: const Text('검사 완료된 서류'),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => uploadIds.remove(id)),
              ),
            ),
          const SizedBox(height: 12),
          DsTextField(
            controller: note,
            keyboardType: TextInputType.multiline,
            minLines: 1,
            maxLines: inputMaxLines(context, 3),
            scrollPadding: const EdgeInsets.all(32),
            label: '심사자에게 전달할 내용 (선택)',
          ),
          const SizedBox(height: 12),
          SubmitButton(
            '심사 요청',
            onPressed: () async {
              if (uploadIds.isEmpty) throw const ApiFailure('먼저 서류를 선택해주세요.');
              await widget.api.call(
                '/dogs/${widget.dogId}/health-submissions',
                method: 'POST',
                data: {
                  'uploadIds': List.of(uploadIds),
                  'note': note.text.trim(),
                },
              );
              if (mounted) {
                setState(() {
                  uploadIds.clear();
                  note.clear();
                  revision++;
                });
              }
            },
          ),
          const Section('제출 내역'),
          for (final submission in records(object(data)['submissions']))
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${statusText(submission['status'])} · ${dateText(submission['submittedAt'])}',
                  ),
                  Text(label(submission['note'])),
                  for (final decision in records(submission['decisions']))
                    Text(
                      '${statusText(decision['decision'])}: ${decision['reason']}',
                    ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class RegionScreen extends StatelessWidget {
  final Api api;
  const RegionScreen(this.api, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppTopBar(title: const Text('우리 동네 인증')),
    body: AsyncView(
      load: () => api.call('/me/region-verification'),
      builder: (value, reload) => PageBody(
        children: [
          const Panel(
            color: tintBackground,
            child: Column(
              children: [
                Icon(Icons.near_me_outlined, size: 70, color: tint),
                SizedBox(height: 16),
                Text(
                  '가까운 곳에서 시작하는 우정',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 10),
                Text(
                  '현재 위치로 활동 동네를 확인해요. 정확한 좌표는 다른 사용자에게 표시하지 않아요.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (value != null)
            Panel(
              child: Text(
                '${object(value)['name']}\n만료: ${dateText(object(value)['expiresAt'])}',
              ),
            ),
          SubmitButton(
            '현재 위치로 인증하기',
            onPressed: () async {
              if (!await Geolocator.isLocationServiceEnabled()) {
                throw const ApiFailure('기기의 위치 서비스를 켜주세요.');
              }
              var permission = await Geolocator.checkPermission();
              if (permission == LocationPermission.denied) {
                permission = await Geolocator.requestPermission();
              }
              if (permission == LocationPermission.deniedForever) {
                throw const ApiFailure('기기 설정에서 댕글의 위치 권한을 허용해주세요.');
              }
              if (permission == LocationPermission.denied) {
                throw const ApiFailure('동네 인증에는 위치 권한이 필요해요.');
              }
              final location = await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.high,
                  timeLimit: Duration(seconds: 25),
                ),
              );
              await api.call(
                '/region-verifications',
                method: 'POST',
                data: {
                  'latitude': location.latitude,
                  'longitude': location.longitude,
                  'accuracy': location.accuracy,
                  'measuredAt': location.timestamp.toUtc().toIso8601String(),
                },
              );
              reload();
              if (context.mounted) toast(context, '동네 인증을 완료했어요.');
            },
          ),
          DsButton(
            label: '위치 권한 설정 열기',
            onPressed: Geolocator.openAppSettings,
            variant: DsButtonVariant.ghost,
            size: DsButtonSize.compact,
          ),
        ],
      ),
    ),
  );
}

class PersonalityScreen extends StatefulWidget {
  final Api api;
  final String dogId;
  const PersonalityScreen(this.api, this.dogId, {super.key});
  @override
  State<PersonalityScreen> createState() => _PersonalityScreenState();
}

class _PersonalityScreenState extends State<PersonalityScreen> {
  final answers = <String, int>{};
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppTopBar(title: const Text('우리 강아지 성격')),
    body: AsyncView(
      load: () => widget.api.call('/personality-tests/current'),
      builder: (data, reload) {
        final test = object(data), questions = records(test['questions']);
        return PageBody(
          children: [
            Text(label(test['name'])),
            const Text('평소 행동을 떠올려 답해주세요. 건강이나 안전을 판정하는 검사가 아닙니다.'),
            for (final q in questions)
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label(q['text']),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    for (var i = 0; i < (q['choices'] as List).length; i++)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          answers[q['id']] == i
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: tint,
                        ),
                        title: Text(label(q['choices'][i])),
                        onTap: () =>
                            setState(() => answers[label(q['id'])] = i),
                      ),
                  ],
                ),
              ),
            SubmitButton(
              '결과 보기',
              onPressed: () async {
                if (questions.any((q) => !answers.containsKey(q['id']))) {
                  throw const ApiFailure('모든 문항에 답해주세요.');
                }
                final result = object(
                  await widget.api.call(
                    '/dogs/${widget.dogId}/personality-results',
                    method: 'POST',
                    data: {
                      'testVersionId': test['id'],
                      'answers': [
                        for (final q in questions)
                          {'questionId': q['id'], 'value': answers[q['id']]},
                      ],
                    },
                  ),
                );
                if (context.mounted) {
                  await showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('${result['code']} · ${result['nickname']}'),
                      content: Text(label(result['description'])),
                      actions: [
                        DsButton(
                          label: '확인',
                          onPressed: () => Navigator.pop(context),
                          variant: DsButtonVariant.ghost,
                          size: DsButtonSize.compact,
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    ),
  );
}

class FamilyScreen extends StatelessWidget {
  final Api api;
  final String dogId;
  const FamilyScreen(this.api, this.dogId, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppTopBar(title: const Text('함께 돌보는 가족')),
    body: AsyncView(
      load: () => api.call('/dogs/$dogId/members'),
      builder: (data, reload) => PageBody(
        children: [
          for (final member in items(data))
            Panel(
              child: Column(
                children: [
                  ListTile(
                    title: Text(label(member['displayName'])),
                    subtitle: Text(member['role'] == 'OWNER' ? '대표 관리자' : '가족'),
                  ),
                  if (member['role'] != 'OWNER')
                    Wrap(
                      children: [
                        DsButton(
                          label: '대표 이전',
                          onPressed: () => action(context, () async {
                            if (!await confirm(
                              context,
                              '대표 관리자 이전',
                              '이 가족에게 강아지의 대표 관리 권한을 이전할까요?',
                            )) {
                              return;
                            }
                            await api.call(
                              '/dogs/$dogId/transfer-ownership',
                              method: 'POST',
                              data: {'userId': member['userId']},
                            );
                            reload();
                          }),
                          variant: DsButtonVariant.ghost,
                          size: DsButtonSize.compact,
                        ),
                        DsButton(
                          label: '연결 해제',
                          onPressed: () => action(context, () async {
                            if (!await confirm(
                              context,
                              '가족 연결 해제',
                              '이 가족의 관리 권한을 해제할까요?',
                            )) {
                              return;
                            }
                            await api.call(
                              '/dogs/$dogId/members/${member['userId']}',
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
          SubmitButton(
            '가족 초대 코드 만들기',
            onPressed: () async {
              final invite = object(
                await api.call(
                  '/dogs/$dogId/invitations',
                  method: 'POST',
                  data: {'role': 'EDITOR'},
                ),
              );
              if (context.mounted) {
                await showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('가족 초대 코드'),
                    content: SelectableText(
                      '${invite['token']}\n\n만료: ${dateText(invite['expiresAt'])}\n가족은 마이 → 가족 초대 수락에서 입력해주세요.',
                    ),
                    actions: [
                      DsButton(
                        label: '초대 취소',
                        onPressed: () => action(context, () async {
                          await api.call(
                            '/dogs/$dogId/invitations/${invite['id']}',
                            method: 'DELETE',
                          );
                          if (context.mounted) Navigator.pop(context);
                        }),
                        variant: DsButtonVariant.ghost,
                        size: DsButtonSize.compact,
                      ),
                      DsButton(
                        label: '복사',
                        onPressed: () => Clipboard.setData(
                          ClipboardData(text: label(invite['token'])),
                        ),
                        variant: DsButtonVariant.ghost,
                        size: DsButtonSize.compact,
                      ),
                      DsButton(
                        label: '닫기',
                        onPressed: () => Navigator.pop(context),
                        variant: DsButtonVariant.ghost,
                        size: DsButtonSize.compact,
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
    ),
  );
}

class SettingsScreen extends StatelessWidget {
  final Api api;
  const SettingsScreen(this.api, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppTopBar(title: const Text('설정 및 계정')),
    body: AsyncView(
      load: () => api.call('/me/profile'),
      builder: (data, reload) {
        final profile = object(data),
            privacy = object(profile['privacy']),
            notifications = object(profile['notificationSettings']);
        return PageBody(
          children: [
            if (kDebugMode)
              ListTile(
                title: const Text('디자인 시스템'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => openScreen(context, const DesignSystemGallery()),
              ),
            const Section('프로필 공개'),
            Panel(
              child: GroupedRows(
                children: [
                  for (final entry in {
                    'showPhoto': '보호자 사진 공개',
                    'showAgeBand': '나이대 공개',
                    'showGender': '성별 공개',
                    'discoverable': '친구 찾기에 표시',
                  }.entries)
                    DsSwitch(
                      label: entry.value,
                      value: privacy[entry.key] == true,
                      onChanged: (v) => action(context, () async {
                        await api.call(
                          '/me/privacy-settings',
                          method: 'PATCH',
                          data: {entry.key: v},
                        );
                        reload();
                      }),
                    ),
                ],
              ),
            ),
            const Section('알림 설정'),
            Panel(
              child: GroupedRows(
                children: [
                  for (final entry in {
                    'proposals': '활동 제안',
                    'friends': '친구 요청',
                    'messages': '새 메시지',
                    'meetups': '모임',
                    'reviews': '심사 결과',
                    'marketing': '마케팅',
                  }.entries)
                    DsSwitch(
                      label: entry.value,
                      value: notifications[entry.key] == true,
                      onChanged: (v) => action(context, () async {
                        await api.call(
                          '/me/notification-settings',
                          method: 'PATCH',
                          data: {entry.key: v},
                        );
                        reload();
                      }),
                    ),
                ],
              ),
            ),
            ListTile(
              title: const Text('차단한 사용자'),
              onTap: () => openScreen(
                context,
                CollectionScreen(
                  api: api,
                  title: '차단 관리',
                  path: '/blocks',
                  row: (row, reload) => Panel(
                    child: ListTile(
                      title: Text(
                        label(row['displayName']).isEmpty
                            ? '차단한 사용자'
                            : label(row['displayName']),
                      ),
                      trailing: DsButton(
                        label: '해제',
                        onPressed: () => action(context, () async {
                          await api.call(
                            '/blocks/${row['userId'] ?? row['targetId']}',
                            method: 'DELETE',
                          );
                          reload();
                        }),
                        variant: DsButtonVariant.ghost,
                        size: DsButtonSize.compact,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ListTile(
              title: const Text('신고 내역'),
              onTap: () => openScreen(
                context,
                CollectionScreen(
                  api: api,
                  title: '신고 내역',
                  path: '/reports/me',
                  row: (row, _) => Panel(
                    child: Text(
                      '${row['reason']} · ${statusText(row['status'])}',
                    ),
                  ),
                ),
              ),
            ),
            ListTile(
              title: const Text('제재 및 이의제기'),
              onTap: () => openScreen(
                context,
                CollectionScreen(
                  api: api,
                  title: '제재 내역',
                  path: '/me/sanctions',
                  row: (row, reload) => Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label(row['reason'])),
                        Text('종료: ${dateText(row['expiresAt'])}'),
                        DsButton(
                          label: '이의제기',
                          onPressed: () => action(context, () async {
                            final reason = await askText(context, '이의제기 사유');
                            if (reason == null) return;
                            await api.call(
                              '/appeals',
                              method: 'POST',
                              data: {'sanctionId': row['id'], 'reason': reason},
                            );
                            if (context.mounted) toast(context, '이의제기를 접수했어요.');
                          }),
                          variant: DsButtonVariant.ghost,
                          size: DsButtonSize.compact,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ListTile(
              title: const Text('현재 약관 동의'),
              onTap: () => openScreen(context, TermsScreen(api)),
            ),
            const SizedBox(height: 20),
            SubmitButton('로그아웃', secondary: true, onPressed: api.logout),
            DsButton(
              label: '회원 탈퇴',
              onPressed: () => openScreen(context, WithdrawalScreen(api)),
              variant: DsButtonVariant.ghost,
              size: DsButtonSize.compact,
            ),
          ],
        );
      },
    ),
  );
}

class TermsScreen extends StatefulWidget {
  final Api api;
  const TermsScreen(this.api, {super.key});
  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  final selected = <String>{};
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppTopBar(title: const Text('현재 약관 동의')),
    body: AsyncView(
      load: () => widget.api.call('/terms'),
      builder: (data, reload) => PageBody(
        children: [
          for (final term in items(data))
            Panel(
              child: Column(
                children: [
                  DsCheckbox(
                    label:
                        '${term['required'] == true || term['required'] == 1 ? '[필수]' : '[선택]'} ${term['title']}',
                    value: selected.contains(term['id']),
                    onChanged: (v) => setState(() {
                      v == true
                          ? selected.add(term['id'])
                          : selected.remove(term['id']);
                    }),
                  ),
                  ExpansionTile(
                    title: const Text('약관 보기'),
                    children: [Text(label(term['content']))],
                  ),
                ],
              ),
            ),
          SubmitButton(
            '선택한 약관 동의 저장',
            onPressed: () async {
              await widget.api.call(
                '/me/consents',
                method: 'POST',
                data: {'consentVersionIds': selected.toList()},
              );
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}

class WithdrawalScreen extends StatelessWidget {
  final Api api;
  const WithdrawalScreen(this.api, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppTopBar(title: const Text('회원 탈퇴')),
    body: AsyncView(
      load: () => api.call('/me/withdrawal-preview'),
      builder: (data, reload) {
        final preview = object(data);
        return PageBody(
          children: [
            const Section('떠나시기 전에 확인해주세요'),
            const Text(
              '탈퇴하면 세션이 종료되고 계정 정리가 시작됩니다. 대표 관리 중인 강아지·채널·모임이 있으면 먼저 이전하거나 정리해주세요.',
            ),
            const SizedBox(height: 16),
            Text('데이터 정리 유예: ${preview['deleteAfterDays']}일'),
            for (final entry in preview.entries.where(
              (e) => e.value is List && (e.value as List).isNotEmpty,
            ))
              Panel(
                child: Text(
                  '${entry.key}: ${(entry.value as List).length}건 정리가 필요해요.',
                ),
              ),
            if (preview['canWithdraw'] == true)
              SubmitButton(
                '탈퇴 신청',
                onPressed: () async {
                  final text = await askText(context, '확인하려면 “탈퇴합니다”를 입력해주세요.');
                  if (text != '탈퇴합니다') return;
                  await api.call(
                    '/me/withdrawal',
                    method: 'POST',
                    data: {'confirmation': text},
                  );
                  await api.forget();
                },
              ),
          ],
        );
      },
    ),
  );
}
