import 'package:flutter/material.dart';

class ChartWidget extends StatelessWidget {
  final Widget chart;
  final String title;

  const ChartWidget({super.key, required this.chart, required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 200, child: chart),
          ],
        ),
      ),
    );
  }
}
