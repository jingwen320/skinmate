import 'dart:convert';
import 'dart:io'; // For File
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../pages/login_page.dart';

class ApiService {
  // static String baseUrl = "http://10.0.2.2/skinmate_api";
  // static const String mediaUrl = "http://10.0.2.2/skinmate_api/images/";
  // static String baseUrl = "https://carwash-manhandle-sprinkler.ngrok-free.dev/skinmate_api";
  // static const String mediaUrl = "https://carwash-manhandle-sprinkler.ngrok-free.dev/skinmate_api/images/";
  static String baseUrl = "https://library-valium-riverboat.ngrok-free.dev/skinmate_api";
  static const String mediaUrl = "https://library-valium-riverboat.ngrok-free.dev/skinmate_api/images/";
  // static String baseUrl = "http://192.168.101.170/skinmate_api";
  // static String baseUrl = "http://192.168.0.22/skinmate_api";
  


  // ========================
  // USER AUTH
  // ========================

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'email': email,
          'password': password,
        },
      ).timeout(const Duration(seconds: 10)); // Prevents infinite loading if server is down

      // Check if the server actually replied successfully (Status 200)
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        // Server returned an error (e.g., 404, 500)
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}'
        };
      }
    } catch (e) {
      // Handles network timeouts, wrong IP addresses, or no internet
      return {
        'status': 'error',
        'message': 'Unable to connect to the server.'
      };
    }
  }

  static Future<void> saveUserSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }

  static Future<String?> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password, 
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        try {
          return json.decode(response.body) as Map<String, dynamic>;
        } catch (e) {
          // Triggers if PHP returns invalid JSON (like an echo'd PHP error)
          return {
            'status': 'error',
            'message': 'Invalid response format from server.'
          };
        }
      } else {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Unable to connect to the server.'
      };
    }
  }

  static Future<Map<String, dynamic>> verifyTac(String email, String tac) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify_otp.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'email': email, 'otp': tac},
      ).timeout(const Duration(seconds: 10));

      debugPrint("RAW SERVER RESPONSE: ${response.body}"); 

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return {'status': 'error', 'message': 'Server error: ${response.statusCode}'};
    } catch (e) {
      debugPrint("CATCH BLOCK ERROR: $e");
      return {'status': 'error', 'message': 'Format error: Your server might be returning HTML/Errors instead of JSON.'};
    }
  }

  static Future<void> cancelRegistration(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/delete_unverified.php'),
      body: {'email': email},
    );
    
    if (response.statusCode == 200) {
      debugPrint("Registration cancelled and record removed.");
    }
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot_password.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'email': email},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return {'status': 'error', 'message': 'Server error: ${response.statusCode}'};
    } catch (e) {
      return {'status': 'error', 'message': 'Unable to connect to the server.'};
    }
  }

  static Future<Map<String, dynamic>> changePassword(String userId, String currentPassword, String newPassword) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/change_password.php'),
        body: {
          'user_id': userId,
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return json.decode(res.body);
      } else {
        return {'status': 'error', 'message': 'Server error: ${res.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  // ========================
  // PROFILE
  // ========================

  static Future getProfile(String userId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/get_profile.php?user_id=$userId'),
    );
    return json.decode(res.body);
  }

  static Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Remove ONLY the userId (Keep 'seenWelcome' as true so they don't see the intro again)
    await prefs.remove('userId');

    // 2. Notify the server (Optional, but good practice)
    try {
      await http.get(Uri.parse('$baseUrl/logout.php')).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint("Server logout failed, but local session cleared: $e");
    }

    // 3. Clear the navigation stack and go to Login
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false, // This makes it impossible to "Go Back" to the Home Page
      );
    }
  }

  // ========================
  // PRODUCTS
  // ========================

  // static Future getProducts() async {
  //   final res = await http.get(Uri.parse('$baseUrl/get_products.php'));
  //   return json.decode(res.body);
  // }

  static Future<Map<String, dynamic>> getProducts() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/get_products.php'))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(res.body);

        if (data['status'] == 'success' && data['products'] != null) {
          for (var product in data['products']) {
            // Force strict mobile type casting
            product['price'] = double.tryParse(product['price'].toString()) ?? 0.0;
            product['stock_quantity'] = int.tryParse(product['stock_quantity'].toString()) ?? 0;

            // Assemble the full host path for direct rendering in NetworkImage components
            if (product['image'] != null && product['image'].toString().isNotEmpty) {
              product['image_url'] = '$mediaUrl${product['image']}';
            } else {
              product['image_url'] = '${mediaUrl}placeholder-default.png';
            }
          }
        }
        return data;
      } else {
        return {'status': 'error', 'message': 'Server error: ${res.statusCode}', 'products': []};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Network failure: $e', 'products': []};
    }
  }

  static Future addWishlist(String userId, String productId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/add_wishlist.php'),
      body: {'user_id': userId, 'product_id': productId},
    );
    return json.decode(res.body);
  }

  static Future<Map<String, dynamic>> getWishlist(String userId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/get_wishlist.php?user_id=$userId'))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(res.body);

        // 🌟 THE FIX: Loop through wishlist items and map the keys exactly like getProducts()
        if (data['status'] == 'success' && data['wishlist'] != null) {
          for (var item in data['wishlist']) {
            // Keep your type mutations synchronized
            item['price'] = double.tryParse(item['price'].toString()) ?? 0.0;

            // Assemble the full host path for direct rendering in NetworkImage components
            if (item['image'] != null && item['image'].toString().isNotEmpty) {
              item['image_url'] = '$mediaUrl${item['image']}';
            } else {
              item['image_url'] = '${mediaUrl}placeholder-default.png';
            }
          }
        }
        return data;
      } else {
        return {'status': 'error', 'message': 'Server error: ${res.statusCode}', 'wishlist': []};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Network failure: $e', 'wishlist': []};
    }
  }

  static Future<Map<String, dynamic>> deleteWishlist(String userId, String productId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/delete_wishlist.php'),
        body: {
          'user_id': userId, 
          'product_id': productId,
        },
      ).timeout(const Duration(seconds: 10));
      
      return json.decode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {'status': 'error', 'message': 'Wishlist removal connection timeout.'};
    }
  }

  static Future addReview(String userId, String productId, String review, int rating) async {
    final res = await http.post(
      Uri.parse('$baseUrl/add_review.php'),
      body: {
        'user_id': userId,
        'product_id': productId,
        'review': review,
        'rating': rating.toString()
      },
    );
    return json.decode(res.body);
  }

  static Future getReviews(String productId) async {
    final res = await http.get(Uri.parse('$baseUrl/get_reviews.php?product_id=$productId'));
    return json.decode(res.body);
  }

  // ========================
  // SKINCARE RECOMMENDATION
  // ========================
  static Future<Map<String, dynamic>?> generateRecommendations({
    required int userId,
    required double targetBudget,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/generate_recommendation.php"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "user_id": userId.toString(),
          "target_budget": targetBudget.toString(),
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("API Error: $e");
      return null;
    }
  }

  // ========================
  // CART
  // ========================
  // 🛒 Fetch the live cart items from the PHP backend
  static Future<Map<String, dynamic>> getCart(String userId) async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/get_cart.php?user_id=$userId'),
        // Uri.parse('http://192.168.101.170/skinmate_api/get_cart.php?user_id=$userId'),
        // Uri.parse('http://192.168.0.22/skinmate_api/get_cart.php?user_id=$userId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // 🌟 THE FIX: Map image keys dynamically so the frontend layout renders them instantly!
        if (data['status'] == 'success' && data['cart'] != null) {
          for (var item in data['cart']) {
            final String rawImg = item['product_image'] ?? item['image'] ?? '';
            
            if (rawImg.isNotEmpty && !rawImg.startsWith('http')) {
              // Automatically strips an accidental leading slash if stored in the database row string
              final cleanRawImg = rawImg.startsWith('/') ? rawImg.substring(1) : rawImg;
              
              // Appends your global API media base path context directory structure
              item['product_image'] = '$mediaUrl$cleanRawImg';
            }
          }
        }
        return data;
      } else {
        return {'status': 'error', 'message': 'Server error ${response.statusCode}', 'cart': []};
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString(), 'cart': []};
    }
  }

  static Future<Map<String, dynamic>> updateCartQuantity(String userId, String cartId, int quantity) async {
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/update_cart_quantity.php'),
        // Uri.parse('http://192.168.101.170/skinmate_api/update_cart_quantity.php'),
        // Uri.parse('http://192.168.0.22/skinmate_api/update_cart_quantity.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'cart_id': cartId,
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'status': 'error', 'message': 'Server error ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> addToCart({
    required String userId,
    required String productId,
    required String productName,
    required String productPrice,
    required String productImage,
    required int quantity,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/add_to_cart.php'),
        body: {
          'user_id': userId,
          'product_id': productId,
          'product_name': productName,
          'product_price': productPrice,
          'product_image': productImage,
          'quantity': quantity.toString(),
        },
      ).timeout(const Duration(seconds: 10));

      return json.decode(res.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Network failure: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteCartItem(String userId, String cartId) async {
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/delete_cart_item.php'),
        // Uri.parse('http://192.168.101.170/skinmate_api/delete_cart_item.php'),
        // Uri.parse('http://192.168.0.22/skinmate_api/delete_cart_item.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'cart_id': cartId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'status': 'error', 'message': 'Server error ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ========================
  // CHECKOUT
  // ========================

  // 💳 Send the finalized bill over to PHP to create the order and wipe the cart
  static Future<Map<String, dynamic>> checkout({
    required String userId,
    required double subtotal,
    required double discount,
    required String shippingFee,
    required double finalTotal,
    required String name,
    required String phone,
    required String addressLine1,
    String? addressLine2,
    required String postcode,
    required String city,
    required String state,
    required String region,
  }) async {
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/checkout.php'),
        // Uri.parse('http://192.168.101.170/skinmate_api/checkout.php'),
        // Uri.parse('http://192.168.0.22/skinmate_api/checkout.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'subtotal': subtotal,
          'discount': discount,
          'shipping_fee': shippingFee,
          'final_total': finalTotal,
          'address_line_1': addressLine1,
          'address_line_2': addressLine2,
          'postcode': postcode,
          'city': city,
          'state': state,
          'region': region,
          'phone': phone,
          'name': name,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'status': 'error', 'message': 'Server error ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ========================
  // ORDERS
  // ========================

  static Future createOrder(String userId, List<Map<String, dynamic>> items, String type) async {
    // items = [{product_id: 1, quantity: 2}, ...]
    final res = await http.post(
      Uri.parse('$baseUrl/create_order.php'),
      body: {
        'user_id': userId,
        'items': json.encode(items),
        'order_type': type // Dine In / Takeaway
      },
    );
    return json.decode(res.body);
  }

  // static Future getOrders(String userId) async {
  //   final res = await http.get(Uri.parse('$baseUrl/get_orders.php?user_id=$userId'));
  //   return json.decode(res.body);
  // }

  static Future<Map<String, dynamic>> getOrders(String userId) async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/get_orders.php?user_id=$userId'),
        // Uri.parse('http://192.168.101.170/skinmate_api/get_orders.php?user_id=$userId'),
        // Uri.parse('http://192.168.0.22/skinmate_api/get_orders.php?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'status': 'error', 'message': 'Server error ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future updateOrderStatus(String orderId, String status) async {
    final res = await http.post(
      Uri.parse('$baseUrl/update_order_status.php'),
      body: {'order_id': orderId, 'status': status},
    );
    return json.decode(res.body);
  }

  static Future<Map<String, dynamic>> completeOrder(String userId, String orderId) async {
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/complete_order.php'),
        // Uri.parse('http://192.168.101.170/skinmate_api/complete_order.php'),
        // Uri.parse('http://192.168.0.22/skinmate_api/complete_order.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'order_id': orderId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'status': 'error', 'message': 'Server error ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/get_order_details.php?order_id=$orderId'),
        // Uri.parse('http://192.168.101.170/skinmate_api/get_order_details.php?order_id=$orderId'),
        // Uri.parse('http://192.168.0.22/skinmate_api/get_order_details.php?order_id=$orderId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'status': 'error', 'message': 'Server error ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ========================
  // SKIN ANALYSIS
  // ========================

  static Future uploadSkinScan(String userId, File imageFile) async {
    var uri = Uri.parse('$baseUrl/upload_skin.php');
    var request = http.MultipartRequest('POST', uri);

    // Add user_id
    request.fields['user_id'] = userId;

    // Add image file
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    return json.decode(response.body);
  }

  static Future getSkinProgress(String userId) async {
    final res = await http.get(Uri.parse('$baseUrl/get_skin_progress.php?user_id=$userId'));
    return json.decode(res.body);
  }

  static Future<List<dynamic>> getSkinHistory(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_skin_history.php?user_id=$userId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        return res['status'] == 'success' ? res['data'] : [];
      }
      return [];
    } catch (e) {
      debugPrint("History Fetch Error: $e");
      return [];
    }
  }

  // ========================
  // SEND EMAIL REPORT
  // ========================

  static Future<Map<String, dynamic>> sendEmailReport(dynamic scanId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/send_report_email.php'),
        body: {'scan_id': scanId.toString()},
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        return json.decode(res.body);
      } else {
        return {'status': 'error', 'message': 'Server returned code: ${res.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Network timeout exception: $e'};
    }
  }

  // ========================
  // HELPER
  // ========================

  // static Future searchProducts(String query) async {
  //   final res = await http.get(Uri.parse('$baseUrl/search_products.php?q=$query'));
  //   return json.decode(res.body);
  // }

  static Future<List<dynamic>> searchProducts(String query) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/search_products.php?q=${Uri.encodeComponent(query)}'))
          .timeout(const Duration(seconds: 10));
      
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(res.body);
        
        final List<dynamic> productList = data['products'] ?? [];

        for (var product in productList) {
          // Force strict mobile type casting so sorting/budget sliders don't crash
          product['price'] = double.tryParse(product['price'].toString()) ?? 0.0;
          product['stock_quantity'] = int.tryParse(product['stock_quantity'].toString()) ?? 0;

          // Assemble the full host path for direct rendering in NetworkImage components
          if (product['image'] != null && product['image'].toString().isNotEmpty) {
            product['image_url'] = '$mediaUrl${product['image']}';
          } else {
            product['image_url'] = '${mediaUrl}placeholder-default.png';
          }
        }

        return productList;
      } else {
        print('❌ Server Error: ${res.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Network/Search Exception: $e');
      return [];
    }
  }

  // ========================
  // UPDATE PROFILE
  // ========================

  static Future<Map<String, dynamic>> updateProfile(
    String userId, 
    String name, 
    String email, 
    {String? currentPassword, String? newPassword} // Optional parameters
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update_profile.php'),
        // Uri.parse('http://192.168.101.170/skinmate_api/update_profile.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'user_id': userId,
          'name': name,
          'email': email,
          // 2. These will send null if not provided, which your PHP can handle
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'status': 'error', 'message': 'Server error ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ========================
  // REMINDER SETTINGS
  // ========================

  static Future<void> saveRemindersToDb({
    required String userId,
    required TimeOfDay morningTime,
    required bool morningOn,
    required TimeOfDay eveningTime,
    required bool eveningOn,
  }) async {
    // 🕒 1. Format exactly for MySQL (HH:mm:ss)
    String mTimeStr = "${morningTime.hour.toString().padLeft(2, '0')}:${morningTime.minute.toString().padLeft(2, '0')}:00";
    String eTimeStr = "${eveningTime.hour.toString().padLeft(2, '0')}:${eveningTime.minute.toString().padLeft(2, '0')}:00";

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update_reminders.php'), // 👈 Make sure this matches your file name!
        body: {
          'user_id': userId,
          'morning_time': mTimeStr,
          'morning_enabled': morningOn ? "1" : "0", // 👈 PHP likes "1"/"0"
          'evening_time': eTimeStr,
          'evening_enabled': eveningOn ? "1" : "0",
        },
      );

      // 🔍 2. ADD THIS DEBUG PRINT - This is how we find the "Reset" bug!
      print("DEBUG SERVER RESPONSE: ${response.body}");
      
    } catch (e) {
      print("DATABASE SYNC FAILED: $e");
    }
  }

  // ========================
  // REFUND REQUEST
  // ========================

  static Future<Map<String, dynamic>> submitRefundRequest({
    required String orderId,
    required String userId,
    required String reason,
    required String description,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
    required List<File> proofFiles,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/submit_refund.php'));
    
    request.fields.addAll({
      'order_id': orderId,
      'user_id': userId,
      'reason': reason,
      'description': description,
      'total_amount': totalAmount.toString(),
      'items': jsonEncode(items), 
    });

    for (int i = 0; i < proofFiles.length; i++) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'proof[]', 
          proofFiles[i].path,
        ),
      );
    }

    var streamedRes = await request.send().timeout(const Duration(seconds: 25));
    var res = await http.Response.fromStream(streamedRes);
    
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      return {
        'status': 'error',
        'message': 'Server returned an unhandled error condition code: ${res.statusCode}'
      };
    }
  }

  static Future<Map<String, dynamic>> getOrderItems(String orderId) async {
    try {
      // 💡 Ensure this filename matches your PHP script exactly
      final response = await http.get(Uri.parse("$baseUrl/get_order_details.php?order_id=${orderId.trim()}"));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'success' && data['order'] != null) {
          return {
            'status': 'success',
            'items': data['order']['items'] ?? [] // 🚀 Extracting items from 'order'
          };
        }
      }
      return {'status': 'error', 'items': []};
    } catch (e) {
      debugPrint("API Error: $e");
      return {'status': 'error', 'items': []};
    }
  }

  // ========================
  // CUSTOMER SUPPORT
  // ========================

  static Future<List<dynamic>> getActiveRefunds(String userId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/get_active_refunds.php?user_id=$userId'),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(res.body);
        if (body['status'] == 'success') {
          return body['data'] ?? [];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getRefundHistory(String userId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/get_refund_history.php?user_id=$userId'),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(res.body);
        if (body['status'] == 'success') {
          // 🌟 Safely returns the clean array maps containing historical receipts back to the view page
          return body['data'] ?? [];
        }
      }
      return [];
    } catch (e) {
      // Return a blank list on structural format network breaks gracefully
      return [];
    }
  }

  static Future<bool> cancelRefundRequest(String orderId, String ticketId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/cancel_refund.php'),
        body: {
          'order_id': orderId,
          'ticket_id': ticketId,
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint("====== CANCEL REFUND DEBUG ======");
      debugPrint("HTTP Status Code: ${res.statusCode}");
      debugPrint("Raw Response Body: '${res.body}'");
      debugPrint("=================================");

      if (res.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(res.body);
        return body['status'] == 'success';
      }
      return false;
    } catch (e, stacktrace) {
      debugPrint("❌ Flutter Cancel Error: $e");
      debugPrint("Stacktrace: $stacktrace");
      return false;
    }
  }

  static Future<List<dynamic>> getChatMessages(int userId) async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/get_messages.php?user_id=$userId'));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        return data['messages'] ?? [];
      }
    }
    return [];
  } catch (e) {
    debugPrint("Error fetching chat messages: $e");
    return [];
  }
}

  static Future<Map<String, dynamic>> sendChatMessage({
    required int userId,
    required String senderType,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send_message.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "sender_type": senderType,
          "message": message,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {"status": "error", "message": "Server responded with status code ${response.statusCode}"};
    } catch (e) {
      debugPrint("Error sending message: $e");
      return {"status": "error", "message": e.toString()};
    }
  }

  static Future<bool> closeChatRoom(int roomId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/close_chat_room.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"room_id": roomId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint("Error closing chat room: $e");
      return false;
    }
  }
}