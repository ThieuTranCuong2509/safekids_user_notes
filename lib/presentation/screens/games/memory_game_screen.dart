import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/games_provider.dart';

class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({super.key});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _CardItem {
  final int id;
  final String emoji;
  bool isFlipped;
  bool isMatched;

  _CardItem({
    required this.id,
    required this.emoji,
  })  : isFlipped = false,
        isMatched = false;
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  static const List<String> _emojis = ['💡', '🚀', '🎯', '⭐', '🎨', '🔥'];

  late List<_CardItem> _cards;
  int? _firstFlippedIndex;
  bool _isBusy = false;
  int _moves = 0;
  int _seconds = 0;
  Timer? _timer;
  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    _timer?.cancel();
    _seconds = 0;
    _moves = 0;
    _isGameOver = false;
    _firstFlippedIndex = null;
    _isBusy = false;

    // Create 6 pairs
    final List<_CardItem> list = [];
    int idCounter = 0;
    for (final emoji in _emojis) {
      list.add(_CardItem(id: idCounter++, emoji: emoji));
      list.add(_CardItem(id: idCounter++, emoji: emoji));
    }
    list.shuffle();
    _cards = list;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isGameOver) {
        setState(() => _seconds++);
      }
    });

    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onCardTap(int index) {
    if (_isBusy || _cards[index].isFlipped || _cards[index].isMatched || _isGameOver) {
      return;
    }

    setState(() {
      _cards[index].isFlipped = true;
    });

    if (_firstFlippedIndex == null) {
      _firstFlippedIndex = index;
    } else {
      _moves++;
      final firstIndex = _firstFlippedIndex!;
      _firstFlippedIndex = null;

      if (_cards[firstIndex].emoji == _cards[index].emoji) {
        // Matched!
        setState(() {
          _cards[firstIndex].isMatched = true;
          _cards[index].isMatched = true;
        });

        // Check if all matched
        if (_cards.every((c) => c.isMatched)) {
          _handleGameWin();
        }
      } else {
        // Not matched, flip back after 700ms
        _isBusy = true;
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) {
            setState(() {
              _cards[firstIndex].isFlipped = false;
              _cards[index].isFlipped = false;
              _isBusy = false;
            });
          }
        });
      }
    }
  }

  void _handleGameWin() {
    _isGameOver = true;
    _timer?.cancel();

    // Calculate score
    final score = (1000 - (_moves * 25 + _seconds * 10)).clamp(150, 1000);

    // Save score to Firestore
    context.read<GamesProvider>().submitScore(
      gameType: 'memory_match',
      score: score,
      timeSpentSeconds: _seconds,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🎉 ', style: TextStyle(fontSize: 28)),
            Text('Chiến thắng!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Điểm số: $score', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 8),
            Text('Thời gian hoàn thành: $_seconds giây'),
            Text('Số lượt lật thẻ: $_moves lượt'),
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
              _startNewGame();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Chơi lại'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        title: const Text('Memory Match (Lật thẻ trí nhớ)'),
        actions: [
          IconButton(
            tooltip: 'Chơi lại',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _startNewGame,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
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
                        const Icon(Icons.timer_outlined, size: 18, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text('$_seconds s', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                        const Icon(Icons.touch_app_outlined, size: 18, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text('$_moves lượt', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    final showFace = card.isFlipped || card.isMatched;

                    return GestureDetector(
                      onTap: () => _onCardTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: showFace
                              ? (card.isMatched ? const Color(0xFFE8F5E9) : Colors.white)
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: card.isMatched ? Colors.green : AppColors.border,
                            width: card.isMatched ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(showFace ? 10 : 25),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: showFace
                              ? Text(
                                  card.emoji,
                                  style: const TextStyle(fontSize: 36),
                                )
                              : const Icon(
                                  Icons.question_mark_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
