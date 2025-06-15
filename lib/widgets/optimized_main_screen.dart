import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../providers/book_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/book_card.dart';
import '../widgets/timer_app_bar_button.dart';
import '../widgets/timer_drawer_item.dart';
import '../widgets/timer_quick_access_button.dart';
import '../screens/add_book_screen.dart';
import 'package:peoject_uas/models/book.dart';

class OptimizedHomeScreen extends StatelessWidget {
  final BookProvider bookProvider;
  final Function(int) onNavigate;

  const OptimizedHomeScreen({
    super.key,
    required this.bookProvider,
    required this.onNavigate,
  });

  Future<List<Map<String, dynamic>>> fetchBooks() async {
    try {
      final supabaseClient = supabase.Supabase.instance.client;
      
      final currentUserId = supabaseClient.auth.currentUser?.id;
      
      if (currentUserId == null) {
        return [];
      }

      final response = await supabaseClient
          .from('books')
          .select()
          .eq('user_id', currentUserId)
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pustakasaku"),
        backgroundColor: Colors.orangeAccent,
        actions: [
          TimerAppBarButton(onPressed: () => onNavigate(1)),
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
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
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
            TimerDrawerItem(
              onTap: () {
                Navigator.pop(context);
                onNavigate(1);
              },
            ),
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
          // Quick Stats Card - Static part
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orangeAccent.withOpacity(0.1), Colors.orange.withOpacity(0.05)],
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
                final readBooks = snapshot.data?.where((book) => book['is_read'] == true).length ?? 0;
                
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
                    // Only this small part updates with timer
                    TimerQuickAccessButton(onPressed: () => onNavigate(1)),
                  ],
                );
              },
            ),
          ),
          
          // Books List - Static part
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
