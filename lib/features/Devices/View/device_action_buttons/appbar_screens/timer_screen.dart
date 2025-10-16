// timer_screen.dart v.1.7

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimerScreen extends StatefulWidget {
  final BluetoothCharacteristic? characteristic;

  const TimerScreen({Key? key, this.characteristic}) : super(key: key);

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  bool isOnEnabled = false;
  bool isOffEnabled = false;

  TimeOfDay? onTime;
  TimeOfDay? offTime;

  Set<int> onSelectedDays = {};
  Set<int> offSelectedDays = {};

  final List<String> dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      isOnEnabled = prefs.getBool('isOnEnabled') ?? false;
      isOffEnabled = prefs.getBool('isOffEnabled') ?? false;

      int? onHour = prefs.getInt('onHour');
      int? onMinute = prefs.getInt('onMinute');
      if (onHour != null && onMinute != null) {
        onTime = TimeOfDay(hour: onHour, minute: onMinute);
      }

      int? offHour = prefs.getInt('offHour');
      int? offMinute = prefs.getInt('offMinute');
      if (offHour != null && offMinute != null) {
        offTime = TimeOfDay(hour: offHour, minute: offMinute);
      }

      onSelectedDays = (prefs.getStringList('on_days') ?? []).map(int.parse).toSet();
      offSelectedDays = (prefs.getStringList('off_days') ?? []).map(int.parse).toSet();
    });

    _sendAllSettings();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isOnEnabled', isOnEnabled);
    await prefs.setBool('isOffEnabled', isOffEnabled);

    if (onTime != null) {
      await prefs.setInt('onHour', onTime!.hour);
      await prefs.setInt('onMinute', onTime!.minute);
    }

    if (offTime != null) {
      await prefs.setInt('offHour', offTime!.hour);
      await prefs.setInt('offMinute', offTime!.minute);
    }

    await prefs.setStringList('on_days', onSelectedDays.map((e) => e.toString()).toList());
    await prefs.setStringList('off_days', offSelectedDays.map((e) => e.toString()).toList());

    _sendAllSettings();
  }

  Future<void> _sendAllSettings() async {
    final c = widget.characteristic;
    if (c == null) return;

    try {
      final isActive = isOnEnabled || isOffEnabled;
      await c.write([isActive ? 0xF0 : 0xF1]);
      print('timer command has sended: ${isActive ? "0xF0 (ВКЛ)" : "0xF1 (ВЫКЛ)"}');

      if (isOnEnabled && onTime != null) {
        await c.write([0xF2, onTime!.hour, onTime!.minute]);
        print('Time ONN sended: ${onTime!.format(context)}');
      }

      if (isOffEnabled && offTime != null) {
        await c.write([0xF3, offTime!.hour, offTime!.minute]);
        print('Time OFF sended: ${offTime!.format(context)}');
      }

      final activeDays = {...onSelectedDays, ...offSelectedDays};
      if (activeDays.isNotEmpty) {
        int bitmask = 0;
        for (int day in activeDays) {
          bitmask |= (1 << day);
        }
        await c.write([0xF4, bitmask]);
        print('Day week sended: 0b${bitmask.toRadixString(2).padLeft(8, '0')}');
      }
    } catch (e) {
      print('⚠️ Ошибка отправки BLE параметров: $e');
    }
  }

  Future<void> _pickTime(bool isOn) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 0, minute: 0),
    );

    if (picked != null) {
      setState(() {
        if (isOn) {
          onTime = picked;
        } else {
          offTime = picked;
        }
      });
      _saveSettings();
    }
  }

  Widget _buildTimerBlock({
    required String title,
    required bool enabled,
    required TimeOfDay? time,
    required Set<int> selectedDays,
    required VoidCallback onTimeTap,
    required ValueChanged<bool> onSwitchChanged,
    required void Function(int index, bool selected) onDayToggle,
  }) {
    final timeText = time != null
        ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
        : 'Not selected';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text(title, style: const TextStyle(fontSize: 18)),
              value: enabled,
              onChanged: (val) {
                onSwitchChanged(val);
                _saveSettings();
              },
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: enabled ? onTimeTap : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Time:', style: TextStyle(fontSize: 16)),
                  Text(
                    timeText,
                    style: TextStyle(
                      color: enabled ? Colors.black : Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Days of the week:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (index) {
                final isSelected = selectedDays.contains(index);
                return ChoiceChip(
                  label: Text(dayLabels[index]),
                  selected: isSelected,
                  onSelected: enabled
                      ? (selected) {
                    setState(() {
                      if (selected) {
                        selectedDays.add(index);
                        print('Day added: ${dayLabels[index]}');
                      } else {
                        selectedDays.remove(index);
                        print('Day removed: ${dayLabels[index]}');
                      }
                    });
                    _saveSettings();
                  }
                      : null,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildTimerBlock(
            title: 'Turn On Light',
            enabled: isOnEnabled,
            time: onTime,
            selectedDays: onSelectedDays,
            onTimeTap: () => _pickTime(true),
            onSwitchChanged: (val) => setState(() => isOnEnabled = val),
            onDayToggle: (index, selected) {},
          ),
          _buildTimerBlock(
            title: 'Turn Off Light',
            enabled: isOffEnabled,
            time: offTime,
            selectedDays: offSelectedDays,
            onTimeTap: () => _pickTime(false),
            onSwitchChanged: (val) => setState(() => isOffEnabled = val),
            onDayToggle: (index, selected) {},
          ),
        ],
      ),
    );
  }
}
