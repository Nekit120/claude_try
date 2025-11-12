import 'position.dart';

class Move {
  final Position from;
  final Position to;
  final List<Position> capturedPositions;
  final bool makesKing;

  const Move({
    required this.from,
    required this.to,
    this.capturedPositions = const [],
    this.makesKing = false,
  });

  bool get isCapture => capturedPositions.isNotEmpty;

  @override
  String toString() =>
      'Move($from -> $to${isCapture ? " captures ${capturedPositions.length}" : ""})';
}
