import 'package:flutter/material.dart';

import '../models/book_model.dart';

// We convert the widget to a StatefulWidget to manage the quantity.
class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  // State variable to hold the current quantity
  int _quantity = 1;

  // Method to increase quantity
  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  // Method to decrease quantity, ensuring it doesn't go below 1
  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // We use the same background color as the home screen
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F2),
      appBar: _buildAppBar(context),
      body: Padding(
        // Padding creates the inset effect for the main white card
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          // Using a Column with an Expanded widget is key to making the
          // bottom action bar "stick" to the bottom of the container.
          child: Column(
            children: [
              // This Expanded contains all the scrollable content.
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        _buildBookCover(),
                        const SizedBox(height: 24),
                        _buildBookInfo(),
                        const SizedBox(height: 24),
                        const Divider(color: Colors.black12),
                        const SizedBox(height: 16),
                        _buildDescriptionSection(),
                      ],
                    ),
                  ),
                ),
              ),
              // This is the fixed bar at the bottom of the white card.
              _buildBottomActionBar(),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDER METHODS ---

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.bookmark_border, color: Colors.black),
              onPressed: () {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookCover() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 3,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          widget.book.imageUrl,
          height: 250,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildBookInfo() {
    return Column(
      children: [
        Text(
          widget.book.title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'by ${widget.book.author}',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return Icon(
              index < widget.book.rating.floor()
                  ? Icons.star
                  : Icons.star_border,
              color: Colors.amber,
              size: 20,
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Description',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              '\$${widget.book.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF005A5A), // Dark Teal
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          widget.book.description,
          style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          // QTY Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text(
                  'QTY',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: _decrementQuantity,
                  child: const Icon(Icons.remove, size: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  '$_quantity', // Display the state variable
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _incrementQuantity,
                  child: const Icon(Icons.add, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // "But Now" Button
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005A5A), // Dark Teal
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
              child: const Text(
                'Buy Now',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
