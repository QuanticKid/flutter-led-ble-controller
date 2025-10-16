// lib/features/Devices/View/device_screen_function/color_spectrum_picker.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:led_control_app/features/Devices/View/device_screen_function/rgb_value_table.dart';

class ColorSpectrumPicker extends StatefulWidget {
  final Color color;
  final double brightness;
  final ValueChanged<Color> onColorChanged;

  const ColorSpectrumPicker({
    Key? key,
    required this.color,
    required this.brightness,
    required this.onColorChanged,
  }) : super(key: key);

  @override
  _ColorSpectrumPickerState createState() => _ColorSpectrumPickerState();
}

class _ColorSpectrumPickerState extends State<ColorSpectrumPicker> {
  late double _hue;
  late double _saturation;

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.color);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
  }

  @override
  void didUpdateWidget(covariant ColorSpectrumPicker old) {
    super.didUpdateWidget(old);
    if (old.color != widget.color) {
      final hsv = HSVColor.fromColor(widget.color);
      _hue = hsv.hue;
      _saturation = hsv.saturation;
    }
  }

  void _updateColor(Offset localPos, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final vec = localPos - center;
    final angle = atan2(vec.dy, vec.dx);
    final hue = (angle * 180 / pi + 360) % 360;
    final sat = (vec.distance / (size.width / 2)).clamp(0.0, 1.0);

    setState(() {
      _hue = hue;
      _saturation = sat;
    });

    final newColor = HSVColor.fromAHSV(1, _hue, _saturation, widget.brightness)
        .toColor();
    widget.onColorChanged(newColor);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, cons) {
      final size = min(cons.maxWidth, cons.maxHeight);
      return GestureDetector(
        onTapDown: (d) => _updateColor(d.localPosition, Size(size, size)),
        onPanStart: (d) => _updateColor(d.localPosition, Size(size, size)),
        onPanUpdate: (d) => _updateColor(d.localPosition, Size(size, size)),
        child: Stack(
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _SpectrumPainter(hue: _hue, saturation: _saturation),
            ),

            // Единая таблица R/G/
          ],
        ),
      );
    });
  }
}

class _SpectrumPainter extends CustomPainter {
  final double hue;
  final double saturation;

  _SpectrumPainter({required this.hue, required this.saturation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // оттенки по кругу
    final sweep = SweepGradient(
      colors: List.generate(361, (i) => HSVColor.fromAHSV(1, i.toDouble(), 1, 1).toColor()),
    ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, Paint()..shader = sweep);

    // белый→прозрачный
    final radial = RadialGradient(
      colors: [Colors.white, Colors.transparent],
      stops: [0, 1],
    ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, Paint()..shader = radial..blendMode = BlendMode.srcOver);

    // обводка круга текущим цветом
    final sel = HSVColor.fromAHSV(1, hue, saturation, 1).toColor();
    canvas.drawCircle(center, radius - 2, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = sel);

    // маркер
    final ang = hue * pi / 180;
    final pt = Offset(
      center.dx + cos(ang) * radius * saturation,
      center.dy + sin(ang) * radius * saturation,
    );
    canvas.drawCircle(pt, 12, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = sel);
    canvas.drawCircle(pt, 10, Paint()..style = PaintingStyle.fill..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _SpectrumPainter old) =>
      old.hue != hue || old.saturation != saturation;
}
