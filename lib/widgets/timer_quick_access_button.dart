import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';

class TimerQuickAccessButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const TimerQuickAccessButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerProvider>(
      builder: (context, timer, child) {
        return IconButton(
          onPressed: onPressed,
          icon: Icon(
            timer.isRunning ? Icons.timer : Icons.timer_outlined,
            color: timer.isRunning ? Colors.orange : Colors.orangeAccent,
          ),
          tooltip: timer.isRunning ? 'Timer Aktif' : 'Mulai Timer',
        );
      },
    );
  }
}
