import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../widgets/timer_completion_dialog.dart';
import '../models/book.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class ReadingTimerScreen extends StatefulWidget {
  const ReadingTimerScreen({super.key});

  @override
  State<ReadingTimerScreen> createState() => _ReadingTimerScreenState();
}

class _ReadingTimerScreenState extends State<ReadingTimerScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  List<Book> _availableBooks = [];
  bool _isLoadingBooks = false;

  // Preset durations in seconds
  final List<Map<String, dynamic>> _presetDurations = [
    {'label': '15 min', 'seconds': 900, 'icon': Icons.timer_outlined},
    {'label': '30 min', 'seconds': 1800, 'icon': Icons.timer},
    {'label': '45 min', 'seconds': 2700, 'icon': Icons.timer_3},
    {'label': '1 jam', 'seconds': 3600, 'icon': Icons.timer_10},
    {'label': '1.5 jam', 'seconds': 5400, 'icon': Icons.schedule},
    {'label': 'Custom', 'seconds': 0, 'icon': Icons.edit_outlined},
  ];

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _loadAvailableBooks();

    // Set completion callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timerProvider = Provider.of<TimerProvider>(context, listen: false);
      timerProvider.setOnSessionCompleted(() {
        if (mounted) {
          TimerCompletionDialog.show(context, timerProvider);
        }
      });
    });
  }

  Future<void> _loadAvailableBooks() async {
    setState(() {
      _isLoadingBooks = true;
    });

    try {
      final supabaseClient = supabase.Supabase.instance.client;
      final currentUserId = supabaseClient.auth.currentUser?.id;
      
      if (currentUserId == null) {
        setState(() {
          _availableBooks = [];
          _isLoadingBooks = false;
        });
        return;
      }

      final response = await supabaseClient
          .from('books')
          .select()
          .eq('user_id', currentUserId)
          .order('title', ascending: true);

      final List<Map<String, dynamic>> booksData = (response as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      final books = booksData
          .map((json) => Book.fromJson(json as Map<String, dynamic>))
          .toList();

      setState(() {
        _availableBooks = books;
        _isLoadingBooks = false;
      });
    } catch (e) {
      print('Error loading books: $e');
      setState(() {
        _availableBooks = [];
        _isLoadingBooks = false;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showCustomDurationDialog() {
    final hoursController = TextEditingController();
    final minutesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Atur Durasi Custom'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: hoursController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jam',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: minutesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Menit',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final hours = int.tryParse(hoursController.text) ?? 0;
              final minutes = int.tryParse(minutesController.text) ?? 0;
              final totalSeconds = (hours * 3600) + (minutes * 60);
              
              if (totalSeconds > 0) {
                Provider.of<TimerProvider>(context, listen: false)
                    .setDuration(totalSeconds);
              }
              
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Atur'),
          ),
        ],
      ),
    );
  }

  void _showBookSelector() {
    if (_availableBooks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada buku tersedia. Tambahkan buku terlebih dahulu!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pilih Buku untuk Dibaca',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _availableBooks.length,
                itemBuilder: (context, index) {
                  final book = _availableBooks[index];
                  final timerProvider = Provider.of<TimerProvider>(context, listen: false);
                  final isSelected = timerProvider.currentBook?.id == book.id;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: isSelected ? 4 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? Colors.orange : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        width: 50,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: book.coverImageUrl != null && book.coverImageUrl!.isNotEmpty
                              ? Image.network(
                                  book.coverImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.book, color: Colors.grey),
                                )
                              : const Icon(Icons.book, color: Colors.grey),
                        ),
                      ),
                      title: Text(
                        book.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.orange : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.author,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          if (book.category.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              book.category,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.orange)
                          : null,
                      onTap: () {
                        timerProvider.setCurrentBook(book);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Buku "${book.title}" dipilih untuk sesi membaca'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerProvider>(
      builder: (context, timerProvider, child) {
        // Start/stop pulse animation based on timer state
        if (timerProvider.isRunning && !_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        } else if (!timerProvider.isRunning && _pulseController.isAnimating) {
          _pulseController.stop();
          _pulseController.reset();
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text(
              'Timer Membaca',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.orange,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadAvailableBooks,
                tooltip: 'Refresh Buku',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Current Book Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.book, color: Colors.orange),
                            const SizedBox(width: 8),
                            const Text(
                              'Buku yang Dipilih',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (timerProvider.currentBook != null) ...[
                          Row(
                            children: [
                              Container(
                                width: 60,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[200],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: timerProvider.currentBook!.coverImageUrl != null && 
                                         timerProvider.currentBook!.coverImageUrl!.isNotEmpty
                                      ? Image.network(
                                          timerProvider.currentBook!.coverImageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(Icons.book, color: Colors.grey),
                                        )
                                      : const Icon(Icons.book, color: Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      timerProvider.currentBook!.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      timerProvider.currentBook!.author,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (timerProvider.currentBook!.category.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        timerProvider.currentBook!.category,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.swap_horiz),
                                onPressed: _showBookSelector,
                                tooltip: 'Ganti Buku',
                              ),
                            ],
                          ),
                        ] else ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.book_outlined,
                                  size: 40,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Belum ada buku dipilih',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: _showBookSelector,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Pilih Buku'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Timer Display
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.orange.withOpacity(0.1),
                          Colors.orange.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        // Circular Progress
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: timerProvider.isRunning ? _pulseAnimation.value : 1.0,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 200,
                                    height: 200,
                                    child: CircularProgressIndicator(
                                      value: timerProvider.progress,
                                      strokeWidth: 8,
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        timerProvider.isRunning ? Colors.orange : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        timerProvider.remainingTimeString,
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: timerProvider.isRunning ? Colors.orange : Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        timerProvider.isRunning
                                            ? 'Sedang Membaca'
                                            : timerProvider.isPaused
                                                ? 'Dijeda'
                                                : 'Siap Mulai',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),

                        // Control Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Stop Button
                            if (timerProvider.isRunning || timerProvider.isPaused)
                              FloatingActionButton(
                                onPressed: timerProvider.stopTimer,
                                backgroundColor: Colors.red,
                                heroTag: "stop",
                                child: const Icon(Icons.stop, color: Colors.white),
                              ),

                            // Main Action Button
                            FloatingActionButton.extended(
                              onPressed: () {
                                if (timerProvider.currentBook == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Pilih buku terlebih dahulu!'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                
                                if (timerProvider.isRunning) {
                                  timerProvider.pauseTimer();
                                } else if (timerProvider.isPaused) {
                                  timerProvider.resumeTimer();
                                } else {
                                  timerProvider.startTimer();
                                }
                              },
                              backgroundColor: timerProvider.isRunning
                                  ? Colors.orange[300]
                                  : Colors.orange,
                              heroTag: "main",
                              icon: Icon(
                                timerProvider.isRunning
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                              ),
                              label: Text(
                                timerProvider.isRunning
                                    ? 'Jeda'
                                    : timerProvider.isPaused
                                        ? 'Lanjut'
                                        : 'Mulai',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            // Reset Button
                            if (timerProvider.isPaused)
                              FloatingActionButton(
                                onPressed: timerProvider.resetTimer,
                                backgroundColor: Colors.grey,
                                heroTag: "reset",
                                child: const Icon(Icons.refresh, color: Colors.white),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Duration Presets
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pilih Durasi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _presetDurations.length,
                          itemBuilder: (context, index) {
                            final preset = _presetDurations[index];
                            final isSelected = preset['seconds'] == timerProvider.totalSeconds ||
                                (preset['seconds'] == 0 && !_presetDurations.any((p) => p['seconds'] == timerProvider.totalSeconds));
                            
                            return GestureDetector(
                              onTap: () {
                                if (preset['seconds'] == 0) {
                                  _showCustomDurationDialog();
                                } else {
                                  timerProvider.setDuration(preset['seconds']);
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.orange.withOpacity(0.2)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? Colors.orange : Colors.grey[300]!,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      preset['icon'],
                                      color: isSelected ? Colors.orange : Colors.grey[600],
                                      size: 28,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      preset['label'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isSelected ? Colors.orange : Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Reading Tips
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Colors.orange),
                            const SizedBox(width: 8),
                            const Text(
                              'Tips Membaca',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '• Pilih buku yang ingin dibaca terlebih dahulu\n'
                          '• Cari tempat yang tenang dan nyaman\n'
                          '• Matikan notifikasi untuk fokus maksimal\n'
                          '• Istirahat sejenak setiap 25-30 menit\n'
                          '• Catat poin-poin penting yang Anda baca',
                          style: TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
