import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

/// Root App
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowMaterialGrid: false, // Removes the Debug Banner
      title: 'Flutter Timer Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const TimerPage(title: 'Animated Timer'),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Timer Page
class TimerPage extends StatefulWidget {
  const TimerPage({super.key, required this.title});
  final String title;

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage>
    with SingleTickerProviderStateMixin {
  int _seconds = 0;
  Timer? _timer;
  bool _running = false;

  void _startTimer() {
    if (_running) return;
    _running = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _pauseTimer() {
    _running = false;
    _timer?.cancel();
  }

  void _resetTimer() {
    _running = false;
    _timer?.cancel();
    setState(() {
      _seconds = 0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Format seconds into mm:ss
  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFA726), Color(0xFFFB8C00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Elapsed Time",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 30),

            /// Advanced Animated Timer
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (child, animation) {
                final rotate = Tween(begin: 1.0, end: 0.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOutBack),
                );
                return AnimatedBuilder(
                  animation: rotate,
                  child: child,
                  builder: (context, child) {
                    final isUnder = (ValueKey(_seconds) != child?.key);
                    var tilt = (rotate.value - 0.5).abs() - 0.5;
                    tilt *= isUnder ? -0.003 : 0.003;

                    return Transform(
                      transform: Matrix4.rotationY(rotate.value * 3.14)
                        ..setEntry(3, 0, tilt),
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: animation.value,
                        child: child,
                      ),
                    );
                  },
                );
              },
              child: Text(
                _formatTime(_seconds),
                key: ValueKey<int>(_seconds),
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 3,
                  shadows: [
                    Shadow(
                      offset: Offset(3, 3),
                      blurRadius: 6,
                      color: Colors.black38,
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 50),

            // Buttons row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildButton(
                  icon: _running ? Icons.pause : Icons.play_arrow,
                  label: _running ? "Pause" : "Start",
                  color: Colors.greenAccent,
                  onTap: _running ? _pauseTimer : _startTimer,
                ),
                const SizedBox(width: 20),
                _buildButton(
                  icon: Icons.stop,
                  label: "Reset",
                  color: Colors.redAccent,
                  onTap: _resetTimer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Custom rounded button widget
  Widget _buildButton(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 6,
      ),
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
