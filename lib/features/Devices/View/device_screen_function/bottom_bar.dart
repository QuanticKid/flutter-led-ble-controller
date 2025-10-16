// файл bottom_bar.dart v.1.2

import 'package:flutter/material.dart';

/// Простой аппбар внизу с пятью кнопками
class BottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onTap;

  const BottomBar({
    Key? key,
    this.selectedIndex = 0,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56.0,
      color: Colors.grey[300],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BottomBarButton(
            icon: Icons.home,
            label: 'Home',
            index: 0,
            selectedIndex: selectedIndex,
            onTap: onTap,
          ),
          _BottomBarButton(
            icon: Icons.toggle_on,
            label: 'Modes',
            index: 1,
            selectedIndex: selectedIndex,
            onTap: onTap,
          ),
          _BottomBarButton(
            icon: Icons.settings,
            label: 'Sensor Settings',
            index: 2,
            selectedIndex: selectedIndex,
            onTap: onTap,
          ),
          _BottomBarButton(
            icon: Icons.access_time,
            label: 'Timer',
            index: 3,
            selectedIndex: selectedIndex,
            onTap: onTap,
          ),
          // Новая кнопка BLE
          _BottomBarButton(
            icon: Icons.bluetooth,
            label: 'BLE',
            index: 4,
            selectedIndex: selectedIndex,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _BottomBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int selectedIndex;
  final ValueChanged<int>? onTap;

  const _BottomBarButton({
    required this.icon,
    required this.label,
    required this.index,
    required this.selectedIndex,
    this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;
    final color = isSelected ? Theme.of(context).primaryColor : Colors.black54;

    return InkWell(
      onTap: () => onTap?.call(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24.0, color: color),
          const SizedBox(height: 4.0),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.0,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
