// lib/features/Devices/View/device_screen_function/rgb_value_table.dart

import 'package:flutter/material.dart';

/// Позиционированная таблица значений R/G/B,
/// чтобы использовать внутри любого селектора цвета.
class RgbValueTable extends StatelessWidget {
  final int r, g, b;

  const RgbValueTable({
    Key? key,
    required this.r,
    required this.g,
    required this.b,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      bottom: 12,
      child: SizedBox(
        width: 80,
        child: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(1),
          },
          children: [
            TableRow(children: [
              const Text('R:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text('$r', style: const TextStyle(fontSize: 12)),
            ]),
            TableRow(children: [
              const Text('G:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text('$g', style: const TextStyle(fontSize: 12)),
            ]),
            TableRow(children: [
              const Text('B:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text('$b', style: const TextStyle(fontSize: 12)),
            ]),
          ],
        ),
      ),
    );
  }
}
