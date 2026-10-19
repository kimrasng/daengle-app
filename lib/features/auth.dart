import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api.dart';
import '../ui/shared.dart';

const developmentIdentity =
    bool.fromEnvironment('ENABLE_DEV_IDENTITY') && !kReleaseMode;

class LoginScreen extends StatefulWidget {
  final Api api;
  const LoginScreen(this.api, {super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final guardianName = TextEditingController(), birth = TextEditingController();
  final form = GlobalKey<FormState>();
  String gender = 'OTHER';
  Json? transaction, registration;
  List<Json>? terms;
  final selected = <String>{};
  @override
  void dispose() {
    guardianName.dispose();
    birth.dispose();
    super.dispose();
  }

  Future<void> start() async {
    if (developmentIdentity && !form.currentState!.validate()) return;
    transaction = object(
      await widget.api.call(
        '/auth/identity/transactions',
        method: 'POST',
        authenticated: false,
        data: {
          'returnUrl': const String.fromEnvironment(
            'IDENTITY_RETURN_URL',
            defaultValue: 'http://localhost:8081',
          ),
        },
      ),
    );
    if (transaction!['provider'] == 'development') {
      if (!developmentIdentity) {
        throw const ApiFailure('지금은 보호자 본인인증을 진행할 수 없어요. 잠시 후 다시 시도해주세요.');
      }
      final path = label(transaction!['developmentCompletionPath'])
          .replaceFirst(RegExp(r'^/v1'), '');
      await widget.api.call(
        path,
        method: 'POST',
        authenticated: false,
        data: {
          'subject': guardianName.text.trim(),
          'birthDate': birth.text.trim(),
          'gender': gender,
        },
      );
      await exchange();
    } else {
      final url = Uri.parse(label(transaction!['verificationUrl']));
      if (url.scheme != 'https' ||
          !await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw const ApiFailure('보호자 본인인증 페이지를 열 수 없어요. 다시 시도해주세요.');
      }
      if (mounted) setState(() {});
    }
  }

  Future<void> exchange() async {
    final result = object(
      await widget.api.call(
        '/auth/identity/exchange',
        method: 'POST',
        authenticated: false,
        data: {
          'transactionId': transaction!['transactionId'],
          'nonce': transaction!['nonce'],
        },
      ),
    );
    if (result['kind'] == 'LOGIN') {
      await widget.api.establish(result);
      return;
    }
    registration = result;
    terms = items(await widget.api.call('/terms', authenticated: false));
    if (mounted) setState(() {});
  }

  Future<void> openGuardianIdentity() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (pageContext) => StatefulBuilder(
          builder: (context, update) {
            final awaitingProvider =
                transaction != null &&
                transaction!['provider'] != 'development';
            return DsPage(
              title: '보호자 본인인증',
              footer: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SubmitButton(
                    awaitingProvider ? '인증 완료하고 계속하기' : '보호자 본인인증',
                    key: const ValueKey('guardian-verification-submit'),
                    onPressed: () async {
                      if (developmentIdentity &&
                          !form.currentState!.validate()) {
                        return;
                      }
                      if (awaitingProvider) {
                        await exchange();
                        if (pageContext.mounted) Navigator.pop(pageContext);
                      } else {
                        await start();
                        if (!pageContext.mounted) return;
                        if (transaction!['provider'] == 'development') {
                          Navigator.pop(pageContext);
                        } else {
                          update(() {});
                        }
                      }
                    },
                  ),
                  if (awaitingProvider)
                    SubmitButton(
                      '본인인증 다시하기',
                      secondary: true,
                      onPressed: () async {
                        await start();
                        if (pageContext.mounted) update(() {});
                      },
                    ),
                ],
              ),
              children: [
                PageIntro(
                  developmentIdentity
                      ? '보호자님의 정보를 입력해주세요'
                      : '보호자님의 본인인증을 진행해주세요',
                  developmentIdentity
                      ? '함께 산책할 보호자님을 확인할게요.'
                      : '보호자님 명의의 휴대폰으로 본인인증을 진행해요. 인증 서비스에서 정보를 확인해주세요.',
                ),
                if (developmentIdentity)
                  Form(
                    key: form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DsTextField(
                          label: '보호자 이름',
                          controller: guardianName,
                          hint: '이름을 입력해주세요',
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? '보호자님의 이름을 입력해주세요.'
                              : null,
                        ),
                        BirthdayField(birth, title: '보호자 생년월일'),
                        DsSelectField<String>(
                          initialValue: gender,
                          label: '성별',
                          optional: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'OTHER',
                              child: Text('선택 안 함'),
                            ),
                            DropdownMenuItem(
                              value: 'FEMALE',
                              child: Text('여성'),
                            ),
                            DropdownMenuItem(value: 'MALE', child: Text('남성')),
                          ],
                          onChanged: (v) => gender = v!,
                        ),
                      ],
                    ),
                  ),
                if (awaitingProvider)
                  const DsNotice(
                    message: '본인인증을 마치셨나요? 인증을 완료한 뒤 아래 버튼을 눌러주세요.',
                  ),
                if (developmentIdentity)
                  const Text(
                    '현재 미리보기 환경에서는 실제 휴대폰 인증이 진행되지 않아요.',
                    style: TextStyle(
                      color: secondaryLabel,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: groupedBackground,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: LayoutBuilder(
            builder: (context, constraints) => Column(
              children: [
                Expanded(
                  child: PageBody(
                    children: [
                      const SizedBox(height: 24),
                      const Row(
                        children: [
                          Icon(Icons.pets_rounded, color: tint, size: 24),
                          SizedBox(width: 8),
                          Text(
                            '댕글',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),
                      if (terms == null) ...[
                        Text(
                          '산책 친구,\n우리 동네에서 만나요',
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                fontSize: 34,
                                height: 1.35,
                                letterSpacing: -1,
                              ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '가까운 강아지 친구를 만나고\n같이 걷는 일상을 시작해요.',
                          style: TextStyle(
                            color: secondaryLabel,
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 40),
                        const Divider(),
                        const SizedBox(height: 20),
                        const ListTile(
                          leading: Icon(Icons.pets_outlined, color: tint),
                          title: Text('가까운 산책 친구'),
                          subtitle: Text('우리 강아지와 잘 맞는 친구를 찾아요'),
                        ),
                        const ListTile(
                          leading: Icon(Icons.map_outlined, color: tint),
                          title: Text('동네에서 잡는 산책 약속'),
                          subtitle: Text('시간이 맞는 이웃과 함께 걸어요'),
                        ),
                        const ListTile(
                          leading: Icon(Icons.chat_bubble_outline, color: tint),
                          title: Text('같이 나누는 강아지 이야기'),
                          subtitle: Text('우리 동네 소식과 산책 팁을 나눠요'),
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (terms != null) ...[
                        const PageIntro('함께 시작하기', '필수 약관을 확인하고 동의해주세요.'),
                        for (final term in terms!)
                          Panel(
                            color: groupedBackground,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DsCheckbox(
                                  label:
                                      '${term['required'] == true || term['required'] == 1 ? '[필수]' : '[선택]'} ${term['title']}',
                                  value: selected.contains(term['id']),
                                  onChanged: (value) => setState(() {
                                    if (value == true) {
                                      selected.add(term['id']);
                                    } else {
                                      selected.remove(term['id']);
                                    }
                                  }),
                                ),
                                ExpansionTile(
                                  dense: true,
                                  tilePadding: const EdgeInsets.only(
                                    left: 12,
                                    right: 4,
                                  ),
                                  title: const Text(
                                    '내용 보기',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: secondaryLabel,
                                    ),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Text(label(term['content'])),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        SubmitButton(
                          '동의하고 가입하기',
                          onPressed: () async {
                            if (terms!
                                .where(
                                  (t) =>
                                      t['required'] == true ||
                                      t['required'] == 1,
                                )
                                .any((t) => !selected.contains(t['id']))) {
                              throw const ApiFailure('필수 약관에 동의해주세요.');
                            }
                            final session = object(
                              await widget.api.call(
                                '/auth/registrations',
                                method: 'POST',
                                authenticated: false,
                                data: {
                                  'ticket': registration!['ticket'],
                                  'consentVersionIds': selected.toList(),
                                },
                              ),
                            );
                            await widget.api.establish(session);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                if (terms == null)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * .55,
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DsButton(
                              label: '보호자 본인인증',
                              onPressed: openGuardianIdentity,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '만 19세 이상부터 이용할 수 있어요.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: secondaryLabel,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
