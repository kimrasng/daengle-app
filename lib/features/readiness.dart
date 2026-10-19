import 'package:flutter/material.dart';

import '../core/api.dart';
import '../ui/shared.dart';
import 'profile.dart';

String readinessReason(String code) => switch (code) {
  'REGION_VERIFICATION_REQUIRED' => '동네를 인증하면 가까운 친구와 만날 수 있어요.',
  'DOG_REVIEW_REQUIRED' => '강아지 건강 심사가 완료되면 산책을 제안할 수 있어요.',
  'TERMS_RECONSENT_REQUIRED' => '변경된 필수 약관을 확인해주세요.',
  'ACCOUNT_SUSPENDED' || 'ACCOUNT_UNAVAILABLE' => '설정에서 계정 이용 상태를 확인해주세요.',
  _ => '강아지 등록과 동네 인증, 건강 심사 상태를 확인해주세요.',
};

Widget? activityRecovery(BuildContext context, Api api, Object error) {
  if (error is! ApiFailure) return null;
  final (title, button, icon, destination) = switch (error.code) {
    'REGION_VERIFICATION_REQUIRED' => (
      '우리 동네부터 알려주세요',
      '동네 인증하기',
      Icons.near_me_rounded,
      RegionScreen(api),
    ),
    'DOG_REVIEW_REQUIRED' => (
      '함께 걷기 전, 준비가 필요해요',
      '산책 준비 확인하기',
      Icons.verified_user_rounded,
      ActivityReadinessScreen(api),
    ),
    'TERMS_RECONSENT_REQUIRED' => (
      '새로운 약관을 확인해주세요',
      '약관 확인하기',
      Icons.article_rounded,
      TermsScreen(api),
    ),
    'ACCOUNT_SUSPENDED' || 'ACCOUNT_UNAVAILABLE' => (
      '계정 이용 상태를 확인해주세요',
      '계정 상태 확인하기',
      Icons.info_rounded,
      SettingsScreen(api),
    ),
    _ => ('', '', Icons.info_rounded, const SizedBox()),
  };
  if (button.isEmpty) return null;
  return Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Empty(title, readinessReason(error.code), icon: icon),
        DsButton(
          label: button,
          onPressed: () => openScreen(context, destination),
        ),
      ],
    ),
  );
}

class ActivityReadinessScreen extends StatelessWidget {
  final Api api;
  const ActivityReadinessScreen(this.api, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const AppTopBar(title: Text('산책 준비')),
    body: AsyncView(
      load: () => Future.wait([api.call('/me'), api.call('/me/capabilities')]),
      builder: (data, _) {
        final me = object((data as List)[0]), capabilities = object(data[1]);
        final onboarding = object(me['onboarding']), dogs = records(me['dogs']);
        final ready = capabilities['canPropose'] == true;
        Widget step(
          IconData icon,
          String title,
          String subtitle,
          bool done,
          Widget destination,
        ) => ListTile(
          leading: FeatureIcon(
            icon,
            color: done ? const Color(0xFF5B7559) : tint,
            background: done ? const Color(0xFFEEF2EB) : tintBackground,
          ),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: Icon(
            done ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
            color: done ? const Color(0xFF5B7559) : secondaryLabel,
            size: 21,
          ),
          onTap: () => openScreen(context, destination),
        );
        return PageBody(
          children: [
            PageIntro(
              ready ? '이제 함께 걸을\n준비가 됐어요' : '반가운 만남을 위한\n작은 준비',
              ready
                  ? '친구 찾기에서 잘 맞는 산책 친구를 만나보세요.'
                  : readinessReason(label(capabilities['reason'])),
            ),
            Panel(
              child: GroupedRows(
                children: [
                  step(
                    Icons.person_rounded,
                    '보호자 정보',
                    '나의 산책 취향을 알려주세요.',
                    onboarding['profile'] == true,
                    OwnerEditor(api, object(me['profile'])),
                  ),
                  step(
                    Icons.pets_rounded,
                    '우리 강아지 등록',
                    dogs.isEmpty
                        ? '이름과 성향으로 우리 아이를 소개해요.'
                        : '${dogs.length}마리의 강아지가 등록되어 있어요.',
                    dogs.isNotEmpty,
                    dogs.isEmpty
                        ? DogEditor(api)
                        : DogScreen(api, label(dogs.first['id'])),
                  ),
                  step(
                    Icons.near_me_rounded,
                    '활동 동네 인증',
                    onboarding['region'] == true
                        ? '현재 활동 동네가 인증되어 있어요.'
                        : '현재 위치로 활동할 동네를 인증해요.',
                    onboarding['region'] == true,
                    RegionScreen(api),
                  ),
                ],
              ),
            ),
            const Section('강아지 건강 심사'),
            if (dogs.isEmpty)
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '강아지를 등록한 뒤 건강 서류를 제출할 수 있어요.',
                      style: TextStyle(color: secondaryLabel),
                    ),
                    const SizedBox(height: 14),
                    DsButton(
                      label: '강아지 등록하기',
                      onPressed: () => openScreen(context, DogEditor(api)),
                    ),
                  ],
                ),
              ),
            for (final dog in dogs)
              Panel(
                child: step(
                  Icons.verified_user_rounded,
                  label(dog['name']),
                  '심사: ${statusText(dog['reviewStatus'])} · 현재 효력: ${statusText(dog['effectiveDecision'])}',
                  dog['canParticipate'] == true,
                  DogScreen(api, label(dog['id'])),
                ),
              ),
            if (records(me['requiredTerms']).isNotEmpty) ...[
              const Section('확인할 약관'),
              Panel(
                child: step(
                  Icons.article_rounded,
                  '변경된 필수 약관',
                  '${records(me['requiredTerms']).length}개의 동의가 필요해요.',
                  false,
                  TermsScreen(api),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              '건강 심사는 제출 서류의 확인 절차예요. 실제 만남 전에는 서로의 반려견 상태와 산책 조건을 직접 확인해주세요.',
              style: TextStyle(
                fontSize: 13,
                color: secondaryLabel,
                height: 1.6,
              ),
            ),
          ],
        );
      },
    ),
  );
}
