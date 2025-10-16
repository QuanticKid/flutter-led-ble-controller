// modes_screen.dart v1.16
import 'package:flutter/material.dart';
import '2modes_screen.dart'; // Предполагается, что 2modes_screen.dart лежит в той же директории
import 'package:led_control_app/features/Devices/Logic/light_controller.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:led_control_app/features/Devices/Logic/light_controller.dart';
import 'package:led_control_app/features/Devices/View/device_screen_function/rgb_value_table.dart';

class ModesScreen extends StatefulWidget {
  const ModesScreen({Key? key}) : super(key: key);

  @override
  State<ModesScreen> createState() => _ModesScreenState();
}

class _ModesScreenState extends State<ModesScreen> {
  // Флаги активации режимов
  bool mode1 = false;
  bool mode2 = false;
  bool mode3 = false;
  bool mode4 = false;

  // Временные интервалы для каждого режима
  TimeOfDay start1 = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay end1 = const TimeOfDay(hour: 23, minute: 0);

  TimeOfDay start2 = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay end2 = const TimeOfDay(hour: 22, minute: 0);

  TimeOfDay start3 = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay end3 = const TimeOfDay(hour: 21, minute: 0);

  TimeOfDay start4 = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay end4 = const TimeOfDay(hour: 8, minute: 0);

  // Названия режимов
  String name1 = "Rainbow Mode";
  String name2 = "Breathing Light";
  String name3 = "Color Loop";
  String name4 = "Morning Boost";

  // Флаги перекрытия по времени (если true — режим выключается автоматически и выключатель блокируется)
  bool overlap1 = false;
  bool overlap2 = false;
  bool overlap3 = false;
  bool overlap4 = false;

  // Цвета для каждого режима
  Color color1 = Colors.red;
  Color color2 = Colors.green;
  Color color3 = Colors.blue;
  Color color4 = Colors.orange;

  // Список активных дней по каждому режиму (1 = понедельник, ..., 7 = воскресенье)
  final List<Set<int>> activeDays = [
    {1, 2, 3, 4, 5}, // для режима 1
    {1, 3, 5}, // для режима 2
    {2, 4}, // для режима 3
    {6, 7}, // для режима 4
  ];

  @override
  void initState() {
    super.initState();
    _updateOverlaps();
  }

  // Пересчитать все overlap-флаги и при необходимости сбросить переключатели
  void _updateOverlaps() {
    overlap1 = _checkOverlap(1);
    overlap2 = _checkOverlap(2);
    overlap3 = _checkOverlap(3);
    overlap4 = _checkOverlap(4);

    if (overlap1) mode1 = false;
    if (overlap2) mode2 = false;
    if (overlap3) mode3 = false;
    if (overlap4) mode4 = false;
  }

  // Проверяет, пересекается ли интервал index-го режима с любым другим
  bool _checkOverlap(int index) {
    final ranges = [
      [start1, end1],
      [start2, end2],
      [start3, end3],
      [start4, end4],
    ];
    final current = ranges[index - 1];
    for (int i = 0; i < ranges.length; i++) {
      if (i == index - 1) continue;
      if (_timeRangesOverlap(
          current[0], current[1], ranges[i][0], ranges[i][1])) {
        return true;
      }
    }
    return false;
  }

  // Проверка пересечения двух временных диапазонов
  bool _timeRangesOverlap(TimeOfDay startA, TimeOfDay endA, TimeOfDay startB,
      TimeOfDay endB) {
    final aStart = startA.hour * 60 + startA.minute;
    final aEnd = endA.hour * 60 + endA.minute;
    final bStart = startB.hour * 60 + startB.minute;
    final bEnd = endB.hour * 60 + endB.minute;
    return aStart < bEnd && bStart < aEnd;
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Modes")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ===== Режим 1 =====
            ModeTileExtended(
              index: 0,
              name: name1,
              isActive: mode1,
              onToggle: (v) {
                setState(() => mode1 = v);

                if (v) {
                  LightController.setColor(0, 0, 255);
                } else {
                  LightController.setColor(0, 0, 0);
                }
              },
              start: start1,
              end: end1,
              onStartChanged: (t) =>
                  setState(() {
                    start1 = t;
                    _updateOverlaps();
                  }),
              onEndChanged: (t) =>
                  setState(() {
                    end1 = t;
                    _updateOverlaps();
                  }),
              onRename: (n) => setState(() => name1 = n),
              overlap: overlap1,
              color: color1,
              onColorPicked: (c) => setState(() => color1 = c),
              activeDays: activeDays[0],
              onToggleDay: (dayNum) =>
                  setState(() {
                    if (activeDays[0].contains(dayNum)) {
                      activeDays[0].remove(dayNum);
                    } else {
                      activeDays[0].add(dayNum);
                    }
                  }),
            ),

            // ===== Режим 2 =====
            ModeTileExtended(
              index: 1,
              name: name2,
              isActive: mode2,
              onToggle: (v) => setState(() => mode2 = v),
              start: start2,
              end: end2,
              onStartChanged: (t) =>
                  setState(() {
                    start2 = t;
                    _updateOverlaps();
                  }),
              onEndChanged: (t) =>
                  setState(() {
                    end2 = t;
                    _updateOverlaps();
                  }),
              onRename: (n) => setState(() => name2 = n),
              overlap: overlap2,
              color: color2,
              onColorPicked: (c) => setState(() => color2 = c),
              activeDays: activeDays[1],
              onToggleDay: (dayNum) =>
                  setState(() {
                    if (activeDays[1].contains(dayNum)) {
                      activeDays[1].remove(dayNum);
                    } else {
                      activeDays[1].add(dayNum);
                    }
                  }),
            ),

            // ===== Режим 3 =====
            ModeTileExtended(
              index: 2,
              name: name3,
              isActive: mode3,
              onToggle: (v) => setState(() => mode3 = v),
              start: start3,
              end: end3,
              onStartChanged: (t) =>
                  setState(() {
                    start3 = t;
                    _updateOverlaps();
                  }),
              onEndChanged: (t) =>
                  setState(() {
                    end3 = t;
                    _updateOverlaps();
                  }),
              onRename: (n) => setState(() => name3 = n),
              overlap: overlap3,
              color: color3,
              onColorPicked: (c) => setState(() => color3 = c),
              activeDays: activeDays[2],
              onToggleDay: (dayNum) =>
                  setState(() {
                    if (activeDays[2].contains(dayNum)) {
                      activeDays[2].remove(dayNum);
                    } else {
                      activeDays[2].add(dayNum);
                    }
                  }),
            ),

            // ===== Режим 4 =====
            ModeTileExtended(
              index: 3,
              name: name4,
              isActive: mode4,
              onToggle: (v) => setState(() => mode4 = v),
              start: start4,
              end: end4,
              onStartChanged: (t) =>
                  setState(() {
                    start4 = t;
                    _updateOverlaps();
                  }),
              onEndChanged: (t) =>
                  setState(() {
                    end4 = t;
                    _updateOverlaps();
                  }),
              onRename: (n) => setState(() => name4 = n),
              overlap: overlap4,
              color: color4,
              onColorPicked: (c) => setState(() => color4 = c),
              activeDays: activeDays[3],
              onToggleDay: (dayNum) =>
                  setState(() {
                    if (activeDays[3].contains(dayNum)) {
                      activeDays[3].remove(dayNum);
                    } else {
                      activeDays[3].add(dayNum);
                    }
                  }),
            ),

            const SizedBox(height: 24),

            // === Иконка "добавить сценарий" ===
            Center(
              child: GestureDetector(
                onTap: () {}, // Пока не делает ничего
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade300,
                  ),
                  child: const Icon(Icons.add, size: 32, color: Colors.black),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}