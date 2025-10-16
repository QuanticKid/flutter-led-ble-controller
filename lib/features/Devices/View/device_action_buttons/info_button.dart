import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:led_control_app/features/Devices/View/device_info_dialog.dart';

class InfoButton extends StatelessWidget {
  final ScanResult result;

  const InfoButton({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 26,
      child: Builder(
        builder: (localContext) => IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            showDeviceInfo(localContext, result);
          },
        ),
      ),
    );
  }
}