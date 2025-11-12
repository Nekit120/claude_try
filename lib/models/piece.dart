import 'position.dart';

enum PieceColor { white, black }

class Piece {
  final PieceColor color;
  final Position position;
  final bool isKing;

  const Piece({
    required this.color,
    required this.position,
    this.isKing = false,
  });

  Piece copyWith({
    PieceColor? color,
    Position? position,
    bool? isKing,
  }) {
    return Piece(
      color: color ?? this.color,
      position: position ?? this.position,
      isKing: isKing ?? this.isKing,
    );
  }

  @override
  String toString() =>
      'Piece(${color.name}, $position, ${isKing ? "King" : "Regular"})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Piece &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          position == other.position &&
          isKing == other.isKing;

  @override
  int get hashCode => color.hashCode ^ position.hashCode ^ isKing.hashCode;
}
