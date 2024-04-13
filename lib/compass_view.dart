import 'dart:math';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CompassView extends StatefulWidget {
  const CompassView({
    Key? key,
    required this.windAngle,
    required this.child,
    this.foregroundColor = Colors.white,
  }) : super(key: key);

  final double windAngle;
  final Color foregroundColor;
  final Widget child;

  @override
  _CompassViewState createState() => _CompassViewState();
}

class _CompassViewState extends State<CompassView> {
  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(150, 150),
            painter: _CompassViewPainter(
              windAngle: widget.windAngle,
              foregroundColor: widget.foregroundColor,
            ),
          ),
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                alignment: Alignment.center,
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.3)),
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassViewPainter extends CustomPainter {
  _CompassViewPainter({
    required this.windAngle,
    required this.foregroundColor,
  });

  final double windAngle;

  final Color foregroundColor;

  final int middleTickCount = 12;
  final int majorTickCount = 4;
  final int minorTickCount = 180;

  final CardinalityMap cardinalities = const {
    0: 'С',
    90: 'В',
    180: 'Ю',
    270: 'З'
  };

  late final bearingIndicatorPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = foregroundColor
    ..strokeWidth = 1
    ..blendMode = BlendMode.srcIn;

  late final middleScalePaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = foregroundColor.withOpacity(0.7)
    ..strokeWidth = 1.0;

  late final minorScalePaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = foregroundColor.withOpacity(0.4)
    ..strokeWidth = 1.0;
  late final majorScalePaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = foregroundColor.withOpacity(1)
    ..strokeWidth = 1.5;

  late final cardinalityStyle = TextStyle(
    color: foregroundColor,
    fontSize: 15,
    fontWeight: FontWeight.bold,
  );

  late final arrowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.white
    ..strokeWidth = 2;

  late final _majorTicks = _layoutScale(majorTickCount);
  late final _middleTicks = _layoutScale(middleTickCount);
  late final _minorTicks = _layoutScale(minorTickCount);

  @override
  void paint(Canvas canvas, Size size) {
    assert(size.width == size.height, 'Size must be square');
    const origin = Offset.zero;
    final center = size.center(origin);
    final radius = size.width / 2;
    const tickLength = 10.0;

    // paint minor scale
    for (final angle in _minorTicks) {
      final tickStart = Offset.fromDirection(
        _correctedAngle(angle).toRadians(),
        radius,
      );

      final tickEnd = Offset.fromDirection(
        _correctedAngle(angle).toRadians(),
        radius - tickLength,
      );

      canvas.drawLine(
        center + tickStart,
        center + tickEnd,
        minorScalePaint,
      );
    }

    // paint middle scale
    for (final angle in _middleTicks) {
      final tickStart = Offset.fromDirection(
        _correctedAngle(angle).toRadians(),
        radius,
      );

      final tickEnd = Offset.fromDirection(
        _correctedAngle(angle).toRadians(),
        radius - tickLength,
      );

      canvas.drawLine(
        center + tickStart,
        center + tickEnd,
        middleScalePaint,
      );
    }
    // paint major scale
    for (final angle in _majorTicks) {
      final tickStart = Offset.fromDirection(
        _correctedAngle(angle).toRadians(),
        radius,
      );

      final tickEnd = Offset.fromDirection(
        _correctedAngle(angle).toRadians(),
        radius - tickLength,
      );

      canvas.drawLine(
        center + tickStart,
        center + tickEnd,
        majorScalePaint,
      );
    }
    //paint bearing
    var path2 = Path();
    path2.moveTo(size.width / 2, 0);
    path2.lineTo(size.width / 2 - 7, tickLength);
    path2.lineTo(size.width / 2 + 7, tickLength);
    path2.close();
    canvas.drawPath(path2, bearingIndicatorPaint);
// paint cardinality text
    for (final cardinality in cardinalities.entries) {
      final angle = cardinality.key.toDouble();
      final text = cardinality.value;

      final textPainter = TextSpan(
        text: text,
        style: cardinalityStyle,
      ).toPainter()
        ..layout();

      final layoutOffset = Offset.fromDirection(
        _correctedAngle(angle).toRadians(),
        radius - 20,
      );

      final offset = center + layoutOffset - textPainter.center;
      textPainter.paint(canvas, offset);
    }
//draw speed direction arrow
    final Offset p1 = center +
        Offset.fromDirection(
          _correctedAngle(windAngle).toRadians(),
          radius - tickLength,
        );
    final Offset p2 = center -
        Offset.fromDirection(
          _correctedAngle(windAngle).toRadians(),
          radius,
        );

    final dX = p2.dx - p1.dx;
    final dY = p2.dy - p1.dy;
    final angle = atan2(dY, dX);
    const arrowSize = tickLength;
    const arrowAngle = 25 * pi / 180;
    canvas.drawLine(p1, p2, arrowPaint);
    canvas.drawCircle(
        center +
            Offset.fromDirection(
              _correctedAngle(windAngle).toRadians(),
              radius - tickLength / 2,
            ),
        5,
        arrowPaint);
    final path = Path();

    path.moveTo(p2.dx - arrowSize * cos(angle - arrowAngle),
        p2.dy - arrowSize * sin(angle - arrowAngle));
    path.lineTo(p2.dx, p2.dy);
    path.lineTo(p2.dx - arrowSize * cos(angle + arrowAngle),
        p2.dy - arrowSize * sin(angle + arrowAngle));
    path.close();
    canvas.drawPath(
      path,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_CompassViewPainter oldDelegate) =>
      oldDelegate.windAngle != windAngle ||
      oldDelegate.foregroundColor != foregroundColor ||
      oldDelegate.middleTickCount != middleTickCount ||
      oldDelegate.minorTickCount != minorTickCount;

  List<double> _layoutScale(int ticks) {
    final scale = 360 / ticks;

    return List.generate(ticks, (i) => i * scale);
  }

  double _correctedAngle(double angle) => angle - 90;
}

typedef CardinalityMap = Map<num, String>;

extension on TextPainter {
  Offset get center => size.center(Offset.zero);
}

extension on TextSpan {
  TextPainter toPainter({TextDirection textDirection = TextDirection.ltr}) =>
      TextPainter(text: this, textDirection: textDirection);
}

extension on num {
  double toRadians() => this * pi / 180;
}
