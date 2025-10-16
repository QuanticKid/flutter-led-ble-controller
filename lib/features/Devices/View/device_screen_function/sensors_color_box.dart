import 'package:flutter/material.dart';
import 'package:led_control_app/features/Devices/View/device_screen_function/preset_color_box.dart';
import 'package:led_control_app/features/Devices/View/device_screen_function/preset_manager.dart';

class SensorsColorBox extends StatelessWidget {
  final PresetManager presetManager;

  final int motionPresetIndex;
  final int lightPresetIndex;

  final bool motionEnabled;
  final bool lightEnabled;

  final ValueChanged<int> onMotionPresetTap;
  final ValueChanged<int> onLightPresetTap;

  final ValueChanged<bool> onMotionToggle;
  final ValueChanged<bool> onLightToggle;

  const SensorsColorBox({
    Key? key,
    required this.presetManager,
    required this.motionPresetIndex,
    required this.lightPresetIndex,
    required this.motionEnabled,
    required this.lightEnabled,
    required this.onMotionPresetTap,
    required this.onLightPresetTap,
    required this.onMotionToggle,
    required this.onLightToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Activity Sensor
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Activity Sensor',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              PresetColorBox(
                color: presetManager.getPreset(motionPresetIndex),
                isActive: true,
                onTap: () => onMotionPresetTap(motionPresetIndex),
                size: 24,
              ),
              const SizedBox(width: 12),
              Switch(
                value: motionEnabled,
                onChanged: onMotionToggle,
              ),
            ],
          ),
        ),

        // Light Sensor
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Light Sensor',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              PresetColorBox(
                color: presetManager.getPreset(lightPresetIndex),
                isActive: true,
                onTap: () => onLightPresetTap(lightPresetIndex),
                size: 24,
              ),
              const SizedBox(width: 12),
              Switch(
                value: lightEnabled,
                onChanged: onLightToggle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
