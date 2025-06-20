import 'package:flutter/material.dart';
import '../providers/timer_provider.dart';

class TimerCompletionDialog extends StatelessWidget {
  final TimerProvider timerProvider;

  const TimerCompletionDialog({
    super.key,
    required this.timerProvider,
  });

  static void show(BuildContext context, TimerProvider timerProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TimerCompletionDialog(timerProvider: timerProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.celebration, color: Colors.orange, size: 28),
          SizedBox(width: 8),
          Text('Selamat!'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Anda telah menyelesaikan sesi membaca!',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Durasi: ${timerProvider.formatDuration(timerProvider.totalSeconds)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                if (timerProvider.currentBook != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Buku: ${timerProvider.currentBook!.title}',
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Penulis: ${timerProvider.currentBook!.author}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            timerProvider.resetTimer();
          },
          child: const Text('Sesi Baru'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            timerProvider.resetTimer();
            
            // Navigate to reading history to see the saved session
            Navigator.of(context).pushReplacementNamed('/main');
            // You can also navigate directly to history tab if needed
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Lihat Riwayat'),
        ),
      ],
    );
  }
}