import 'package:flutter/material.dart';

class ProgressRing extends StatelessWidget {
  final double value;
  final String label;

  const ProgressRing({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: CircularProgressIndicator(
            value: value,
            strokeWidth: 10,
            color: const Color(0xFF1976D2),
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 24)),
      ],
    );
  }
}
