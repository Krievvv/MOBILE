class Book {
  final String id;
  final String title;
  final String author;
  final String category;
  final String publishedDate;
  final String publisher;
  final String pages; // Changed to String to handle both String and int inputs
  final String isbn;
  final String series;
  final String description;
  final String? coverImageUrl;
  final bool isRead;
  final String notes;
  final String userId;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.publishedDate,
    required this.publisher,
    required this.pages,
    required this.isbn,
    required this.series,
    required this.description,
    this.coverImageUrl,
    required this.isRead,
    required this.notes,
    required this.userId,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      category: json['category'] ?? '',
      publishedDate: json['published_date'] ?? '',
      publisher: json['publisher'] ?? '',
      pages: json['pages']?.toString() ?? '0', // Convert to String
      isbn: json['isbn'] ?? '',
      series: json['series'] ?? '',
      description: json['description'] ?? '',
      coverImageUrl: json['cover_image_url'],
      isRead: json['is_read'] == true || json['is_read'] == 'true',
      notes: json['notes'] ?? '',
      userId: json['user_id']?.toString() ?? '',
    );
  }
}
