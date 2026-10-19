import 'package:flutter/material.dart';

import '../core/api.dart';
import '../ui/shared.dart';
import 'social.dart';
import 'profile.dart';
import 'chat.dart';
import 'community.dart';
import 'notifications.dart';
import 'readiness.dart';

class AppShell extends StatefulWidget {
  final Api api;
  const AppShell(this.api, {super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int tab = 0, revision = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() => revision++);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppTopBar(
      title: tab == 0
          ? const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pets_rounded, color: tint, size: 25),
                SizedBox(width: 8),
                Text('댕글'),
              ],
            )
          : Text(['댕글', '친구 찾기', '동네', '채팅', '마이'][tab]),
      actions: [
        IconButton(
          tooltip: '활동 제안함',
          onPressed: () => openScreen(context, ProposalsScreen(widget.api)),
          icon: const Icon(Icons.mail_outline),
        ),
        NotificationBell(widget.api, refreshKey: '$tab-$revision'),
      ],
    ),
    body: KeyedSubtree(
      key: ValueKey('$tab-$revision'),
      child: switch (tab) {
        0 => HomeScreen(widget.api),
        1 => DiscoveryScreen(widget.api, embedded: true),
        2 => NeighborhoodScreen(widget.api),
        3 => RoomsScreen(widget.api, embedded: true),
        _ => ProfileScreen(widget.api),
      },
    ),
    bottomNavigationBar: DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: separator, width: .5)),
      ),
      child: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets),
            label: '친구 찾기',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: '동네',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: '채팅',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '마이',
          ),
        ],
      ),
    ),
  );
}

class HomeScreen extends StatelessWidget {
  final Api api;
  const HomeScreen(this.api, {super.key});
  @override
  Widget build(BuildContext context) => AsyncView(
    load: () async => await Future.wait([
      api.call('/me'),
      api.call('/home'),
      api.call('/me/capabilities'),
    ]),
    builder: (data, reload) {
      final values = data as List,
          me = object(values[0]),
          home = object(values[1]),
          capabilities = object(values[2]);
      final profile = object(me['profile']),
          onboarding = object(me['onboarding']),
          recommendations = object(home['recommendations']);
      return PageBody(
        children: [
          Text(
            '${guardianNameText(profile['displayName'])}님, 안녕하세요',
            style: const TextStyle(fontSize: 15, color: secondaryLabel),
          ),
          const SizedBox(height: 6),
          Text(
            '오늘 누구랑 산책할까요?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          for (final meetup in items(home['upcomingMeetups']).take(1))
            Panel(
              color: tintBackground,
              child: ListTile(
                leading: const FeatureIcon(
                  Icons.event_rounded,
                  background: Colors.white,
                ),
                title: Text(label(meetup['title'])),
                subtitle: Text(
                  '다가오는 약속 · ${dateText(meetup['startsAt'])}\n${label(meetup['placeName'])}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: () =>
                    openScreen(context, MeetupScreen(api, label(meetup['id']))),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: DsButton(
                  onPressed: () => openScreen(context, DiscoveryScreen(api)),
                  icon: Icons.pets_outlined,
                  label: '친구 찾기',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DsButton(
                  onPressed: () => openScreen(context, MeetupEditor(api)),
                  icon: Icons.add_rounded,
                  label: '모임 만들기',
                  variant: DsButtonVariant.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          if (onboarding.values.any((v) => v == false))
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '산책을 시작하려면',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Text(
                        '${['profile', 'dog', 'region', 'healthSubmitted'].where((key) => onboarding[key] == true).length}/4',
                        style: const TextStyle(
                          color: tint,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '우리 강아지와 동네를 알려주세요.',
                    style: TextStyle(color: secondaryLabel, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  GroupedRows(
                    children: [
                      if (onboarding['profile'] == false)
                        ListTile(
                          leading: const FeatureIcon(Icons.person_rounded),
                          title: const Text('보호자 정보 완성하기'),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                          ),
                          onTap: () =>
                              openScreen(context, OwnerEditor(api, profile)),
                        ),
                      if (onboarding['dog'] == false)
                        ListTile(
                          leading: const FeatureIcon(
                            Icons.pets_rounded,
                            color: Color(0xFF8B775C),
                            background: Color(0xFFF5F1E9),
                          ),
                          title: const Text('우리 강아지 등록하기'),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                          ),
                          onTap: () => openScreen(context, DogEditor(api)),
                        ),
                      if (onboarding['region'] == false)
                        ListTile(
                          leading: const FeatureIcon(
                            Icons.near_me_rounded,
                            color: Color(0xFF5B7559),
                            background: Color(0xFFEEF2EB),
                          ),
                          title: const Text('활동 동네 인증하기'),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                          ),
                          onTap: () => openScreen(context, RegionScreen(api)),
                        ),
                      if (onboarding['dog'] == true &&
                          onboarding['healthSubmitted'] == false)
                        ListTile(
                          leading: const FeatureIcon(
                            Icons.verified_user_rounded,
                          ),
                          title: const Text('건강 서류 제출하기'),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                          ),
                          onTap: () => openScreen(context, ProfileWrapper(api)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          if (capabilities['canPropose'] != true)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextButton.icon(
                style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                onPressed: () =>
                    openScreen(context, ActivityReadinessScreen(api)),
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: const Text('산책 준비 상태 확인하기'),
              ),
            ),
          Section(
            '가까이 있는 산책 친구',
            trailing: DsButton(
              label: '모두 보기',
              onPressed: () => openScreen(context, DiscoveryScreen(api)),
              variant: DsButtonVariant.ghost,
              size: DsButtonSize.compact,
            ),
          ),
          if (items(recommendations).isEmpty)
            const Panel(
              child: Row(
                children: [
                  Icon(Icons.pets_outlined, color: secondaryLabel, size: 28),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '아직 주변 친구가 없어요',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '동네를 인증하고 다시 찾아보세요.',
                          style: TextStyle(color: secondaryLabel, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          for (final dog in items(recommendations)) DogCard(api, dog),
          if (items(home['receivedProposals']).isNotEmpty)
            Section(
              '받은 산책 제안',
              trailing: DsButton(
                label: '전체 보기',
                onPressed: () => openScreen(context, ProposalsScreen(api)),
                variant: DsButtonVariant.ghost,
                size: DsButtonSize.compact,
              ),
            ),
          for (final p in items(home['receivedProposals']))
            Panel(
              child: ListTile(
                title: const Text('함께하자는 제안이 도착했어요'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    openScreen(context, ProposalScreen(api, label(p['id']))),
              ),
            ),
          if (records(home['neighborhoodPosts']).isNotEmpty)
            const Section('우리 동네 소식'),
          for (final post in records(home['neighborhoodPosts']))
            Panel(
              child: ListTile(
                title: Text(label(post['title'])),
                subtitle: Text(label(post['channelName'])),
                onTap: () =>
                    openScreen(context, PostScreen(api, label(post['id']))),
              ),
            ),
        ],
      );
    },
  );
}

class ProfileWrapper extends StatelessWidget {
  final Api api;
  const ProfileWrapper(this.api, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppTopBar(title: const Text('우리 강아지 관리')),
    body: ProfileScreen(api),
  );
}
