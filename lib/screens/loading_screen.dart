import 'package:flutter/material.dart';

import '../services/settings_service.dart';
import '../widgets/design_stage.dart';
import 'start_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  double _progress = 0;
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _bootstrap();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _runPhase(0, 0.2, () async {
      if (!AppConfig.isTest) {
        await Future.delayed(const Duration(seconds: 2));
      }
    });
    await _runPhase(0.2, 0.75, () async {
      await Future.delayed(
        Duration(milliseconds: 260 + (220 * (0.3 + 0.7)).toInt()),
      );
    });
    await _runPhase(0.75, 1.0, () async {
      await Future.delayed(const Duration(milliseconds: 180));
    });
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const StartScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  Future<void> _runPhase(
    double from,
    double to,
    Future<void> Function() work,
  ) async {
    setState(() => _progress = from);
    final done = work();
    final start = DateTime.now();
    while (true) {
      await Future.delayed(const Duration(milliseconds: 16));
      final t = DateTime.now().difference(start).inMilliseconds / 550.0;
      final p = (from + (to - from) * t.clamp(0, 1)).clamp(0.0, 1.0);
      if (mounted) setState(() => _progress = p);
      if (t >= 1) break;
    }
    await done;
    if (mounted) setState(() => _progress = to);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A120C),
      body: DesignStage(
        backgroundAsset: 'assets/images/LodingBG.png',
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: const Alignment(0, 0.55),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Image.asset(
                          'assets/images/LodingBarBox_01.png',
                          width: double.infinity,
                          fit: BoxFit.fill,
                          height: 32,
                        ),
                        FractionallySizedBox(
                          widthFactor: _progress.clamp(0.02, 1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 7,
                            ),
                            child: Image.asset(
                              'assets/images/LodingBar_01.png',
                              height: 18,
                              fit: BoxFit.fill,
                              alignment: Alignment.centerLeft,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${(_progress * 100).clamp(0, 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
