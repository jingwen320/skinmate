import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WishlistPage extends StatefulWidget {
  @override
  _WishlistPageState createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List wishlist = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchWishlist();
  }

  void fetchWishlist() async {
    try {
      var res = await ApiService.getWishlist("1"); // Replace 1 with logged user ID
      setState(() {
        wishlist = res['wishlist'] ?? [];
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return Center(child: CircularProgressIndicator());
    return ListView.builder(
      itemCount: wishlist.length,
      itemBuilder: (context, index) {
        var item = wishlist[index];
        return ListTile(
          leading: Image.network(item['image'] ?? '', width: 50, height: 50, fit: BoxFit.cover),
          title: Text(item['name']),
          subtitle: Text("RM ${item['price']}"),
        );
      },
    );
  }
}