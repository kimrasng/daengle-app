import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';

import 'core/api.dart';
import 'features/auth.dart';
import 'features/home.dart';
import 'ui/shared.dart';

import 'package:daengle_design/daengle_design.dart' show DaengleTheme;
export 'package:daengle_design/daengle_design.dart' show buildAppTheme;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      ['Pretendard'],
      await rootBundle.loadString(
        'packages/daengle_design/assets/fonts/OFL.txt',
      ),
    );
  });
  runApp(DaengleApp(api: Api()));
}

class DaengleApp extends StatelessWidget {
  final Api api;
  const DaengleApp({super.key, required this.api});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '댕글',
    locale: const Locale('ko'),
    supportedLocales: const [Locale('ko'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    debugShowCheckedModeBanner: false,
    theme: DaengleTheme.light(),
    home: SessionGate(api),
  );
}

class SessionGate extends StatefulWidget {
  final Api api;
  const SessionGate(this.api, {super.key});
  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  bool ready = false;
  Object? error;
  @override
  void initState() {
    super.initState();
    restore();
  }

  Future<void> restore() async {
    setState(() {
      error = null;
      ready = false;
    });
    try {
      await widget.api.restore();
      if (mounted) setState(() => ready = true);
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e;
          ready = widget.api.session == null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ready) {
      return Scaffold(
        body: Center(
          child: error == null
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$error'),
                      const SizedBox(height: 16),
                      DsButton(label: '다시 연결', onPressed: restore),
                    ],
                  ),
                ),
        ),
      );
    }
    return ListenableBuilder(
      listenable: widget.api,
      builder: (context, _) => widget.api.accessToken == null
          ? LoginScreen(widget.api)
          : Navigator(
              key: ValueKey(widget.api.userId),
              observers: [routeObserver],
              onGenerateRoute: (_) =>
                  MaterialPageRoute<void>(builder: (_) => AppShell(widget.api)),
            ),
    );
  }
}
