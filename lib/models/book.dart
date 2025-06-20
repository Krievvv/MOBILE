class Book {
  final int id;
  final String title;
  final String author;
  final String category;
  final String publishedDate;
  final String publisher;
  final int pages;
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
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      category: json['category'] as String? ?? '',
      publishedDate: json['published_date'] as String? ?? '',
      publisher: json['publisher'] as String? ?? '',
      pages: json['pages'] as int? ?? 0,
      isbn: json['isbn'] as String? ?? '',
      series: json['series'] as String? ?? '',
      description: json['description'] as String? ?? '',
      coverImageUrl: json['cover_image_url'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'category': category,
      'published_date': publishedDate,
      'publisher': publisher,
      'pages': pages,
      'isbn': isbn,
      'series': series,
      'description': description,
      'cover_image_url': coverImageUrl,
      'is_read': isRead,
      'notes': notes,
      'user_id': userId,
    };
  }

  // CopyWith method with proper null handling
  Book copyWith({
    int? id,
    String? title,
    String? author,
    String? category,
    String? publishedDate,
    String? publisher,
    int? pages,
    String? isbn,
    String? series,
    String? description,
    String? coverImageUrl,
    bool? isRead,
    String? notes,
    String? userId,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      category: category ?? this.category,
      publishedDate: publishedDate ?? this.publishedDate,
      publisher: publisher ?? this.publisher,
      pages: pages ?? this.pages,
      isbn: isbn ?? this.isbn,
      series: series ?? this.series,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      isRead: isRead ?? this.isRead,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() {
    return 'Book{id: $id, title: $title, author: $author}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Book &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
