import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProductPage extends StatefulWidget {
  final String userId;
  final String productId;

  const ProductPage({Key? key, required this.userId, required this.productId}) : super(key: key);

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  Map product = {};
  List reviews = [];
  bool isLoading = true;
  bool isWishlist = false;

  TextEditingController reviewController = TextEditingController();
  int rating = 5;

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
    _fetchReviews();
  }

  Future<void> _fetchProductDetails() async {
    final response = await ApiService.getProducts();
    setState(() {
      product = (response['products'] ?? []).firstWhere(
        (p) => p['id'].toString() == widget.productId,
        orElse: () => {},
      );
      isLoading = false;
    });
  }

  Future<void> _fetchReviews() async {
    final response = await ApiService.getReviews(widget.productId);
    setState(() {
      reviews = response['reviews'] ?? [];
    });
  }

  Future<void> _addToWishlist() async {
    final response = await ApiService.addWishlist(widget.userId, widget.productId);
    if (response['success'] == true) {
      setState(() {
        isWishlist = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added to wishlist!')),
      );
    }
  }

  Future<void> _submitReview() async {
    if (reviewController.text.isEmpty) return;
    final response = await ApiService.addReview(
      widget.userId,
      widget.productId,
      reviewController.text,
      rating,
    );
    if (response['success'] == true) {
      reviewController.clear();
      _fetchReviews();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review submitted!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product['name'] ?? 'Product'),
        actions: [
          IconButton(
            icon: Icon(isWishlist ? Icons.favorite : Icons.favorite_border),
            onPressed: _addToWishlist,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(
                    product['image'] ?? '',
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: 16),
                  Text(
                    product['name'] ?? '',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "RM ${product['price']}",
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 16),
                  Text(
                    product['description'] ?? '',
                    style: TextStyle(fontSize: 16),
                  ),
                  Divider(height: 32),
                  Text(
                    "Reviews",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ...reviews.map((r) => ListTile(
                        title: Text(r['review']),
                        subtitle: Text("Rating: ${r['rating']}"),
                      )),
                  SizedBox(height: 16),
                  TextField(
                    controller: reviewController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Write a review',
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text("Rating: "),
                      DropdownButton<int>(
                        value: rating,
                        items: List.generate(
                          5,
                          (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text('${index + 1}'),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            rating = val!;
                          });
                        },
                      ),
                      Spacer(),
                      ElevatedButton(
                        onPressed: _submitReview,
                        child: Text('Submit'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}