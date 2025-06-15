import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../screens/reading_timer_screen.dart';

class FloatingTimerWidget extends StatelessWidget {
  const FloatingTimerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerProvider>(
      builder: (context, timerProvider, child) {
        // Only show if timer is running or paused
        if (!timerProvider.isRunning && !timerProvider.isPaused) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 16,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReadingTimerScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: timerProvider.isRunning 
                    ? Colors.orange 
                    : Colors.orange.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    timerProvider.isRunning 
                        ? Icons.timer 
                        : Icons.pause_circle_outline,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timerProvider.remainingTimeString,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      value: timerProvider.progress,
                      strokeWidth: 2,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
