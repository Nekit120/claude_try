import '../models/piece.dart';
import '../models/position.dart';
import '../models/move.dart';
import 'game_state.dart';

class GameLogic {
  // Направления для обычных шашек (белые идут вверх, чёрные вниз)
  static List<Position> _getForwardDirections(PieceColor color) {
    if (color == PieceColor.white) {
      return [
        const Position(1, -1), // вверх-влево
        const Position(1, 1), // вверх-вправо
      ];
    } else {
      return [
        const Position(-1, -1), // вниз-влево
        const Position(-1, 1), // вниз-вправо
      ];
    }
  }

  // Все диагональные направления для дамок и для взятия
  static const List<Position> _allDirections = [
    Position(-1, -1), // вверх-влево
    Position(-1, 1), // вверх-вправо
    Position(1, -1), // вниз-влево
    Position(1, 1), // вниз-вправо
  ];

  // Получить все возможные ходы для текущего игрока
  static List<Move> getAllPossibleMoves(GameState state) {
    final pieces = state.getPiecesForPlayer(state.currentPlayer);
    final allMoves = <Move>[];

    for (final piece in pieces) {
      allMoves.addAll(getPossibleMovesForPiece(state, piece));
    }

    // Проверяем обязательное взятие - если есть ходы с захватом, оставляем только их
    final captureMoves = allMoves.where((move) => move.isCapture).toList();
    if (captureMoves.isNotEmpty) {
      return captureMoves;
    }

    return allMoves;
  }

  // Получить возможные ходы для конкретной шашки
  static List<Move> getPossibleMovesForPiece(GameState state, Piece piece) {
    final moves = <Move>[];

    // Сначала проверяем ходы с захватом
    final captureMoves = _getCaptureMoves(state, piece, []);
    moves.addAll(captureMoves);

    // Если нет ходов с захватом, проверяем обычные ходы
    if (captureMoves.isEmpty) {
      moves.addAll(_getSimpleMoves(state, piece));
    }

    return moves;
  }

  // Получить обычные ходы (без захвата)
  static List<Move> _getSimpleMoves(GameState state, Piece piece) {
    final moves = <Move>[];
    final directions =
        piece.isKing ? _allDirections : _getForwardDirections(piece.color);

    for (final dir in directions) {
      final newPos = Position(
        piece.position.row + dir.row,
        piece.position.col + dir.col,
      );

      if (state.isValidPosition(newPos) && state.getPieceAt(newPos) == null) {
        final makesKing = _shouldBecomeKing(piece, newPos);
        moves.add(Move(
          from: piece.position,
          to: newPos,
          makesKing: makesKing,
        ));
      }
    }

    return moves;
  }

  // Получить ходы с захватом (с рекурсией для множественного захвата)
  static List<Move> _getCaptureMoves(
    GameState state,
    Piece piece,
    List<Position> alreadyCaptured,
  ) {
    final moves = <Move>[];

    for (final dir in _allDirections) {
      final enemyPos = Position(
        piece.position.row + dir.row,
        piece.position.col + dir.col,
      );
      final landPos = Position(
        piece.position.row + dir.row * 2,
        piece.position.col + dir.col * 2,
      );

      if (!state.isValidPosition(enemyPos) || !state.isValidPosition(landPos)) {
        continue;
      }

      final enemyPiece = state.getPieceAt(enemyPos);
      final landPiece = state.getPieceAt(landPos);

      // Проверяем, можем ли мы захватить
      if (enemyPiece != null &&
          enemyPiece.color != piece.color &&
          !alreadyCaptured.contains(enemyPos) &&
          landPiece == null) {
        final newCaptured = [...alreadyCaptured, enemyPos];
        final makesKing = _shouldBecomeKing(piece, landPos);

        // Создаём временное состояние для проверки продолжения захвата
        final tempPiece = piece.copyWith(
          position: landPos,
          isKing: piece.isKing || makesKing,
        );

        // Проверяем, можем ли продолжить захват
        final furtherCaptures = _getCaptureMoves(state, tempPiece, newCaptured);

        if (furtherCaptures.isEmpty) {
          // Это конечный ход
          moves.add(Move(
            from: piece.position,
            to: landPos,
            capturedPositions: newCaptured,
            makesKing: makesKing,
          ));
        } else {
          // Добавляем все продолжения
          for (final further in furtherCaptures) {
            moves.add(Move(
              from: piece.position,
              to: further.to,
              capturedPositions: further.capturedPositions,
              makesKing: further.makesKing,
            ));
          }
        }
      }
    }

    return moves;
  }

  // Проверить, должна ли шашка стать дамкой
  static bool _shouldBecomeKing(Piece piece, Position newPos) {
    if (piece.isKing) return false;

    if (piece.color == PieceColor.white && newPos.row == 7) {
      return true;
    }
    if (piece.color == PieceColor.black && newPos.row == 0) {
      return true;
    }

    return false;
  }

  // Выполнить ход
  static GameState makeMove(GameState state, Move move) {
    final newBoard = Map<Position, Piece>.from(state.board);
    final piece = newBoard[move.from]!;

    // Убираем шашку с исходной позиции
    newBoard.remove(move.from);

    // Убираем захваченные шашки
    for (final capturedPos in move.capturedPositions) {
      newBoard.remove(capturedPos);
    }

    // Ставим шашку на новую позицию
    final newPiece = piece.copyWith(
      position: move.to,
      isKing: piece.isKing || move.makesKing,
    );
    newBoard[move.to] = newPiece;

    // Обновляем счётчики захватов
    final newWhiteCaptures = state.whiteCaptures +
        (piece.color == PieceColor.white ? move.capturedPositions.length : 0);
    final newBlackCaptures = state.blackCaptures +
        (piece.color == PieceColor.black ? move.capturedPositions.length : 0);

    // Меняем игрока
    final nextPlayer = state.currentPlayer == PieceColor.white
        ? PieceColor.black
        : PieceColor.white;

    final newState = state.copyWith(
      board: newBoard,
      currentPlayer: nextPlayer,
      whiteCaptures: newWhiteCaptures,
      blackCaptures: newBlackCaptures,
      clearSelectedPosition: true,
      availableMoves: [],
    );

    // Проверяем победу
    return _checkWinner(newState);
  }

  // Проверить победителя
  static GameState _checkWinner(GameState state) {
    final whitePieces = state.getPiecesForPlayer(PieceColor.white);
    final blackPieces = state.getPiecesForPlayer(PieceColor.black);

    if (whitePieces.isEmpty) {
      return state.copyWith(winner: 'Чёрные');
    }
    if (blackPieces.isEmpty) {
      return state.copyWith(winner: 'Белые');
    }

    // Проверяем, есть ли доступные ходы
    final availableMoves = getAllPossibleMoves(state);
    if (availableMoves.isEmpty) {
      final winner = state.currentPlayer == PieceColor.white ? 'Чёрные' : 'Белые';
      return state.copyWith(winner: winner);
    }

    return state;
  }

  // Выбрать шашку
  static GameState selectPiece(GameState state, Position position) {
    final piece = state.getPieceAt(position);

    if (piece == null || piece.color != state.currentPlayer) {
      return state.copyWith(
        clearSelectedPosition: true,
        availableMoves: [],
      );
    }

    final moves = getPossibleMovesForPiece(state, piece);

    // Проверяем обязательное взятие
    final allMoves = getAllPossibleMoves(state);
    final hasCaptures = allMoves.any((m) => m.isCapture);
    final pieceHasCaptures = moves.any((m) => m.isCapture);

    // Если есть обязательные взятия, но у этой шашки их нет - не выбираем
    if (hasCaptures && !pieceHasCaptures) {
      return state.copyWith(
        clearSelectedPosition: true,
        availableMoves: [],
      );
    }

    return state.copyWith(
      selectedPosition: position,
      availableMoves: moves,
    );
  }
}
