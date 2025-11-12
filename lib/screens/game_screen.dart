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
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
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
        orElse: () => Move(from: position, to: position),
      );

      if (move.from == _gameState.selectedPosition) {
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
      backgroundColor: const Color(0xFF2C3E50),
      appBar: AppBar(
        title: const Text('Русские шашки', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF34495E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
            tooltip: 'Новая игра',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              _buildPlayerIndicator(),
              const SizedBox(height: 20),
              _buildBoard(),
              const SizedBox(height: 20),
              _buildScoreBoard(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF34495E),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _gameState.currentPlayer == PieceColor.white
                  ? Colors.white
                  : Colors.black,
              border: Border.all(color: Colors.grey.shade700, width: 2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _gameState.currentPlayer == PieceColor.white
                ? 'Ход белых'
                : 'Ход чёрных',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF34495E),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildScoreItem('Белые', _gameState.whiteCaptures, Colors.white),
          const SizedBox(width: 40),
          _buildScoreItem('Чёрные', _gameState.blackCaptures, Colors.black),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: Colors.grey.shade700, width: 1.5),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'x $count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBoard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final rawBoardSize = screenWidth > 600 ? 600.0 : screenWidth * 0.95;
    const borderWidth = 4.0;
    // Делаем внутренний размер кратным 8 для избежания overflow
    final innerSize = ((rawBoardSize - borderWidth * 2) ~/ 8) * 8.0;
    final boardSize = innerSize + borderWidth * 2;
    final cellSize = innerSize / 8;

    return Container(
      width: boardSize,
      height: boardSize,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF34495E), width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Клетки доски
          Column(
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
                    child: Container(
                      width: cellSize,
                      height: cellSize,
                      decoration: BoxDecoration(
                        color: isBlackCell
                            ? (isSelected
                                ? const Color(0xFF3498DB)
                                : const Color(0xFF8B4513))
                            : const Color(0xFFDEB887),
                        border: isAvailableMove
                            ? Border.all(color: Colors.green, width: 3)
                            : null,
                      ),
                      child: isAvailableMove
                          ? Center(
                              child: Container(
                                width: cellSize * 0.3,
                                height: cellSize * 0.3,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green.withValues(alpha: 0.5),
                                ),
                              ),
                            )
                          : null,
                    ),
                  );
                }),
              );
            }),
          ),
          // Шашки
          ..._buildPieces(cellSize),
          // Показываем winner dialog
          if (_gameState.winner != null) _buildWinnerOverlay(),
        ],
      ),
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
    return Positioned(
      left: piece.position.col * cellSize,
      top: piece.position.row * cellSize,
      child: Container(
        width: cellSize,
        height: cellSize,
        padding: EdgeInsets.all(cellSize * 0.1),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: piece.color == PieceColor.white ? Colors.white : Colors.black,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.grey.shade700,
              width: 2,
            ),
          ),
          child: piece.isKing
              ? Center(
                  child: Icon(
                    Icons.auto_awesome,
                    color: piece.color == PieceColor.white
                        ? Colors.amber
                        : Colors.amber.shade200,
                    size: cellSize * 0.5,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildAnimatedPiece(Piece piece, double cellSize) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final t = _animationController.value;
        final fromCol = _animatingFrom!.col;
        final fromRow = _animatingFrom!.row;
        final toCol = _animatingTo!.col;
        final toRow = _animatingTo!.row;

        final currentCol = fromCol + (toCol - fromCol) * t;
        final currentRow = fromRow + (toRow - fromRow) * t;

        return Positioned(
          left: currentCol * cellSize,
          top: currentRow * cellSize,
          child: Container(
            width: cellSize,
            height: cellSize,
            padding: EdgeInsets.all(cellSize * 0.1),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: piece.color == PieceColor.white ? Colors.white : Colors.black,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.grey.shade700,
                  width: 2,
                ),
              ),
              child: piece.isKing
                  ? Center(
                      child: Icon(
                        Icons.auto_awesome,
                        color: piece.color == PieceColor.white
                            ? Colors.amber
                            : Colors.amber.shade200,
                        size: cellSize * 0.5,
                      ),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildWinnerOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF34495E),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Победили ${_gameState.winner}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _resetGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3498DB),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'Новая игра',
                    style: TextStyle(fontSize: 18),
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
