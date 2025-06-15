import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';

class TimerDrawerItem extends StatelessWidget {
  final VoidCallback? onTap;

  const TimerDrawerItem({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerProvider>(
      builder: (context, timer, child) {
        return ListTile(
          leading: Icon(
            timer.isRunning ? Icons.timer : Icons.timer_outlined,
            color: timer.isRunning ? Colors.orange : null,
          ),
          title: Text(
            timer.isRunning ? 'Timer Aktif' : 'Timer Membaca',
            style: TextStyle(
              color: timer.isRunning ? Colors.orange : null,
              fontWeight: timer.isRunning ? FontWeight.bold : null,
            ),
          ),
          trailing: timer.isRunning 
              ? Text(
                  timer.remainingTimeString,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
          onTap: onTap,
        );
      },
    );
  }
}
