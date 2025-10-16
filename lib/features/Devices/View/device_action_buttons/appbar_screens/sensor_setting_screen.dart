import 'package:flutter/material.dart';

class SensorSettingScreen extends StatefulWidget {
  const SensorSettingScreen({Key? key}) : super(key: key);

  @override
  State<SensorSettingScreen> createState() => _SensorSettingScreenState();
}

class _SensorSettingScreenState extends State<SensorSettingScreen> {
  double _motionSensitivity = 1;
  double _motionDuration = 1.0;
  double _motionTimeout = 10;
  double _lightThreshold = 0.4;
  double _lightSensitivityCurve = 50;
  double _lightDarknessThreshold = 0.5;
  double _ambientAdaptation = 50;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSensorCard(
            title: 'Activity Sensor',
            children: [
              _buildLabeledSlider(
                label: 'Distance sensitivity',
                value: _motionSensitivity,
                min: 1,
                max: 7,
                divisions: 28,
                minLabel: 'Low',
                maxLabel: 'High',
                onChanged: (v) => setState(() => _motionSensitivity = v),
              ),
              _buildLabeledSlider(
                label: 'Motion duration',
                value: _motionDuration,
                min: 0,
                max: 5,
                divisions: 5,
                minLabel: 'Instant',
                maxLabel: 'Sustained',
                onChanged: (v) => setState(() => _motionDuration = v),
              ),
              _buildLabeledSlider(
                label: 'Timeout ',
                value: _motionTimeout,
                min: 0,
                max: 600,
                divisions: 30,
                minLabel: '0',
                maxLabel: '600',
                onChanged: (v) => setState(() => _motionTimeout = v),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSensorCard(
            title: 'Light Sensor',
            children: [
              _buildLabeledSlider(
                label: 'Darkness threshold',
                value: _lightDarknessThreshold,
                min: 0,
                max: 100,
                divisions: 20,
                minLabel: 'Min',
                maxLabel: 'Max',
                onChanged: (v) => setState(() => _lightDarknessThreshold = v),
              ),
              _buildLabeledSlider(
                label: 'Ambient adaptation',
                value: _ambientAdaptation,
                min: 0,
                max: 100,
                divisions: 10,
                minLabel: 'Slow',
                maxLabel: 'Fast',
                onChanged: (v) => setState(() => _ambientAdaptation = v),
              ),
              _buildLabeledSlider(
                label: 'Sensitivity curve',
                value: _lightSensitivityCurve,
                min: 0,
                max: 100,
                divisions: 20,
                minLabel: 'Soft',
                maxLabel: 'Sharp',
                onChanged: (v) => setState(() => _lightSensitivityCurve = v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildLabeledSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String minLabel,
    required String maxLabel,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: value.toStringAsFixed(1),
          onChanged: onChanged,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(minLabel, style: const TextStyle(fontSize: 12)),
            Text(maxLabel, style: const TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
