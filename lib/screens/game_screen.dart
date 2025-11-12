import 'package:flutter/material.dart';
import '../models/piece.dart';
import '../models/position.dart';
import '../models/move.dart';
import '../game_logic/game_state.dart';
import '../game_logic/game_logic.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameState _gameState;
  late AnimationController _moveAnimationController;
  late AnimationController _pulseAnimationController;
  Position? _animatingFrom;
  Position? _animatingTo;

  @override
  void initState() {
    super.initState();
    _gameState = GameState.initial();

    _moveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _moveAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  void _handleCellTap(Position position) {
    if (_gameState.winner != null) return;

    final piece = _gameState.getPieceAt(position);

    // Если уже выбрана шашка
    if (_gameState.selectedPosition != null) {
      // Проверяем, можем ли сделать ход на эту клетку
      final move = _gameState.availableMoves.firstWhere(
        (m) => m.to == position,
        orElse: () => Move(from: Position(-1, -1), to: Position(-1, -1)),
      );

      if (move.from.row != -1) {
        // Делаем ход с анимацией
        _animatingFrom = move.from;
        _animatingTo = move.to;
        _moveAnimationController.forward(from: 0).then((_) {
          setState(() {
            _gameState = GameLogic.makeMove(_gameState, move);
            _animatingFrom = null;
            _animatingTo = null;
          });
        });
      } else if (piece != null && piece.color == _gameState.currentPlayer) {
        // Выбираем другую шашку
        setState(() {
          _gameState = GameLogic.selectPiece(_gameState, position);
        });
      } else {
        // Снимаем выделение
        setState(() {
          _gameState = _gameState.copyWith(
            clearSelectedPosition: true,
            availableMoves: [],
          );
        });
      }
    } else if (piece != null && piece.color == _gameState.currentPlayer) {
      // Выбираем шашку
      setState(() {
        _gameState = GameLogic.selectPiece(_gameState, position);
      });
    }
  }

  void _resetGame() {
    setState(() {
      _gameState = GameState.initial();
      _animatingFrom = null;
      _animatingTo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0a0e27),
              const Color(0xFF1a1a2e),
              const Color(0xFF16213e),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 20),
              _buildPlayerIndicator(),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: _buildBoard(),
                ),
              ),
              const SizedBox(height: 20),
              _buildScoreBoard(),
              const SizedBox(height: 20),
              _buildResetButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00f5ff),
                  const Color(0xFF00a8ff),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00f5ff).withValues(alpha: 0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.circle, color: Colors.white, size: 12),
          ),
          const SizedBox(width: 16),
          const Text(
            'Русские шашки',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1a1a1a),
                  const Color(0xFF000000),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.circle, color: Colors.black87, size: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00f5ff),
            const Color(0xFF00a8ff),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00f5ff).withValues(alpha: 0.6),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _gameState.currentPlayer == PieceColor.white
                  ? Colors.white
                  : Colors.black87,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            _gameState.currentPlayer == PieceColor.white
                ? 'Ход белых'
                : 'Ход чёрных',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1a1a2e).withValues(alpha: 0.9),
            const Color(0xFF16213e).withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00f5ff).withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildScoreItem('Белые', _gameState.whiteCaptures, Colors.white),
          Container(
            width: 2,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0xFF00f5ff).withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          _buildScoreItem('Чёрные', _gameState.blackCaptures, Colors.black87),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(
                  color: const Color(0xFF00f5ff).withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'x $count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResetButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _resetGame,
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFff006e),
                  const Color(0xFFff4081),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFff006e).withValues(alpha: 0.6),
                  blurRadius: 25,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'Новая игра',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBoard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxSize = screenWidth < screenHeight ? screenWidth : screenHeight * 0.6;
    final rawBoardSize = maxSize * 0.92;
    const borderWidth = 4.0;
    final innerSize = ((rawBoardSize - borderWidth * 2) ~/ 8) * 8.0;
    final boardSize = innerSize + borderWidth * 2;
    final cellSize = innerSize / 8;

    return Container(
      width: boardSize,
      height: boardSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00f5ff),
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00f5ff).withValues(alpha: 0.6),
            blurRadius: 35,
            spreadRadius: 3,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Клетки доски
            _buildBoardCells(cellSize),
            // Шашки
            ..._buildPieces(cellSize),
            // Winner overlay
            if (_gameState.winner != null) _buildWinnerOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardCells(double cellSize) {
    return Column(
      children: List.generate(8, (row) {
        return Row(
          children: List.generate(8, (col) {
            final position = Position(row, col);
            final isBlackCell = (row + col) % 2 == 1;
            final isSelected = _gameState.selectedPosition == position;
            final isAvailableMove = _gameState.availableMoves
                .any((move) => move.to == position);

            return GestureDetector(
              onTap: () => _handleCellTap(position),
              child: AnimatedBuilder(
                animation: _pulseAnimationController,
                builder: (context, child) {
                  final pulse = isAvailableMove
                      ? _pulseAnimationController.value
                      : 0.0;

                  return Container(
                    width: cellSize,
                    height: cellSize,
                    decoration: BoxDecoration(
                      gradient: isBlackCell
                          ? (isSelected
                              ? LinearGradient(
                                  colors: [
                                    const Color(0xFF00f5ff),
                                    const Color(0xFF00a8ff),
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    const Color(0xFF1a1a1a),
                                    const Color(0xFF2d2d2d),
                                  ],
                                ))
                          : LinearGradient(
                              colors: [
                                const Color(0xFF3a3a3a),
                                const Color(0xFF4d4d4d),
                              ],
                            ),
                      border: isAvailableMove
                          ? Border.all(
                              color: Color.lerp(
                                const Color(0xFF00ff88),
                                const Color(0xFF00ffff),
                                pulse,
                              )!,
                              width: 3 + pulse * 2,
                            )
                          : null,
                      boxShadow: isAvailableMove
                          ? [
                              BoxShadow(
                                color: Color.lerp(
                                  const Color(0xFF00ff88),
                                  const Color(0xFF00ffff),
                                  pulse,
                                )!.withValues(alpha: 0.6 + pulse * 0.3),
                                blurRadius: 15 + pulse * 10,
                                spreadRadius: 2 + pulse * 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isAvailableMove
                        ? Center(
                            child: Container(
                              width: cellSize * (0.3 + pulse * 0.1),
                              height: cellSize * (0.3 + pulse * 0.1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Color.lerp(
                                      const Color(0xFF00ff88),
                                      const Color(0xFF00ffff),
                                      pulse,
                                    )!.withValues(alpha: 0.9),
                                    Color.lerp(
                                      const Color(0xFF00ff88),
                                      const Color(0xFF00ffff),
                                      pulse,
                                    )!.withValues(alpha: 0.3),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color.lerp(
                                      const Color(0xFF00ff88),
                                      const Color(0xFF00ffff),
                                      pulse,
                                    )!.withValues(alpha: 0.8),
                                    blurRadius: 15 + pulse * 5,
                                    spreadRadius: 1 + pulse,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : null,
                  );
                },
              ),
            );
          }),
        );
      }),
    );
  }

  List<Widget> _buildPieces(double cellSize) {
    final pieces = <Widget>[];

    for (final piece in _gameState.board.values) {
      // Пропускаем анимируемую шашку
      if (_animatingFrom == piece.position) {
        continue;
      }

      pieces.add(_buildPiece(piece, cellSize));
    }

    // Добавляем анимируемую шашку
    if (_animatingFrom != null && _animatingTo != null) {
      final animatingPiece = _gameState.board[_animatingFrom];
      if (animatingPiece != null) {
        pieces.add(_buildAnimatedPiece(animatingPiece, cellSize));
      }
    }

    return pieces;
  }

  Widget _buildPiece(Piece piece, double cellSize) {
    final canMove = _gameState.currentPlayer == piece.color &&
                    _gameState.winner == null;
    final isSelected = _gameState.selectedPosition == piece.position;

    return Positioned(
      left: piece.position.col * cellSize,
      top: piece.position.row * cellSize,
      child: GestureDetector(
        onTap: canMove ? () => _handleCellTap(piece.position) : null,
        child: AnimatedScale(
          scale: isSelected ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: _buildPieceVisual(piece, cellSize, isSelected: isSelected),
        ),
      ),
    );
  }

  Widget _buildPieceVisual(Piece piece, double cellSize, {bool isSelected = false, bool isAnimating = false}) {
    return Container(
      width: cellSize,
      height: cellSize,
      padding: EdgeInsets.all(cellSize * 0.1),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.4, -0.4),
            radius: 0.9,
            colors: piece.color == PieceColor.white
                ? [
                    Colors.white,
                    const Color(0xFFf5f5f5),
                    const Color(0xFFe0e0e0),
                    const Color(0xFFbdbdbd),
                  ]
                : [
                    const Color(0xFF424242),
                    const Color(0xFF2d2d2d),
                    const Color(0xFF1a1a1a),
                    Colors.black,
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isAnimating ? 0.8 : 0.6),
              blurRadius: isAnimating ? 25 : 15,
              offset: Offset(0, isAnimating ? 10 : 6),
            ),
            if (isSelected || isAnimating)
              BoxShadow(
                color: const Color(0xFF00f5ff).withValues(alpha: 0.8),
                blurRadius: 30,
                spreadRadius: 3,
              ),
          ],
          border: Border.all(
            color: piece.color == PieceColor.white
                ? Colors.white.withValues(alpha: 0.5)
                : const Color(0xFF555555),
            width: 3,
          ),
        ),
        child: piece.isKing
            ? Center(
                child: Icon(
                  Icons.auto_awesome,
                  color: const Color(0xFFffd700),
                  size: cellSize * 0.5,
                  shadows: [
                    Shadow(
                      color: const Color(0xFFff8800).withValues(alpha: 0.8),
                      blurRadius: 15,
                    ),
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildAnimatedPiece(Piece piece, double cellSize) {
    return AnimatedBuilder(
      animation: _moveAnimationController,
      builder: (context, child) {
        // Используем более плавную кривую с bounce эффектом
        final t = Curves.easeOutCubic.transform(_moveAnimationController.value);
        final fromCol = _animatingFrom!.col;
        final fromRow = _animatingFrom!.row;
        final toCol = _animatingTo!.col;
        final toRow = _animatingTo!.row;

        final currentCol = fromCol + (toCol - fromCol) * t;
        final currentRow = fromRow + (toRow - fromRow) * t;

        // Добавляем небольшой подъем в середине движения (параболическая траектория)
        final lift = (1 - (2 * t - 1) * (2 * t - 1)) * 0.3;

        return Positioned(
          left: currentCol * cellSize,
          top: currentRow * cellSize - lift * cellSize,
          child: Transform.scale(
            scale: 1.0 + lift * 0.3,
            child: _buildPieceVisual(piece, cellSize, isAnimating: true),
          ),
        );
      },
    );
  }

  Widget _buildWinnerOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.9),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF00f5ff),
                  const Color(0xFF00a8ff),
                  const Color(0xFF0066ff),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00f5ff).withValues(alpha: 0.8),
                  blurRadius: 50,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFffd700),
                    size: 80,
                    shadows: [
                      Shadow(
                        color: Color(0xFFff8800),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'ПОБЕДА!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        blurRadius: 15,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Победили ${_gameState.winner}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 36),
                ElevatedButton(
                  onPressed: _resetGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0066ff),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 56,
                      vertical: 22,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 15,
                    shadowColor: Colors.white.withValues(alpha: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.refresh_rounded, size: 32),
                      SizedBox(width: 14),
                      Text(
                        'Новая игра',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
