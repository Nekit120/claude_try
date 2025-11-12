import '../models/piece.dart';
import '../models/position.dart';
import '../models/move.dart';

class GameState {
  final Map<Position, Piece> board;
  final PieceColor currentPlayer;
  final int whiteCaptures;
  final int blackCaptures;
  final Position? selectedPosition;
  final List<Move> availableMoves;
  final String? winner;

  GameState({
    required this.board,
    required this.currentPlayer,
    this.whiteCaptures = 0,
    this.blackCaptures = 0,
    this.selectedPosition,
    this.availableMoves = const [],
    this.winner,
  });

  factory GameState.initial() {
    final board = <Position, Piece>{};

    // Расставляем белые шашки (внизу)
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 8; col++) {
        if ((row + col) % 2 == 1) {
          final pos = Position(row, col);
          board[pos] = Piece(color: PieceColor.white, position: pos);
        }
      }
    }

    // Расставляем чёрные шашки (вверху)
    for (int row = 5; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        if ((row + col) % 2 == 1) {
          final pos = Position(row, col);
          board[pos] = Piece(color: PieceColor.black, position: pos);
        }
      }
    }

    return GameState(
      board: board,
      currentPlayer: PieceColor.white,
    );
  }

  GameState copyWith({
    Map<Position, Piece>? board,
    PieceColor? currentPlayer,
    int? whiteCaptures,
    int? blackCaptures,
    Position? selectedPosition,
    bool clearSelectedPosition = false,
    List<Move>? availableMoves,
    String? winner,
    bool clearWinner = false,
  }) {
    return GameState(
      board: board ?? Map.from(this.board),
      currentPlayer: currentPlayer ?? this.currentPlayer,
      whiteCaptures: whiteCaptures ?? this.whiteCaptures,
      blackCaptures: blackCaptures ?? this.blackCaptures,
      selectedPosition:
          clearSelectedPosition ? null : (selectedPosition ?? this.selectedPosition),
      availableMoves: availableMoves ?? this.availableMoves,
      winner: clearWinner ? null : (winner ?? this.winner),
    );
  }

  bool isValidPosition(Position pos) {
    return pos.row >= 0 && pos.row < 8 && pos.col >= 0 && pos.col < 8;
  }

  Piece? getPieceAt(Position pos) {
    return board[pos];
  }

  List<Piece> getPiecesForPlayer(PieceColor color) {
    return board.values.where((piece) => piece.color == color).toList();
  }

  bool hasNoPieces(PieceColor color) {
    return !board.values.any((piece) => piece.color == color);
  }
}
