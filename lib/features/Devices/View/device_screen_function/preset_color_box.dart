import 'package:flutter/material.dart';

class PresetColorBox extends StatelessWidget {
  final Color color;
  final VoidCallback? onTap;
  final bool isActive;
  final double size;

  const PresetColorBox({
    Key? key,
    required this.color,
    this.onTap,
    this.isActive = false,
    this.size = 40, // значение по умолчанию — как раньше
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? Colors.black : Colors.black26,
            width: isActive ? 3 : 1,
          ),
        ),
      ),
    );
  }
}
