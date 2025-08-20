class Book {
  final String id; // NEW: The UUID from Supabase
  final String title;
  final String author;
  final String imageUrl;
  final double rating;
  final String description;
  final double price;

  Book({
    required this.id, // MODIFIED
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.rating,
    required this.description,
    required this.price,
  });

  // NEW: A factory constructor to easily create a Book from the JSON
  // data we get from Supabase.
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      // Provide default values in case some fields are null in the database
      imageUrl:
          json['image_url'] as String? ?? 'https://via.placeholder.com/150',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      description:
          json['description'] as String? ?? 'No description available.',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
