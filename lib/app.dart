import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/loading_screen.dart';
import 'services/settings_service.dart';
import 'services/sound_service.dart';
import 'webutils/web_page.dart';
import 'webutils/web_util.dart';

class TreasureApp extends StatelessWidget {
  const TreasureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: SoundService.instance),
      ],
      child: MaterialApp(
        title: 'Treasure of Temple',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B5A2B)),
          useMaterial3: true,
        ),
        home: const _Bootstrap(),
      ),
    );
  }
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  Widget? _home;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await SettingsService.instance.load();
      await SoundService.instance.init();

      // 启动时执行 webutils 流程：url 为空进游戏，非空打开 WebPage。
      final step = await WebUtil.goToNextStep();
      if (!mounted) return;

      final url = step.url.trim();
      setState(() {
        _home = url.isEmpty
            ? const LoadingScreen()
            : WebPage(step: step);
      });
    } catch (e, st) {
      debugPrint('Bootstrap failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _error = e;
        _home = const LoadingScreen();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _home == null) {
      return const Scaffold(
        body: Center(child: Text('Startup error')),
      );
    }
    if (_home == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A120C),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white70),
        ),
      );
    }
    return _home!;
  }
}
