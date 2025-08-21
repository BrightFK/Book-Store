import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/book_model.dart';

class BookDetailScreen extends StatelessWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  // This _toggleBookmark function is no longer needed here.
  // The logic will be moved to the _BottomActionBar.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F2),
      appBar: AppBar(
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
        // <-- REMOVED THE BOOKMARK ACTION FROM APPBAR TO AVOID CONFUSION
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
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
              // <-- Pass the whole book object
              _BottomActionBar(book: book),
            ],
          ),
        ),
      ),
    );
  }

  // ... All your _build... helper methods remain exactly the same ...
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
        child: Image.network(book.imageUrl, height: 250, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildBookInfo() {
    return Column(
      children: [
        Text(
          book.title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'by ${book.author}',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (index) => Icon(
              index < book.rating.floor() ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Description',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          book.description,
          style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
        ),
      ],
    );
  }
}

class _BottomActionBar extends StatefulWidget {
  // <-- Change to receive the full book
  final Book book;
  const _BottomActionBar({required this.book});

  @override
  State<_BottomActionBar> createState() => _BottomActionBarState();
}

class _BottomActionBarState extends State<_BottomActionBar> {
  int _quantity = 1;

  void _incrementQuantity() => setState(() => _quantity++);
  void _decrementQuantity() =>
      setState(() => _quantity > 1 ? _quantity-- : null);

  Future<void> _addToCart() async {
    final wishlistBox = Hive.box<Book>('wishlist_books');
    final quantityBox = Hive.box<int>('cart_quantities');

    // Add/update the book in the wishlist box
    await wishlistBox.put(widget.book.id, widget.book);
    // Add/update the quantity in the quantity box
    await quantityBox.put(widget.book.id, _quantity);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${widget.book.title}" added to cart.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // <-- Calculation now uses the passed book's price
    final totalCost = widget.book.price * _quantity;
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
                      '$_quantity',
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total Cost',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  Text(
                    '\$${totalCost.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              // <-- CHANGE: Use the new cart logic and button style
              icon: const Icon(Icons.add_shopping_cart),
              onPressed: _addToCart,
              label: const Text('Add to Cart'),
            ),
          ),
        ],
      ),
    );
  }
}
