import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/cards/card.dart';
import '../../../domain/enums/rank.dart';
import '../../../domain/enums/suit.dart';

class CardFace extends StatelessWidget {
  final PlayingCard card;

  const CardFace({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CardFacePainter(card),
    );
  }
}

class _CardFacePainter extends CustomPainter {
  final PlayingCard card;

  _CardFacePainter(this.card);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.shortestSide * 0.08);
    final rrect = RRect.fromRectAndRadius(rect, radius);

    final backgroundPaint = Paint()..color = const Color(0xFFFDFCF9);
    final borderPaint = Paint()
      ..color = const Color(0xFF3D3A36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.035;

    canvas.drawRRect(rrect, backgroundPaint);
    canvas.drawRRect(rrect, borderPaint);

    if (card.isJoker) {
      _drawJoker(canvas, size);
      return;
    }

    final suitColor = _suitColor(card);
    final cornerInset = size.shortestSide * 0.08;
    final cornerSize = Size(size.width * 0.2, size.height * 0.2);

    _drawRankCorner(
      canvas,
      Offset(cornerInset, cornerInset),
      cornerSize,
      suitColor,
    );

    canvas.save();
    canvas.translate(size.width, size.height);
    canvas.rotate(math.pi);
    _drawRankCorner(
      canvas,
      Offset(cornerInset, cornerInset),
      cornerSize,
      suitColor,
    );
    canvas.restore();

    final centerSize = Size(size.width * 0.46, size.height * 0.46);
    final centerOffset = Offset(
      (size.width - centerSize.width) / 2,
      (size.height - centerSize.height) / 2,
    );
    _drawSuitIcon(canvas, Rect.fromLTWH(centerOffset.dx, centerOffset.dy, centerSize.width, centerSize.height), suitColor);
  }

  void _drawJoker(Canvas canvas, Size size) {
    final isBig = card.rank == Rank.bigJoker;
    final color = isBig ? const Color(0xFFD4433C) : const Color(0xFF2F2D2B);
    final label = isBig ? 'JOKER' : 'Joker';

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: size.shortestSide * 0.2,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);

    final offset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );
    textPainter.paint(canvas, offset);
  }

  void _drawRankCorner(
    Canvas canvas,
    Offset offset,
    Size size,
    Color color,
  ) {
    final rankText = _rankLabel(card.rank);
    final rankPainter = TextPainter(
      text: TextSpan(
        text: rankText,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: size.height * 0.52,
        ),
      ),
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);

    rankPainter.paint(canvas, offset);

    final suitRect = Rect.fromLTWH(
      offset.dx,
      offset.dy + size.height * 0.5,
      size.width,
      size.height * 0.5,
    );
    _drawSuitIcon(canvas, suitRect, color);
  }

  void _drawSuitIcon(Canvas canvas, Rect rect, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (card.suit) {
      case Suit.heart:
        canvas.drawPath(_heartPath(rect), paint);
        break;
      case Suit.diamond:
        canvas.drawPath(_diamondPath(rect), paint);
        break;
      case Suit.spade:
        canvas.drawPath(_spadePath(rect), paint);
        break;
      case Suit.club:
        canvas.drawPath(_clubPath(rect), paint);
        break;
      case Suit.joker:
        break;
    }
  }

  Path _diamondPath(Rect rect) {
    return Path()
      ..moveTo(rect.center.dx, rect.top)
      ..lineTo(rect.right, rect.center.dy)
      ..lineTo(rect.center.dx, rect.bottom)
      ..lineTo(rect.left, rect.center.dy)
      ..close();
  }

  Path _heartPath(Rect rect) {
    final path = Path();
    final w = rect.width;
    final h = rect.height;
    final x = rect.left;
    final y = rect.top;

    path.moveTo(x + w / 2, y + h);
    path.cubicTo(x + w * 1.05, y + h * 0.7, x + w * 0.9, y + h * 0.15, x + w / 2, y + h * 0.35);
    path.cubicTo(x + w * 0.1, y + h * 0.15, x - w * 0.05, y + h * 0.7, x + w / 2, y + h);
    path.close();
    return path;
  }

  Path _spadePath(Rect rect) {
    final path = Path();
    final w = rect.width;
    final h = rect.height;
    final x = rect.left;
    final y = rect.top;

    path.moveTo(x + w / 2, y);
    path.cubicTo(x + w * 1.05, y + h * 0.35, x + w * 0.9, y + h * 0.85, x + w / 2, y + h * 0.65);
    path.cubicTo(x + w * 0.1, y + h * 0.85, x - w * 0.05, y + h * 0.35, x + w / 2, y);
    path.close();

    final stem = Rect.fromLTWH(x + w * 0.42, y + h * 0.6, w * 0.16, h * 0.35);
    path.addRect(stem);

    return path;
  }

  Path _clubPath(Rect rect) {
    final path = Path();
    final w = rect.width;
    final h = rect.height;
    final x = rect.left;
    final y = rect.top;

    final circleRadius = w * 0.22;
    final topCenter = Offset(x + w / 2, y + h * 0.3);
    final leftCenter = Offset(x + w * 0.28, y + h * 0.55);
    final rightCenter = Offset(x + w * 0.72, y + h * 0.55);

    path.addOval(Rect.fromCircle(center: topCenter, radius: circleRadius));
    path.addOval(Rect.fromCircle(center: leftCenter, radius: circleRadius));
    path.addOval(Rect.fromCircle(center: rightCenter, radius: circleRadius));

    final stem = Rect.fromLTWH(x + w * 0.45, y + h * 0.55, w * 0.1, h * 0.35);
    path.addRect(stem);

    return path;
  }

  Color _suitColor(PlayingCard card) {
    switch (card.suit) {
      case Suit.heart:
      case Suit.diamond:
        return const Color(0xFFD4433C);
      case Suit.spade:
      case Suit.club:
        return const Color(0xFF2F2D2B);
      case Suit.joker:
        return card.rank == Rank.bigJoker ? const Color(0xFFD4433C) : const Color(0xFF2F2D2B);
    }
  }

  String _rankLabel(Rank rank) {
    switch (rank) {
      case Rank.ace:
        return 'A';
      case Rank.king:
        return 'K';
      case Rank.queen:
        return 'Q';
      case Rank.jack:
        return 'J';
      case Rank.ten:
        return '10';
      case Rank.nine:
        return '9';
      case Rank.eight:
        return '8';
      case Rank.seven:
        return '7';
      case Rank.six:
        return '6';
      case Rank.five:
        return '5';
      case Rank.four:
        return '4';
      case Rank.three:
        return '3';
      case Rank.two:
        return '2';
      case Rank.smallJoker:
        return 'JK';
      case Rank.bigJoker:
        return 'JK';
    }
  }

  @override
  bool shouldRepaint(covariant _CardFacePainter oldDelegate) {
    return oldDelegate.card != card;
  }
}
