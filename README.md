# 댕글 Flutter 앱

기존 Express 백엔드 `/v1` 계약에 연결한 iOS·Android 사용자 앱이다. Flutter 3.47.2 / Dart 3.13.2로 개발했고 패키지 버전은 `pubspec.lock`에 고정했다.

## 디자인 컴포넌트

공통 UI는 이 저장소의 `packages/daengle_design` Flutter 패키지를 path 의존성으로 사용한다. 별도 저장소 없이 `flutter pub get`으로 의존성을 설치할 수 있다. 패키지의 `DaengleTheme.light()`와 버튼·필드·선택·레이아웃을 사용하며 실제 서버 데이터와 비즈니스 로직은 이 앱에 남아 있다. [컴포넌트 안내](packages/daengle_design/README.md)을 참고한다.

## 실행

백엔드·MySQL·Redis·파일 저장소·워커를 먼저 실행한다. [백엔드 실행 안내](https://github.com/kimrasng/daengle-backend)를 따른다. 아래 명령은 이 저장소 루트에서 실행한다. Flutter SDK를 PATH에 등록한다.

```sh
flutter pub get
flutter devices

# iOS 시뮬레이터 / 로컬 API
flutter run -d <ios-device-id> \
  --dart-define=API_BASE_URL=http://localhost:4000/v1 \
  --dart-define=ENABLE_DEV_IDENTITY=true

# Android 에뮬레이터 / 호스트 Mac의 API
flutter run -d <android-device-id> \
  --dart-define=API_BASE_URL=http://10.0.2.2:4000/v1 \
  --dart-define=ENABLE_DEV_IDENTITY=true
```

가입 진입은 **보호자 본인인증**으로 통일했다. 보호자 프로필은 **보호자님의 정보를 입력해주세요**라고 안내하고 공개 닉네임과 산책 취향을 받는다. `ENABLE_DEV_IDENTITY=true`인 비 release 빌드에서는 이름·생년월일·선택 성별을 받는 미리보기 입력 폼을 사용하며, 실제 휴대폰 인증이 실행되지 않는다는 안내를 표시한다. 생일은 직접 선택해야 진행한다. 이 모드는 실제 인증을 대체하는 운영 기능이 아니고 개발용 약관도 운영 약관을 대신하지 않는다.

기본 복귀 주소는 백엔드 `.env.example`의 `APP_ORIGIN=http://localhost:8081`과 일치한다. 변경할 때 `--dart-define=IDENTITY_RETURN_URL=<서버가 허용한 주소>`도 지정한다. 운영 인증 서버는 제공사의 HTTPS 인증 URL을 외부 브라우저로 열고, 사용자가 앱으로 돌아와 **인증 완료하고 계속하기**를 누르면 서버 거래를 교환한다. 제공사별 SDK·자동 복귀 딥링크는 추가 연결 대상이다.

Android 업로드에는 백엔드 `S3_PUBLIC_ENDPOINT=http://10.0.2.2:9000`을 설정한 후 API를 다시 시작한다. iOS 시뮬레이터에는 `http://localhost:9000`을 사용한다. 서명된 URL의 호스트를 앱이 바꾸지 않으므로 실행 대상에서 접근 가능한 주소로 서버를 설정해야 한다.

실기기는 `localhost`가 개발 Mac이 아니다. API의 `HOST=0.0.0.0`, 같은 LAN의 Mac IP 또는 HTTPS 개발 도메인을 사용하고 `API_BASE_URL`과 `S3_PUBLIC_ENDPOINT`를 함께 맞춘다. HTTP 허용은 Android debug manifest와 iOS `Info-Debug.plist`에만 적용했다. release에는 HTTPS API·저장소가 필요하다. iOS 플러그인은 Swift Package Manager로 연결된다.

## 화면과 기능

- **홈**: 다가오는 확정 모임, 가입 준비 상태, 추천 친구, 받은 제안, 동네 소식, 서버 활동 자격 안내.
- **친구 찾기**: 거리·크기·산책 시간 필터, 추천 이유, 다음 페이지, 공개 프로필·사진, 활동 복수 선택, 동행 강아지 선택, 서버 카드 미리보기와 제안. 지역·건강 심사·약관 제한은 해결 화면으로 연결하며 빈 검색 결과는 30km까지 바로 확장할 수 있다.
- **동네**: 채널 생성·가입·승인·멤버 조회·대표 이전·내보내기·탈퇴·보관, 게시글·사진·수정·삭제, 댓글·수정·삭제, 채널 채팅.
- **모임**: 산책 모임·즉석 동행 생성, 공개 장소·시간·정원·크기 조건, 참여 신청·취소, 주최자 승인·거절·내보내기·모임 취소, 즉석 동행 연장, 모임 채팅.
- **나의 모임**: 동네·마이에서 참여 확정/주최 모임, 신청 중, 지난 내역 조회. 다가오는 모임은 가까운 일정부터 표시하고 상세로 연결한다.
- **채팅**: 방 목록, Socket.IO 수신, REST 순번 복구, 읽음·음소거, 사진 첨부, 메시지 신고, 실패 메시지의 동일 ID 재시도.
- **마이**: 견주 산책 정보·사진, 다견 등록·수정·보관, 등록 작성본 저장·복구, 성격 테스트·결과, 위치 권한·동네 인증, 건강 서류·심사 사유, 가족 초대·취소·수락·대표 이전·해제, 제안함·친구 관리.
- **산책 준비**: 마이와 홈에서 견주·강아지·동네·건강 심사·필수 약관 상태를 모아보고 필요한 화면으로 이동. 돌아오면 서버 상태를 다시 확인한다.
- **알림**: 미확인 수 배지, 전체/안 읽음 필터, 조회 시각까지 모두 읽기, 관련 제안·모임·대화 연결. 배지는 탭 전환·앱 복귀·알림 화면 복귀 시 갱신한다.
- **설정**: 공개 범위, 알림 수신 설정, 차단·해제, 신고 내역, 제재·이의제기, 현재 약관 동의, 로그아웃, 서버 탈퇴 사전 확인.

서버가 권한·심사·유효기간·지역 인증을 최종 판정한다. 심사 상태와 승인 효력을 나누어 표시한다. 서류는 실제 업로드 → 서버 검사 READY 확인 → 심사 제출 순서로 처리하며 원본을 공개 사진으로 표시하지 않는다. 파일 선택은 시스템 문서 선택기를 사용하며 카메라 촬영은 포함하지 않는다.

## 인증과 복구

접근 토큰은 메모리에만 두고 갱신 토큰을 Keychain/Android 보안 저장소에 보관한다. 앱 재시작 시 갱신하고, 동시 401은 하나의 갱신 작업을 공유한다. 일시적인 네트워크 실패에는 갱신 토큰을 지우지 않는다. 생성 요청은 동일 본문·멱등 키로 재시도한다. 채팅 전송 실패에는 동일 `clientMessageId`·본문·첨부로 재시도한다.

채팅은 가입 순번부터 REST를 페이지 끝까지 조회하고 **연속으로 확인한 순번**만 복구 커서로 사용한다. Socket.IO 이벤트는 재조회 계기로 쓰며 숨김 메시지도 순번을 유지한다. 연결 실패 시 15초 간격의 REST 재조회가 보조하고 앱 복귀 시 갱신한다. 대화방 접근권을 잃으면 표시 중인 메시지를 제거한다. 앱이 활성 상태이고 최신 메시지가 보이는 위치일 때 읽음을 저장한다.

현재 채팅 이력은 방 진입 시 가입 이후 이력을 메모리로 복구한다. 긴 대화방의 과거 이력 지연 로딩·로컬 DB 캐시는 후속 최적화 항목이다. 작성본 임시 저장·복구는 신규 강아지 등록 화면에 연결했다. 다른 온보딩 단계 전체의 자동 임시 저장은 아직 구현하지 않았다.

## 검증

```sh
flutter analyze
flutter test

# 로컬 합성 계정 2개를 만들고 마지막에 탈퇴 처리한다.
# API·워커·S3·seed된 개발 운영자 계정이 필요하다.
flutter test test/live_backend_test.dart \
  --dart-define=RUN_LOCAL_BACKEND_TESTS=true

# 실제 iOS 화면을 조작하는 테스트. 개발 인증 서버가 필요하다.
flutter test integration_test/app_test.dart -d <ios-device-id> \
  --dart-define=ENABLE_DEV_IDENTITY=true

# 실제 서류 업로드·검사·관리자 승인으로 합성 계정을 준비한 신규 기능 QA
QA_OUTPUT_DIR=qa/screenshots flutter drive \
  --driver=integration_test/qa_driver.dart --target=integration_test/product_gaps_test.dart \
  -d <device-id> --dart-define=ENABLE_DEV_IDENTITY=true \
  --dart-define=API_BASE_URL=<platform-local-api-url>

flutter build ios --simulator --debug --dart-define=ENABLE_DEV_IDENTITY=true
flutter build apk --debug --dart-define=ENABLE_DEV_IDENTITY=true \
  --dart-define=API_BASE_URL=http://10.0.2.2:4000/v1
```

로컬 통합 테스트는 `localhost`·`127.0.0.1`에만 연결한다. 운영자 로그인 기본값은 백엔드의 공개된 로컬 seed 값이며 앱 런타임에는 운영자 코드·자격증명이 포함되지 않는다. 변경한 로컬 계정은 테스트 실행 시 `LOCAL_ADMIN_EMAIL`·`LOCAL_ADMIN_PASSWORD` dart define으로 전달한다. 비밀값은 셸 기록에 남기지 않는 환경별 실행 방법을 사용한다.

## 운영 연결 전 남은 항목

실제 본인확인 사업자·딥링크, 전국 지역/공개 장소 데이터, 실제 약관·성향 문항·건강 심사 정책은 백엔드와 함께 확정해야 한다. 현재 지도 SDK 화면은 없고 서버의 공개 장소 목록을 사용한다. APNs/FCM 네이티브 기기 등록과 백그라운드 푸시는 아직 연결하지 않았으며 앱 내 알림과 수신 설정만 구현했다.

실기기 GPS·파일 선택·기기 잠금 후 세션 저장, 운영 인증과 HTTPS, App Store/Play 서명·개인정보 표시·배포 심사는 별도 검증이 필요하다. Android release 서명은 생성된 템플릿 상태이므로 배포 전에 실제 키를 설정해야 한다. 현재 결과물은 로컬 서버와 연결해 기능을 확인하는 개발 버전이다.
