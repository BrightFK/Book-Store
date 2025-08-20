import 'package:hive/hive.dart';

// Add this part directive
part 'book_model.g.dart';

@HiveType(typeId: 0) // Unique typeId for this class
class Book extends HiveObject {
  // Extend HiveObject for easier management
  @HiveField(0) // Unique index for each field
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String author;

  @HiveField(3)
  final String imageUrl;

  @HiveField(4)
  final double rating;

  @HiveField(5)
  final String genre;

  @HiveField(6)
  final String description;

  @HiveField(7)
  final double price;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.rating,
    required this.genre,
    required this.description,
    required this.price,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      imageUrl:
          json['image_url'] as String? ?? 'https://via.placeholder.com/150',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      genre: json['genre'] as String,
      description:
          json['description'] as String? ?? 'No description available.',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
