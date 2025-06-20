import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../providers/book_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/timer_provider.dart';
import '../widgets/book_card.dart';
import '../widgets/floating_timer_widget.dart';
import 'profile_screen.dart';
import '../screens/add_book_screen.dart';
import '../screens/reading_timer_screen.dart';
import '../screens/reading_history_screen.dart';

import 'package:peoject_uas/models/book.dart';
import '../widgets/optimized_main_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);
    final supabaseClient = supabase.Supabase.instance.client;

    final List<Widget> _screens = [
      OptimizedHomeScreen(
          bookProvider: bookProvider, onNavigate: _onItemTapped),
      const ReadingTimerScreen(),
      const ReadingHistoryScreen(),
      ProfileScreen(
        totalBooks: bookProvider.books.length,
        booksRead: bookProvider.books.where((book) => book.isRead).length,
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          _screens[_selectedIndex],
          // Floating Timer Widget
          const FloatingTimerWidget(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.orangeAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: "Timer"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Riwayat"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final BookProvider bookProvider;
  final Function(int) onNavigate;

  const HomeScreen({
    super.key,
    required this.bookProvider,
    required this.onNavigate,
  });

  Future<List<Map<String, dynamic>>> fetchBooks() async {
    try {
      final supabaseClient = supabase.Supabase.instance.client;

      // Get current user ID
      final currentUserId = supabaseClient.auth.currentUser?.id;

      if (currentUserId == null) {
        return []; // Return empty list if no user is logged in
      }

      final response = await supabaseClient
          .from('books')
          .select()
          .eq('user_id', currentUserId) // Filter by user_id
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> books = (response as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      return books;
    } catch (error) {
      print('Error fetching books: $error');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final timerProvider = Provider.of<TimerProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pustakasaku"),
        backgroundColor: Colors.orangeAccent,
        actions: [
          // Timer Quick Access - pisahkan ke widget terpisah
          const TimerAppBarButton(),
          IconButton(
            icon: themeProvider.themeMode == ThemeMode.dark
                ? const Icon(Icons.dark_mode)
                : const Icon(Icons.light_mode),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.orangeAccent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.library_books, color: Colors.white, size: 40),
                  SizedBox(height: 8),
                  Text(
                    'Pustakasaku',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Kelola koleksi buku Anda',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              selected: true,
              onTap: () {
                Navigator.pop(context);
                onNavigate(0);
              },
            ),
            const TimerDrawerItem(),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Riwayat Membaca'),
              onTap: () {
                Navigator.pop(context);
                onNavigate(2);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                onNavigate(3);
              },
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orangeAccent.withOpacity(0.1),
                  Colors.orange.withOpacity(0.05)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orangeAccent.withOpacity(0.2)),
            ),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchBooks(),
              builder: (context, snapshot) {
                final booksCount = snapshot.data?.length ?? 0;
                final readBooks = snapshot.data
                        ?.where((book) => book['is_read'] == true)
                        .length ??
                    0;

                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Koleksi Buku',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$booksCount buku',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orangeAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey[300],
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Sudah Dibaca',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$readBooks buku',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const TimerQuickAccessButton(),
                  ],
                );
              },
            ),
          ),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchBooks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final booksMap = snapshot.data ?? [];
                final books = booksMap
                    .map((json) => Book.fromJson(json as Map<String, dynamic>))
                    .toList();

                if (books.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.library_books_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada buku!',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tambahkan buku pertama Anda',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return isWideScreen
                    ? GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2 / 3,
                        ),
                        itemCount: books.length,
                        itemBuilder: (context, index) {
                          final book = books[index];
                          return BookCard(book: book);
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: books.length,
                        itemBuilder: (context, index) {
                          final book = books[index];
                          return BookCard(book: book);
                        },
                      );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orangeAccent,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddBookScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class TimerAppBarButton extends StatelessWidget {
  const TimerAppBarButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerProvider>(
      builder: (context, timer, child) {
        final onNavigate = (int index) {
          final mainScreenState =
              context.findAncestorStateOfType<_MainScreenState>();
          mainScreenState?._onItemTapped(index);
        };
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
            onPressed: () => onNavigate(1),
            tooltip: 'Timer Aktif',
          );
        }
        return IconButton(
          icon: const Icon(Icons.timer_outlined),
          onPressed: () => onNavigate(1),
          tooltip: 'Timer Membaca',
        );
      },
    );
  }
}

class TimerDrawerItem extends StatelessWidget {
  const TimerDrawerItem({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerProvider>(
      builder: (context, timer, child) {
        final onNavigate = (int index) {
          final mainScreenState =
              context.findAncestorStateOfType<_MainScreenState>();
          mainScreenState?._onItemTapped(index);
        };
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
          onTap: () {
            Navigator.pop(context);
            onNavigate(1);
          },
        );
      },
    );
  }
}

class TimerQuickAccessButton extends StatelessWidget {
  const TimerQuickAccessButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerProvider>(
      builder: (context, timer, child) {
        final onNavigate = (int index) {
          final mainScreenState =
              context.findAncestorStateOfType<_MainScreenState>();
          mainScreenState?._onItemTapped(index);
        };
        return IconButton(
          onPressed: () => onNavigate(1),
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
