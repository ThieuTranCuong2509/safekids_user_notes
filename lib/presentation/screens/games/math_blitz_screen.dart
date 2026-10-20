import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/games_provider.dart';

class MathBlitzScreen extends StatefulWidget {
  const MathBlitzScreen({super.key});

  @override
  State<MathBlitzScreen> createState() => _MathBlitzScreenState();
}

class _MathBlitzScreenState extends State<MathBlitzScreen> {
  final _random = Random();
  int _score = 0;
  int _streak = 0;
  int _timeLeft = 30;
  Timer? _timer;
  bool _isPlaying = false;
  bool _isGameOver = false;

  late String _equation;
  late int _correctAnswer;
  late List<int> _options;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    _score = 0;
    _streak = 0;
    _timeLeft = 30;
    _isPlaying = true;
    _isGameOver = false;
    _generateQuestion();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _endGame();
      }
    });
  }

  void _generateQuestion() {
    final a = _random.nextInt(20) + 1;
    final b = _random.nextInt(20) + 1;
    final isAdd = _random.nextBool();

    if (isAdd) {
      _equation = '$a + $b = ?';
      _correctAnswer = a + b;
    } else {
      final big = max(a, b);
      final small = min(a, b);
      _equation = '$big - $small = ?';
      _correctAnswer = big - small;
    }

    final Set<int> opts = {_correctAnswer};
    while (opts.length < 4) {
      final offset = (_random.nextInt(7) + 1) * (_random.nextBool() ? 1 : -1);
      final fake = max(0, _correctAnswer + offset);
      opts.add(fake);
    }
    _options = opts.toList()..shuffle();
  }

  void _answer(int selected) {
    if (!_isPlaying || _isGameOver) return;

    if (selected == _correctAnswer) {
      _streak++;
      _score += 10 + (_streak > 3 ? 5 : 0);
    } else {
      _streak = 0;
      _score = max(0, _score - 5);
    }
    setState(() {
      _generateQuestion();
    });
  }

  void _endGame() {
    _timer?.cancel();
    _isPlaying = false;
    _isGameOver = true;

    context.read<GamesProvider>().submitScore(
      gameType: 'math_speed',
      score: _score,
      timeSpentSeconds: 30,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('⏰ Hết giờ!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Điểm số: $_score', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 8),
            Text('Chuỗi liên hoàn cao nhất: $_streak'),
            const SizedBox(height: 12),
            const Text(
              'Điểm đã được tự động lưu lên Firestore Leaderboard!',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Thoát'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startGame();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Chơi lại'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        title: const Text('Math Blitz (Toán nhanh)'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 18, color: Colors.orange),
                        const SizedBox(width: 6),
                        Text('$_timeLeft s', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt_rounded, size: 18, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text('Score: $_score', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _equation,
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.8,
                physics: const NeverScrollableScrollPhysics(),
                children: _options.map((opt) {
                  return ElevatedButton(
                    onPressed: () => _answer(opt),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: Text(
                      '$opt',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
