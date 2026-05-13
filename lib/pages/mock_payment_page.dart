import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class MockPaymentPage extends StatefulWidget {
  final String userId;
  final double cartSubtotal; 
  final double discount; // 👈 ADD THIS!

  const MockPaymentPage({
    super.key, 
    required this.userId, 
    required this.cartSubtotal,
    required this.discount, // 👈 ADD THIS!
  });

  @override
  State<MockPaymentPage> createState() => _MockPaymentPageState();
}

class _MockPaymentPageState extends State<MockPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  
  bool _isProcessing = false;
  String? _selectedState;

  // 📍 Malaysian logistics split
  final List<String> _westMalaysia = [
    'Johor', 'Kedah', 'Kelantan', 'Melaka', 'Negeri Sembilan', 
    'Pahang', 'Pulau Pinang', 'Perak', 'Perlis', 'Selangor', 
    'Terengganu', 'Kuala Lumpur', 'Putrajaya'
  ];
  
  final List<String> _eastMalaysia = ['Sabah', 'Sarawak', 'Labuan'];

  // 🧮 1. Figure out the actual basket value after the store discount
  double get _amountAfterDiscount => widget.cartSubtotal - widget.discount;

  // 🚚 2. Shipping Math Rules (Now checks amount AFTER discount!)
  double get _shippingFee {
    if (_amountAfterDiscount >= 250.00) return 0.00; // Free over RM250 after discount!
    if (_selectedState == null) return 0.00;
    
    return _eastMalaysia.contains(_selectedState) ? 15.00 : 10.00;
  }

  // 💰 3. Final Grand Total
  double get _finalGrandTotal => _amountAfterDiscount + _shippingFee;

  final _addr1Controller = TextEditingController();
  final _addr2Controller = TextEditingController(); // This one can be left blank!
  final _postcodeController = TextEditingController();
  final _cityController = TextEditingController();

  void _simulatePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 3));

    final cleanCardNumber = _cardNumberController.text.replaceAll(' ', '');
    const successVisa = "4242424242424242";
    const successMastercard = "5555555555554444";

    if (cleanCardNumber == successVisa || cleanCardNumber == successMastercard) {
      
      // 🚚 Grab the string for the database!
      String shippingFeeStr = _shippingFee == 0.00 ? "FREE" : _shippingFee.toStringAsFixed(2);
      String region = _eastMalaysia.contains(_selectedState) ? "East Malaysia" : "West Malaysia";

      final response = await ApiService.checkout(
        userId: widget.userId,
        subtotal: widget.cartSubtotal,
        discount: widget.discount, // 👈 Pulling it directly from widget.discount
        shippingFee: shippingFeeStr,
        finalTotal: _finalGrandTotal, // 👈 Uses the new getter (after discount + shipping)
        addressLine1: _addr1Controller.text.trim(),
        addressLine2: _addr2Controller.text.trim().isEmpty ? null : _addr2Controller.text.trim(),
        postcode: _postcodeController.text.trim(),
        city: _cityController.text.trim(),
        state: _selectedState!,
        region: region,
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        if (response['status'] == 'success') {
          _showResultDialog(true, "Transaction Approved!", "Order #${response['order_id']} placed successfully.");
        } else {
          _showResultDialog(false, "System Error", response['message'] ?? "Checkout failed.");
        }
      }
    } else {
      setState(() => _isProcessing = false);
      _showResultDialog(false, "Card Declined", "The card number was rejected by the mock bank. Try using 4242 4242 4242 4242.");
    }
  }

  void _showResultDialog(bool isSuccess, String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error, 
              color: isSuccess ? Colors.green : Colors.red
            ),
            const SizedBox(width: 10),
            // 🚀 THE FIX: Expanded keeps the text within the bounds of the screen!
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              if (isSuccess) Navigator.pop(context, true); // Send true back to cart!
            },
            child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF91462E))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const colorPrimary = Color(0xFF91462E);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📦 Totals Box
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(12), 
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]
                ),
                child: Column(
                  children: [
                    _summaryRow("Cart Subtotal", "RM ${widget.cartSubtotal.toStringAsFixed(2)}"),
                    const SizedBox(height: 5),
                    
                    // 🏷️ NEW: Shows the discount applied!
                    if (widget.discount > 0) ...[
                      _summaryRow(
                        "Discount Applied", 
                        "-RM ${widget.discount.toStringAsFixed(2)}", 
                        valueColor: Colors.red
                      ),
                      const SizedBox(height: 5),
                    ],
                    
                    // 🚚 UPDATED: Shows "FREE" instead of RM 0.00
                    _summaryRow(
                      "Shipping", 
                      _shippingFee == 0.00 ? "FREE" : "RM ${_shippingFee.toStringAsFixed(2)}",
                      valueColor: _shippingFee == 0.00 ? Colors.green : Colors.black
                    ),
                    const Divider(height: 20),
                    _summaryRow("Total Amount Due", "RM ${_finalGrandTotal.toStringAsFixed(2)}", isBold: true, valueColor: colorPrimary),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // 🏠 Multi-line address
              const Text("Shipping Address (Malaysia)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              TextFormField(
                controller: _addr1Controller,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Address Line 1', hintText: 'Unit, Floor, Building'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              
              TextFormField(
                controller: _addr2Controller,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Address Line 2 (Optional)', hintText: 'Street Name, Area'),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _postcodeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [LengthLimitingTextInputFormatter(5), FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Postcode', hintText: '50000'),
                      validator: (val) => val!.length < 5 ? 'Invalid' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'City'),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'State'),
                items: [..._westMalaysia, ..._eastMalaysia].map((state) {
                  return DropdownMenuItem(value: state, child: Text(state));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedState = val;
                  });
                },
                validator: (val) => val == null ? 'Please select a state' : null,
              ),
              
              const SizedBox(height: 30),

              // 💳 Dummy Gateway Card Inputs
              const Text("Card Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, CardNumberFormatter()],
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Card Number', hintText: '4242 4242 4242 4242', prefixIcon: Icon(Icons.credit_card)),
                validator: (val) => val!.replaceAll(' ', '').length < 16 ? 'Enter a valid 16-digit number' : null,
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, CardExpirationFormatter()],
                      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Expiry Date', hintText: 'MM/YY'),
                      validator: (val) => val!.length < 5 ? 'Invalid' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'CVV', hintText: '123'),
                      validator: (val) => val!.length < 3 ? 'Invalid CVV' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _simulatePayment,
                  style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Pay Securely", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String title, String amount, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14)),
        Text(amount, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 18 : 14, color: valueColor ?? Colors.black)),
      ],
    );
  }
}

class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(' ', '');
    if (text.length > 16) text = text.substring(0, 16);
    
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      int index = i + 1;
      if (index % 4 == 0 && index != text.length) {
        buffer.write(' ');
      }
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class CardExpirationFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll('/', '');
    if (text.length > 4) text = text.substring(0, 4);
    
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && text.length > 2) {
        buffer.write('/');
      }
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}