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

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late GameState _gameState;
  late AnimationController _animationController;
  Position? _animatingFrom;
  Position? _animatingTo;

  @override
  void initState() {
    super.initState();
    _gameState = GameState.initial();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDragStart(Position position) {
    if (_gameState.winner != null) return;

    setState(() {
      _gameState = GameLogic.selectPiece(_gameState, position);
    });
  }

  void _handleDragEnd(Position from, Position to) {
    if (_gameState.winner != null) return;

    final move = _gameState.availableMoves.firstWhere(
      (m) => m.from == from && m.to == to,
      orElse: () => Move(from: Position(-1, -1), to: Position(-1, -1)),
    );

    if (move.from.row != -1) {
      // Делаем ход с анимацией
      _animatingFrom = move.from;
      _animatingTo = move.to;
      _animationController.forward(from: 0).then((_) {
        setState(() {
          _gameState = GameLogic.makeMove(_gameState, move);
          _animatingFrom = null;
          _animatingTo = null;
        });
      });
    } else {
      setState(() {
        _gameState = _gameState.copyWith(
          clearSelectedPosition: true,
          availableMoves: [],
        );
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
              const Color(0xFF1a1a2e),
              const Color(0xFF16213e),
              const Color(0xFF0f3460),
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
          Icon(
            Icons.circle,
            color: Colors.white.withValues(alpha: 0.9),
            size: 16,
          ),
          const SizedBox(width: 12),
          const Text(
            'Русские шашки',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.circle,
            color: Colors.black.withValues(alpha: 0.9),
            size: 16,
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
            const Color(0xFF00d2ff),
            const Color(0xFF3a7bd5),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00d2ff).withValues(alpha: 0.5),
            blurRadius: 20,
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
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
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
              letterSpacing: 0.5,
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
            const Color(0xFF2C3E50).withValues(alpha: 0.9),
            const Color(0xFF34495E).withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
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
                  Colors.white.withValues(alpha: 0.3),
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
            color: Colors.white.withValues(alpha: 0.7),
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
                border: Border.all(color: Colors.white54, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
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
                  const Color(0xFFff6b6b),
                  const Color(0xFFee5a6f),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFff6b6b).withValues(alpha: 0.5),
                  blurRadius: 20,
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
    const borderWidth = 6.0;
    final innerSize = ((rawBoardSize - borderWidth * 2) ~/ 8) * 8.0;
    final boardSize = innerSize + borderWidth * 2;
    final cellSize = innerSize / 8;

    return Container(
      width: boardSize,
      height: boardSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00d2ff),
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00d2ff).withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 20,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
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

            return DragTarget<Position>(
              onWillAcceptWithDetails: (details) {
                return isAvailableMove;
              },
              onAcceptWithDetails: (details) {
                _handleDragEnd(details.data, position);
              },
              builder: (context, candidateData, rejectedData) {
                final isHovered = candidateData.isNotEmpty;

                return Container(
                  width: cellSize,
                  height: cellSize,
                  decoration: BoxDecoration(
                    gradient: isBlackCell
                        ? (isSelected
                            ? LinearGradient(
                                colors: [
                                  const Color(0xFF00d2ff),
                                  const Color(0xFF3a7bd5),
                                ],
                              )
                            : LinearGradient(
                                colors: [
                                  const Color(0xFF654321),
                                  const Color(0xFF8B4513),
                                ],
                              ))
                        : LinearGradient(
                            colors: [
                              const Color(0xFFf5deb3),
                              const Color(0xFFdeb887),
                            ],
                          ),
                    border: isAvailableMove
                        ? Border.all(
                            color: isHovered
                                ? const Color(0xFF00ff88)
                                : const Color(0xFF00ff88).withValues(alpha: 0.6),
                            width: isHovered ? 4 : 3,
                          )
                        : null,
                    boxShadow: isAvailableMove && isHovered
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00ff88).withValues(alpha: 0.5),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isAvailableMove
                      ? Center(
                          child: Container(
                            width: cellSize * 0.35,
                            height: cellSize * 0.35,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF00ff88).withValues(alpha: 0.8),
                                  const Color(0xFF00ff88).withValues(alpha: 0.3),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00ff88).withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        )
                      : null,
                );
              },
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

    return Positioned(
      left: piece.position.col * cellSize,
      top: piece.position.row * cellSize,
      child: canMove
          ? Draggable<Position>(
              data: piece.position,
              onDragStarted: () => _handleDragStart(piece.position),
              onDragEnd: (details) {
                if (!details.wasAccepted) {
                  setState(() {
                    _gameState = _gameState.copyWith(
                      clearSelectedPosition: true,
                      availableMoves: [],
                    );
                  });
                }
              },
              feedback: _buildPieceVisual(piece, cellSize, isDragging: true),
              childWhenDragging: SizedBox(
                width: cellSize,
                height: cellSize,
              ),
              child: _buildPieceVisual(piece, cellSize),
            )
          : _buildPieceVisual(piece, cellSize),
    );
  }

  Widget _buildPieceVisual(Piece piece, double cellSize, {bool isDragging = false}) {
    return Container(
      width: cellSize,
      height: cellSize,
      padding: EdgeInsets.all(cellSize * 0.12),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.3),
            radius: 0.8,
            colors: piece.color == PieceColor.white
                ? [
                    Colors.white,
                    const Color(0xFFf0f0f0),
                    const Color(0xFFd0d0d0),
                  ]
                : [
                    const Color(0xFF2d2d2d),
                    const Color(0xFF1a1a1a),
                    Colors.black,
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDragging ? 0.7 : 0.5),
              blurRadius: isDragging ? 20 : 12,
              offset: Offset(0, isDragging ? 8 : 6),
            ),
            if (isDragging)
              BoxShadow(
                color: (piece.color == PieceColor.white
                    ? Colors.white
                    : Colors.black).withValues(alpha: 0.5),
                blurRadius: 25,
                spreadRadius: 2,
              ),
          ],
          border: Border.all(
            color: piece.color == PieceColor.white
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.grey.shade800,
            width: 2,
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
                      color: Colors.black.withValues(alpha: 0.5),
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
      animation: _animationController,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_animationController.value);
        final fromCol = _animatingFrom!.col;
        final fromRow = _animatingFrom!.row;
        final toCol = _animatingTo!.col;
        final toRow = _animatingTo!.row;

        final currentCol = fromCol + (toCol - fromCol) * t;
        final currentRow = fromRow + (toRow - fromRow) * t;

        return Positioned(
          left: currentCol * cellSize,
          top: currentRow * cellSize,
          child: _buildPieceVisual(piece, cellSize, isDragging: true),
        );
      },
    );
  }

  Widget _buildWinnerOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF00d2ff),
                  const Color(0xFF3a7bd5),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00d2ff).withValues(alpha: 0.6),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFffd700),
                    size: 80,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Победа!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Победили ${_gameState.winner}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _resetGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF3a7bd5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.refresh_rounded, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Новая игра',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
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
