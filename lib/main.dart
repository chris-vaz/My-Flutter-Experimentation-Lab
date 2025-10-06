import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

/// Root App
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pomodoro Timer',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFFF6B9D),
          secondary: const Color(0xFFC86DD7),
          surface: const Color(0xFF1D1E33),
        ),
        useMaterial3: true,
      ),
      home: const PomodoroTimerPage(),
    );
  }
}

/// Pomodoro Timer Page
class PomodoroTimerPage extends StatefulWidget {
  const PomodoroTimerPage({super.key});

  @override
  State<PomodoroTimerPage> createState() => _PomodoroTimerPageState();
}

class _PomodoroTimerPageState extends State<PomodoroTimerPage>
    with TickerProviderStateMixin {
  // Timer states
  Timer? _timer;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  
  // Pomodoro settings
  TimerMode _currentMode = TimerMode.focus;
  int _focusDuration = 25;
  int _shortBreakDuration = 5;
  int _longBreakDuration = 15;
  int _completedPomodoros = 0;
  int _dailyGoal = 8;
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _onTimerComplete();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _getDurationForMode(_currentMode) * 60;
    });
  }

  void _onTimerComplete() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      if (_currentMode == TimerMode.focus) {
        _completedPomodoros++;
        if (_completedPomodoros % 4 == 0) {
          _switchMode(TimerMode.longBreak);
        } else {
          _switchMode(TimerMode.shortBreak);
        }
      } else {
        _switchMode(TimerMode.focus);
      }
    });
    _showCompletionDialog();
  }

  void _switchMode(TimerMode newMode) {
    setState(() {
      _currentMode = newMode;
      _remainingSeconds = _getDurationForMode(newMode) * 60;
    });
  }

  int _getDurationForMode(TimerMode mode) {
    switch (mode) {
      case TimerMode.focus:
        return _focusDuration;
      case TimerMode.shortBreak:
        return _shortBreakDuration;
      case TimerMode.longBreak:
        return _longBreakDuration;
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _currentMode == TimerMode.focus ? '🎉 Break Time!' : '💪 Back to Work!',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        content: Text(
          _currentMode == TimerMode.focus
              ? 'Great job! Time for a well-deserved break.'
              : 'Break is over. Ready to focus again?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    // Create local copies for the dialog
    int tempFocus = _focusDuration;
    int tempShort = _shortBreakDuration;
    int tempLong = _longBreakDuration;
    int tempGoal = _dailyGoal;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1D1E33),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.settings, color: _getModeColor()),
                const SizedBox(width: 10),
                const Text(
                  'Settings',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSettingSliderInDialog(
                    label: 'Focus Duration',
                    icon: Icons.psychology,
                    value: tempFocus.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    onChanged: (value) {
                      setDialogState(() => tempFocus = value.toInt());
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildSettingSliderInDialog(
                    label: 'Short Break',
                    icon: Icons.coffee,
                    value: tempShort.toDouble(),
                    min: 1,
                    max: 15,
                    divisions: 14,
                    onChanged: (value) {
                      setDialogState(() => tempShort = value.toInt());
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildSettingSliderInDialog(
                    label: 'Long Break',
                    icon: Icons.hotel,
                    value: tempLong.toDouble(),
                    min: 10,
                    max: 30,
                    divisions: 4,
                    onChanged: (value) {
                      setDialogState(() => tempLong = value.toInt());
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildSettingSliderInDialog(
                    label: 'Daily Goal',
                    icon: Icons.emoji_events,
                    value: tempGoal.toDouble(),
                    min: 4,
                    max: 16,
                    divisions: 12,
                    onChanged: (value) {
                      setDialogState(() => tempGoal = value.toInt());
                    },
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: _getModeColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getModeColor().withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: _getModeColor(), size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Changes apply immediately',
                            style: TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setDialogState(() {
                    tempFocus = 25;
                    tempShort = 5;
                    tempLong = 15;
                    tempGoal = 8;
                  });
                },
                child: const Text(
                  'Reset Defaults',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _focusDuration = tempFocus;
                    _shortBreakDuration = tempShort;
                    _longBreakDuration = tempLong;
                    _dailyGoal = tempGoal;
                    if (!_isRunning) {
                      _remainingSeconds = _getDurationForMode(_currentMode) * 60;
                    }
                  });
                  Navigator.pop(context);
                },
                child: Text(
                  'Done',
                  style: TextStyle(
                    color: _getModeColor(),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingSliderInDialog({
    required String label,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _getModeColor(), size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getModeColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.toInt()} min',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getModeColor(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: _getModeColor(),
            inactiveTrackColor: Colors.white12,
            thumbColor: _getModeColor(),
            overlayColor: _getModeColor().withOpacity(0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  Color _getModeColor() {
    switch (_currentMode) {
      case TimerMode.focus:
        return const Color(0xFFFF6B9D);
      case TimerMode.shortBreak:
        return const Color(0xFF4ECDC4);
      case TimerMode.longBreak:
        return const Color(0xFFC86DD7);
    }
  }

  String _getModeTitle() {
    switch (_currentMode) {
      case TimerMode.focus:
        return 'Focus Time';
      case TimerMode.shortBreak:
        return 'Short Break';
      case TimerMode.longBreak:
        return 'Long Break';
    }
  }

  String _getModeEmoji() {
    switch (_currentMode) {
      case TimerMode.focus:
        return '🎯';
      case TimerMode.shortBreak:
        return '☕';
      case TimerMode.longBreak:
        return '🌟';
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1 - (_remainingSeconds / (_getDurationForMode(_currentMode) * 60));
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A0E21),
              _getModeColor().withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildModeSelector(),
                      const SizedBox(height: 40),
                      _buildCircularTimer(progress),
                      const SizedBox(height: 50),
                      _buildControlButtons(),
                      const SizedBox(height: 40),
                      _buildStatsSection(),
                      const SizedBox(height: 20),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pomodoro Timer',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  foreground: Paint()
                    ..shader = LinearGradient(
                      colors: [_getModeColor(), _getModeColor().withOpacity(0.6)],
                    ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Stay focused, be productive',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white54,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QuotesPage(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D1E33),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: _getModeColor().withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.format_quote,
                    color: _getModeColor(),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _showSettingsDialog,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D1E33),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: _getModeColor().withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.settings_outlined,
                    color: _getModeColor(),
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1E33),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildModeButton(TimerMode.focus, 'Focus', Icons.psychology),
            _buildModeButton(TimerMode.shortBreak, 'Short', Icons.coffee),
            _buildModeButton(TimerMode.longBreak, 'Long', Icons.hotel),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(TimerMode mode, String label, IconData icon) {
    final isSelected = _currentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? _getModeColor() : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : Colors.white54,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularTimer(double progress) {
    return AnimatedBuilder(
      animation: _isRunning ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        return Transform.scale(
          scale: _isRunning ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _getModeColor().withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(280, 280),
                  painter: CircularProgressPainter(
                    progress: progress,
                    color: _getModeColor(),
                    backgroundColor: const Color(0xFF1D1E33),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getModeEmoji(),
                      style: const TextStyle(fontSize: 40),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _formatTime(_remainingSeconds),
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: _getModeColor().withOpacity(0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getModeTitle(),
                      style: TextStyle(
                        fontSize: 16,
                        color: _getModeColor(),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton(
          icon: Icons.refresh,
          onTap: _resetTimer,
          color: Colors.white24,
          size: 60,
        ),
        const SizedBox(width: 30),
        _buildControlButton(
          icon: _isRunning ? Icons.pause : Icons.play_arrow,
          onTap: _isRunning ? _pauseTimer : _startTimer,
          color: _getModeColor(),
          size: 80,
          isPrimary: true,
        ),
        const SizedBox(width: 30),
        _buildControlButton(
          icon: Icons.skip_next,
          onTap: () => _switchMode(
            _currentMode == TimerMode.focus 
                ? TimerMode.shortBreak 
                : TimerMode.focus,
          ),
          color: Colors.white24,
          size: 60,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required double size,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 25,
                    spreadRadius: 5,
                  ),
                ]
              : [],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: isPrimary ? 40 : 28,
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.check_circle_outline,
                  value: _completedPomodoros.toString(),
                  label: 'Completed',
                  color: const Color(0xFF4ECDC4),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.emoji_events_outlined,
                  value: '$_dailyGoal',
                  label: 'Daily Goal',
                  color: const Color(0xFFFFD93D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progressPercent = _completedPomodoros / _dailyGoal;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                '${(_completedPomodoros / _dailyGoal * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getModeColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progressPercent.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(_getModeColor()),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// NEW PAGE: Quotes Page with FutureBuilder
// ============================================

class QuotesPage extends StatefulWidget {
  const QuotesPage({super.key});

  @override
  State<QuotesPage> createState() => _QuotesPageState();
}

class _QuotesPageState extends State<QuotesPage> {
  late Future<List<Quote>> _quotesFuture;

  @override
  void initState() {
    super.initState();
    _quotesFuture = fetchQuotes();
  }

  // API call to fetch quotes
  Future<List<Quote>> fetchQuotes() async {
    // Using ZenQuotes API - free and no authentication required
    final response = await http.get(
      Uri.parse('https://zenquotes.io/api/quotes'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Quote.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load quotes');
    }
  }

  void _refreshQuotes() {
    setState(() {
      _quotesFuture = fetchQuotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0E21),
              Color(0xFF1D1E33),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildQuotesHeader(),
              Expanded(
                child: FutureBuilder<List<Quote>>(
                  future: _quotesFuture,
                  builder: (context, snapshot) {
                    // Loading state
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            CircularProgressIndicator(
                              color: Color(0xFFFF6B9D),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Loading inspiring quotes...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    // Error state
                    else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 80,
                              color: Color(0xFFFF6B9D),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Error: ${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 30),
                            ElevatedButton.icon(
                              onPressed: _refreshQuotes,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6B9D),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    // Success state with data
                    else if (snapshot.hasData) {
                      final quotes = snapshot.data!;
                      return RefreshIndicator(
                        onRefresh: () async {
                          _refreshQuotes();
                        },
                        color: const Color(0xFFFF6B9D),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: quotes.length,
                          itemBuilder: (context, index) {
                            return _buildQuoteCard(quotes[index], index);
                          },
                        ),
                      );
                    }
                    
                    // Empty state (no data)
                    else {
                      return const Center(
                        child: Text(
                          'No quotes available',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuotesHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1D1E33),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B9D).withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Color(0xFFFF6B9D),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Inspiration',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [Color(0xFFFF6B9D), Color(0xFFC86DD7)],
                      ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Stay motivated during your breaks',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white54,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _refreshQuotes,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1D1E33),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B9D).withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.refresh,
                color: Color(0xFFFF6B9D),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(Quote quote, int index) {
    final gradients = [
      [const Color(0xFFFF6B9D), const Color(0xFFFF8FAB)],
      [const Color(0xFF4ECDC4), const Color(0xFF6FE7DD)],
      [const Color(0xFFC86DD7), const Color(0xFFD88FE5)],
      [const Color(0xFFFFD93D), const Color(0xFFFFE066)],
    ];
    
    final gradient = gradients[index % gradients.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradient[0].withOpacity(0.1),
            gradient[1].withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gradient[0].withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.format_quote,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Quote #${index + 1}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: gradient[0],
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            quote.text,
            style: const TextStyle(
              fontSize: 18,
              height: 1.5,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Container(
                height: 2,
                width: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '- ${quote.author}',
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: gradient[0],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Quote model class
class Quote {
  final String text;
  final String author;

  Quote({required this.text, required this.author});

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      text: json['q'] ?? '',
      author: json['a'] ?? 'Unknown',
    );
  }
}

// Custom painter for circular progress
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius - 10, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withOpacity(0.5)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}

// Timer mode enum
enum TimerMode { focus, shortBreak, longBreak }