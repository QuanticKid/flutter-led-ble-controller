// 2modes_screen.dart v1.1
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:led_control_app/features/Devices/Logic/light_controller.dart';

class ModeTileExtended extends StatefulWidget {
  final int index;
  final String name;
  final bool isActive;
  final Function(bool) onToggle;
  final TimeOfDay start;
  final TimeOfDay end;
  final Function(TimeOfDay) onStartChanged;
  final Function(TimeOfDay) onEndChanged;
  final Function(String) onRename;
  final bool overlap;
  final Color color;
  final Function(Color) onColorPicked;
  final Set<int> activeDays;
  final Function(int) onToggleDay;

  const ModeTileExtended({
    Key? key,
    required this.index,
    required this.name,
    required this.isActive,
    required this.onToggle,
    required this.start,
    required this.end,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onRename,
    required this.overlap,
    required this.color,
    required this.onColorPicked,
    required this.activeDays,
    required this.onToggleDay,
  }) : super(key: key);

  @override
  State<ModeTileExtended> createState() => _ModeTileExtendedState();
}

class _ModeTileExtendedState extends State<ModeTileExtended> {
  bool _activityEnabled = false;
  bool _lightEnabled = false;

  int _activityDuration = 30;
  int _lightDuration = 60;

  Color _activityColor = Colors.blue;
  Color _lightColor = Colors.green;

  final List<String> _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  Future<Color?> _pickColor(BuildContext context, Color initialColor) async {
    HSVColor currentHsv = HSVColor.fromColor(initialColor);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select color"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onPanDown: (details) {
                      final box = context.findRenderObject() as RenderBox;
                      final offset = box.globalToLocal(details.globalPosition);
                      final dx = offset.dx - 90;
                      final dy = offset.dy - 90;
                      final distance = sqrt(dx * dx + dy * dy);
                      if (distance <= 90) {
                        final angle = atan2(dy, dx);
                        final degrees = (angle * 180 / pi + 360) % 360;
                        setState(() {
                          currentHsv = HSVColor.fromAHSV(
                              1, degrees, 1, currentHsv.value);
                        });
                      }
                    },
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const SweepGradient(
                          colors: [
                            Colors.red,
                            Colors.yellow,
                            Colors.green,
                            Colors.cyan,
                            Colors.blue,
                            Colors.purple,
                            Colors.red,
                          ],
                        ),
                        border: Border.all(
                            color: currentHsv.toColor(), width: 4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text("Brightness: ${(currentHsv.value * 100).toInt()}%"),
                  Slider(
                    value: currentHsv.value,
                    min: 0.05,
                    max: 1.0,
                    divisions: 19,
                    label: "${(currentHsv.value * 100).toInt()}%",
                    onChanged: (v) {
                      setState(() {
                        currentHsv = currentHsv.withValue(v);
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, currentHsv.toColor()),
              child: const Text('Select'),
            ),
          ],
        );
      },
    );

    return currentHsv.toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // === Верхняя строка: цвет, название, редактирование, переключатель ===
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () async {
                        final controller =
                        TextEditingController(text: widget.name);
                        final newName = await showDialog<String>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Rename Mode'),
                            content: TextField(
                              controller: controller,
                              autofocus: true,
                              decoration:
                              const InputDecoration(hintText: 'Enter name'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(null),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(controller.text),
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                        );
                        if (newName != null && newName.trim().isNotEmpty) {
                          widget.onRename(newName.trim());
                        }
                      },
                      child: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: widget.isActive,
                onChanged: widget.overlap ? null : widget.onToggle,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // === Цветовая палитра ===
          GestureDetector(
            onTap: () async {
              final selected = await _pickColor(context, widget.color);
              if (selected != null) widget.onColorPicked(selected);
            },
            child: Container(
              width: 60,
              height: 20,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                gradient: LinearGradient(
                  colors: [
                    Colors.red,
                    Colors.orange,
                    Colors.yellow,
                    Colors.green,
                    Colors.blue,
                    Colors.purple,
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // === Start/End Time ===
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: widget.start,
                  );
                  if (picked != null) widget.onStartChanged(picked);
                },
                child: Text(
                  "Start: ${widget.start.format(context)}",
                  style: TextStyle(
                      color: widget.overlap ? Colors.red : Colors.black),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: widget.end,
                  );
                  if (picked != null) widget.onEndChanged(picked);
                },
                child: Text(
                  "End: ${widget.end.format(context)}",
                  style: TextStyle(
                      color: widget.overlap ? Colors.red : Colors.black),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // === Дни недели ===
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_weekdays.length, (i) {
              final dayNum = i + 1;
              final isSelected = widget.activeDays.contains(dayNum);
              return GestureDetector(
                onTap: () => widget.onToggleDay(dayNum),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected ? Colors.blueAccent : Colors.white,
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Text(
                    _weekdays[i],
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 12),

          // === Блок Activity ===
          Row(
            children: [
              Switch(
                value: _activityEnabled,
                onChanged: (v) async {
                  setState(() => _activityEnabled = v);

                  if (widget.index == 0) {
                    final command = v ? [0xA1] : [0xA0];
                    LightController.sendRaw(command);
                  }
                },
              ),
              GestureDetector(
                onTap: () async {
                  final selected = await _pickColor(context, _activityColor);
                  if (selected != null) {
                    setState(() => _activityColor = selected);
                  }
                },
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: _activityColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                ),
              ),
              const Text('Activity'),
            ],
          ),
          Slider(
            value: _activityDuration.toDouble(),
            min: 10,
            max: 600,
            divisions: 59,
            label: '${_activityDuration}s',
            onChanged: _activityEnabled
                ? (v) => setState(() => _activityDuration = v.toInt())
                : null,
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("10 sec", style: TextStyle(fontSize: 12)),
              Text("10 min", style: TextStyle(fontSize: 12)),
            ],
          ),

          const SizedBox(height: 16),

          // === Блок Light ===
          Row(
            children: [
              Switch(
                value: _lightEnabled,
                onChanged: (v) async {
                  setState(() => _lightEnabled = v);

                  if (widget.index == 0) {
                    final command = v ? [0xB1] : [0xB0];
                    LightController.sendRaw(command);
                  }
                },
              ),
              GestureDetector(
                onTap: () async {
                  final selected = await _pickColor(context, _lightColor);
                  if (selected != null) {
                    setState(() => _lightColor = selected);
                  }
                },
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: _lightColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                ),
              ),
              const Text('Light'),
            ],
          ),
          Slider(
            value: _lightDuration.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            label: '${_lightDuration.toInt()}',
            onChanged: _lightEnabled
                ? (v) => setState(() => _lightDuration = v.toInt())
                : null,
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("0% (LOW)" , style: TextStyle(fontSize: 12)),
              Text("100% (HIGH)", style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
