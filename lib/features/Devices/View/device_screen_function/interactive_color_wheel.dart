// lib/features/Devices/View/device_screen_function/interactive_color_wheel.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:led_control_app/features/Devices/Logic/light_controller.dart';
import 'package:led_control_app/features/Devices/View/device_screen_function/rgb_value_table.dart';

class InteractiveColorWheel extends StatefulWidget {
  final double brightness;
  final ValueChanged<Color> onColorChanged;

  const InteractiveColorWheel({
    super.key,
    required this.brightness,
    required this.onColorChanged,
  });

  @override
  State<InteractiveColorWheel> createState() => InteractiveColorWheelState();
}

class InteractiveColorWheelState extends State<InteractiveColorWheel> {
  double _angle = 0;
  Offset _center = Offset.zero;
  double _radius = 0;

  @override
  void didUpdateWidget(covariant InteractiveColorWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.brightness != widget.brightness) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendCurrentColor();
      });
    }
  }

  void setColorFromOutside(Color newColor) {
    setState(() {
      final hsl = HSLColor.fromColor(newColor);
      const hueOffset = 115;
      final angle = ((hsl.hue - hueOffset + 360) % 360) * pi / 180;
      _angle = angle;
    });
    _sendCurrentColor();
  }

  void _sendCurrentColor() {
    final baseColor = _hueToColor(_angle);
    final adjustedColor = _applyBrightness(baseColor);

    widget.onColorChanged(adjustedColor);
    LightController.updateLocalColor(
      adjustedColor.red,
      adjustedColor.green,
      adjustedColor.blue,
    );
  }

  void _updateAngle(Offset globalPosition) {
    RenderBox box = context.findRenderObject() as RenderBox;
    final local = box.globalToLocal(globalPosition);
    final dx = local.dx - _center.dx;
    final dy = local.dy - _center.dy;
    setState(() => _angle = atan2(dy, dx));
    _sendCurrentColor();
  }

  Color _hueToColor(double angle) {
    const hueOffset = 115;
    final hue = ((angle * 180 / pi) + hueOffset) % 360;
    return HSLColor.fromAHSL(1.0, hue, 1.0, 0.5).toColor();
  }

  Color _applyBrightness(Color c) {
    return Color.fromARGB(
      255,
      (c.red * widget.brightness).clamp(0, 255).toInt(),
      (c.green * widget.brightness).clamp(0, 255).toInt(),
      (c.blue * widget.brightness).clamp(0, 255).toInt(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => _updateAngle(d.globalPosition),
      onPanUpdate: (d) => _updateAngle(d.globalPosition),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = min(constraints.maxWidth, constraints.maxHeight);
          _center = Offset(size / 2, size / 2);
          _radius = size / 2;

          final currentColor = _hueToColor(_angle);
          final adjusted = _applyBrightness(currentColor);

          final r = adjusted.red;
          final g = adjusted.green;
          final b = adjusted.blue;

          return SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset('assets/color_wheel.png', width: size, height: size),

                CustomPaint(
                  size: Size(size, size),
                  painter: ArcPainter(
                    angle: _angle,
                    radius: _radius - 33,
                    color: adjusted,
                  ),
                ),

                Container(
                  width: size * 0.32,
                  height: size * 0.32,
                  decoration: BoxDecoration(
                    color: adjusted,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),

                Positioned(
                  left: _center.dx + (_radius - 33) * cos(_angle) - 8,
                  top: _center.dy + (_radius - 33) * sin(_angle) - 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: adjusted,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

              ],
            ),
          );
        },
      ),
    );
  }
}

class ArcPainter extends CustomPainter {
  final double angle;
  final double radius;
  final Color color;

  ArcPainter({required this.angle, required this.radius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const steps = 100;
    const sweep = 1.5;

    for (int i = 0; i < steps; i++) {
      final t = 1 - (i / steps);
      final currentAngle = angle - sweep * (1 - t);
      final paint = Paint()
        ..color = color.withOpacity(1.0)
        ..strokeWidth = 6 * t
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final start = Offset(
        center.dx + radius * cos(currentAngle),
        center.dy + radius * sin(currentAngle),
      );
      final end = Offset(
        center.dx + radius * cos(currentAngle + 0.015),
        center.dy + radius * sin(currentAngle + 0.015),
      );

      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ArcPainter old) =>
      old.angle != angle || old.color != color;
}
