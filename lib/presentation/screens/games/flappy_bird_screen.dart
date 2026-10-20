import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/games_provider.dart';

class FlappyBirdScreen extends StatefulWidget {
  const FlappyBirdScreen({super.key});

  @override
  State<FlappyBirdScreen> createState() => _FlappyBirdScreenState();
}

class _PipePair {
  double x;
  final double topHeight;
  final double gap;
  bool isPassed;

  _PipePair({
    required this.x,
    required this.topHeight,
    this.gap = 160.0,
  }) : isPassed = false;
}

class _FlappyBirdScreenState extends State<FlappyBirdScreen> with SingleTickerProviderStateMixin {
  // Game states
  bool _isPlaying = false;
  bool _isGameOver = false;
  int _score = 0;
  int _bestScore = 0;

  // Bird physics
  double _birdY = 250.0;
  double _velocity = 0.0;
  static const double _gravity = 0.45;
  static const double _jumpForce = -7.5;
  static const double _birdSize = 34.0;
  static const double _birdX = 80.0;

  // Pipes
  final List<_PipePair> _pipes = [];
  static const double _pipeWidth = 56.0;
  static const double _pipeSpeed = 2.4;
  final Random _random = Random();

  Timer? _gameLoop;

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    _gameLoop?.cancel();
    _birdY = 250.0;
    _velocity = 0.0;
    _score = 0;
    _isPlaying = false;
    _isGameOver = false;
    _pipes.clear();
    setState(() {});
  }

  void _startGame() {
    _resetGame();
    _isPlaying = true;
    _velocity = _jumpForce;

    // Spawn first pipe
    _spawnPipe(350);
    _spawnPipe(550);

    _gameLoop = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) return;
      _updateGame();
    });
    setState(() {});
  }

  void _spawnPipe(double startX) {
    // Top height between 60 and 260
    final topH = 70.0 + _random.nextInt(180);
    _pipes.add(_PipePair(x: startX, topHeight: topH, gap: 155.0));
  }

  void _jump() {
    if (_isGameOver) {
      _startGame();
      return;
    }
    if (!_isPlaying) {
      _startGame();
      return;
    }
    _velocity = _jumpForce;
  }

  void _updateGame() {
    if (!_isPlaying || _isGameOver) return;

    // 1. Update bird
    _velocity += _gravity;
    _birdY += _velocity;

    final screenHeight = MediaQuery.of(context).size.height;
    final groundY = screenHeight - 140;

    // Ceiling / Ground collision
    if (_birdY <= 0 || _birdY + _birdSize >= groundY) {
      _triggerGameOver();
      return;
    }

    // 2. Update pipes
    for (int i = 0; i < _pipes.length; i++) {
      final p = _pipes[i];
      p.x -= _pipeSpeed;

      // Score check
      if (!p.isPassed && p.x + _pipeWidth < _birdX) {
        p.isPassed = true;
        _score++;
        if (_score > _bestScore) _bestScore = _score;
      }

      // Bird vs Pipe Collision
      final birdRect = Rect.fromLTWH(_birdX + 4, _birdY + 4, _birdSize - 8, _birdSize - 8);
      final topPipeRect = Rect.fromLTWH(p.x, 0, _pipeWidth, p.topHeight);
      final bottomPipeY = p.topHeight + p.gap;
      final bottomPipeRect = Rect.fromLTWH(p.x, bottomPipeY, _pipeWidth, groundY - bottomPipeY);

      if (birdRect.overlaps(topPipeRect) || birdRect.overlaps(bottomPipeRect)) {
        _triggerGameOver();
        return;
      }
    }

    // Remove offscreen pipe & spawn new
    if (_pipes.isNotEmpty && _pipes.first.x + _pipeWidth < -10) {
      _pipes.removeAt(0);
      final lastX = _pipes.isNotEmpty ? _pipes.last.x : 350.0;
      _spawnPipe(lastX + 210);
    }

    setState(() {});
  }

  void _triggerGameOver() {
    _gameLoop?.cancel();
    _isPlaying = false;
    _isGameOver = true;

    // Record high score to Firestore
    if (_score > 0) {
      context.read<GamesProvider>().submitScore(
        gameType: 'flappy_bird',
        score: _score * 10,
        timeSpentSeconds: max(5, _score * 2),
      );
    }

    setState(() {});
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final groundY = screenHeight - 140;

    return Scaffold(
      backgroundColor: const Color(0xFF70C5CE), // Classic Sky Blue
      appBar: AppBar(
        backgroundColor: const Color(0xFF70C5CE),
        elevation: 0,
        title: const Text('Flappy Bird', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _jump,
        child: Stack(
          children: [
            // Clouds in background
            Positioned(
              top: 50,
              left: 40,
              child: Opacity(opacity: 0.6, child: Icon(Icons.cloud, size: 80, color: Colors.white)),
            ),
            Positioned(
              top: 120,
              right: 30,
              child: Opacity(opacity: 0.5, child: Icon(Icons.cloud, size: 100, color: Colors.white)),
            ),

            // Pipes
            ..._pipes.map((p) => Positioned(
                  left: p.x,
                  top: 0,
                  bottom: screenHeight - groundY,
                  child: SizedBox(
                    width: _pipeWidth,
                    child: Column(
                      children: [
                        // Top Pipe
                        Container(
                          height: p.topHeight,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF73BF2E), Color(0xFF558022)],
                            ),
                            border: Border.all(color: Colors.black, width: 2),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                          ),
                        ),
                        // Gap
                        SizedBox(height: p.gap),
                        // Bottom Pipe
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF73BF2E), Color(0xFF558022)],
                              ),
                              border: Border.all(color: Colors.black, width: 2),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),

            // Ground
            Positioned(
              top: groundY,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFDED895),
                  border: Border(top: BorderSide(color: Color(0xFF558022), width: 12)),
                ),
                child: const Center(
                  child: Text('🌲 🌲 🌲', style: TextStyle(fontSize: 24)),
                ),
              ),
            ),

            // Bird
            Positioned(
              left: _birdX,
              top: _birdY,
              child: Transform.rotate(
                angle: (_velocity * 0.06).clamp(-0.5, 0.8),
                child: Container(
                  width: _birdSize,
                  height: _birdSize,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7D117), // Yellow Bird
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Center(
                    child: Text(
                      _velocity < 0 ? '🐤' : '🐥',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              ),
            ),

            // In-game Score
            if (_isPlaying)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '$_score',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(2, 2)),
                      ],
                    ),
                  ),
                ),
              ),

            // Tap to Start Screen
            if (!_isPlaying && !_isGameOver)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(220),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🐤', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 8),
                      Text(
                        'Chạm để bay!',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Vượt qua các ống cống để ghi điểm',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),

            // Game Over Dialog Overlay
            if (_isGameOver)
              Center(
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 16)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'GAME OVER',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.error),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Điểm: $_score',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kỷ lục: $_bestScore',
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Điểm số đã đồng bộ lên Firestore Leaderboard!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Chơi Lại', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
