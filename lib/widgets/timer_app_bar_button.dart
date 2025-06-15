import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';

class TimerAppBarButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const TimerAppBarButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerProvider>(
      builder: (context, timer, child) {
        if (timer.isRunning || timer.isPaused) {
          return IconButton(
            icon: Stack(
              children: [
                Icon(
                  timer.isRunning ? Icons.timer : Icons.pause_circle_outline,
                  color: Colors.white,
                ),
                if (timer.isRunning)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: onPressed,
            tooltip: 'Timer Aktif',
          );
        }
        return IconButton(
          icon: const Icon(Icons.timer_outlined),
          onPressed: onPressed,
          tooltip: 'Timer Membaca',
        );
      },
    );
  }
}
