import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart';

class RefundRequestPage extends StatefulWidget {
  final String orderId;
  final String userId;

  const RefundRequestPage({super.key, required this.orderId, required this.userId});

  @override
  State<RefundRequestPage> createState() => _RefundRequestPageState();
}

class _RefundRequestPageState extends State<RefundRequestPage> {
  final _formKey = GlobalKey<FormState>();
  
  List<dynamic> _orderItems = [];

  final List<Map<String, dynamic>> _selectedItemsWithQty = [];
  final List<File> _proofFiles = [];

  // Map<String, dynamic>? _selectedItem;

  // int _quantity = 1;
  // double _calculatedRefund = 0.0;
  
  String? _selectedReason;
  final TextEditingController _descController = TextEditingController();
  // File? _proofFile;
  bool _isLoadingItems = true;
  bool _isSubmitting = false;

  final List<String> _reasons = ["Did not receive", "Received broken", "Allergy"];

  // THEME COLORS (Synced with Edit Profile)
  static const colorPrimary = Color(0xFF91462E);
  static const colorSurface = Color(0xFFF7F6F3);

  @override
  void initState() {
    super.initState();
    _fetchOrderItems();
  }

  Future<void> _fetchOrderItems() async {
    try {
      final res = await ApiService.getOrderItems(widget.orderId);
      if (mounted) {
        setState(() {
          // Based on your get_order_details.php, items are nested: res['order']['items']
          // Adjust this line if your ApiService already flattens it
          _orderItems = res['items'] ?? []; 
          _isLoadingItems = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingItems = false);
    }
  }

  // void _updatePrice() {
  //   if (_selectedItem != null) {
  //     String rawPrice = _selectedItem!['price'].toString().replaceAll('RM ', '').replaceAll(',', '');
  //     double price = double.tryParse(rawPrice) ?? 0.0;
  //     setState(() => _calculatedRefund = price * _quantity);
  //   }
  // }

  double get _calculatedRefund {
    double total = 0;
    for (var selected in _selectedItemsWithQty) {
      String rawPrice = selected['item']['price'].toString().replaceAll('RM ', '').replaceAll(',', '');
      double price = double.tryParse(rawPrice) ?? 0.0;
      int qty = selected['quantity'] as int;
      total += (price * qty);
    }
    return total;
  }

  Future<void> _handleAttachment() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: colorPrimary),
              title: const Text('Take Photo', style: TextStyle(fontFamily: 'Plus Jakarta Sans')),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: colorPrimary),
              title: const Text('Choose from Gallery', style: TextStyle(fontFamily: 'Plus Jakarta Sans')),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: colorPrimary),
              title: const Text('Upload PDF Document', style: TextStyle(fontFamily: 'Plus Jakarta Sans')),
              onTap: () { Navigator.pop(context); _pickFile(); }, // Your existing file_picker logic
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source, imageQuality: 80); // Compressed for faster PHP upload

    if (image != null) {
      setState(() => _proofFiles.add(File(image.path)));
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'pdf'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() => _proofFiles.add(File(result.files.single.path!)));
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // 1. Initial trigger with confirmation dialog
  Future<void> _submit() async {
    // if (!_formKey.currentState!.validate() || _selectedItem == null || _proofFile == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text("Please complete all fields & upload proof"))
    //   );
    //   return;
    // }

    if (!_formKey.currentState!.validate()) return;

    if (_selectedItemsWithQty.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one item to refund."))
      );
      return;
    }

    if (_proofFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload at least one proof image or document."))
      );
      return;
    }

    // 💡 CONFIRMATION DIALOG
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Confirm Submission", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to submit this refund request? Please ensure all details are correct."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _executeApiCall();      // Trigger the actual upload
            },
            child: const Text("SUBMIT", style: TextStyle(color: colorPrimary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 2. The actual API execution
  Future<void> _executeApiCall() async {
    setState(() => _isSubmitting = true);
    
    try {
      List<Map<String, dynamic>> itemsPayload = _selectedItemsWithQty.map((e) {
        String rawPrice = e['item']['price'].toString().replaceAll('RM ', '').replaceAll(',', '');
        double price = double.tryParse(rawPrice) ?? 0.0;
        int qty = e['quantity'] as int;
        
        return {
          'product_id': e['item']['product_id'].toString(),
          'quantity': qty,
          'amount': price * qty
        };
      }).toList();

      final res = await ApiService.submitRefundRequest(
        orderId: widget.orderId,
        userId: widget.userId,
        // productId: _selectedItem!['product_id'].toString(),
        reason: _selectedReason!,
        description: _descController.text,
        // quantity: _quantity,
        // amount: _calculatedRefund,
        // file: _proofFile!,
        totalAmount: _calculatedRefund,
        items: itemsPayload,
        proofFiles: _proofFiles,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (res['status'] == 'success') {
          _showSuccessFeedback(); // 💡 SHOW SUCCESS MESSAGE
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? "Submission failed"))
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e"))
      );
    }
  }

  // Matching Input Decoration from Edit Profile
  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(icon, color: colorPrimary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  void _showSuccessFeedback() {
    showModalBottomSheet(
      context: context,
      isDismissible: false, // Force user to click the button
      enableDrag: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text(
              "Request Submitted!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans'),
            ),
            const SizedBox(height: 12),
            const Text(
              "Your refund request has been successfully submitted. Our team will review your request. Please wait for approval.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close Sheet
                  Navigator.pop(context, true); // Go back to History with refresh signal
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text("BACK TO ORDERS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorSurface,
      appBar: AppBar(
        title: Text(
          "Refund Request #${widget.orderId}", 
          style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, color: colorPrimary),
        ),
        centerTitle: true,
        backgroundColor: colorSurface,
        elevation: 0,
        foregroundColor: colorPrimary,
      ),
      body: _isLoadingItems 
        ? const Center(child: CircularProgressIndicator(color: colorPrimary)) 
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Request Details", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorPrimary, fontFamily: 'Plus Jakarta Sans'),
                  ),
                  const SizedBox(height: 20),

                  const Text("Select Items to Return", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  _orderItems.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text("No items available for return.", style: TextStyle(color: Colors.grey, fontFamily: 'Plus Jakarta Sans')),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _orderItems.length,
                          itemBuilder: (context, index) {
                            final item = _orderItems[index];
                            
                            // Identify if this row exists inside the user's active choice list array
                            final selectedIdx = _selectedItemsWithQty.indexWhere((element) => element['item']['product_id'] == item['product_id']);
                            final isChecked = selectedIdx != -1;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  CheckboxListTile(
                                    activeColor: colorPrimary,
                                    title: Text(
                                      "${item['brand'].toString().toUpperCase()} ${item['name'] ?? "Unknown Product"}",
                                      style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                    ),
                                    subtitle: Text(
                                      "Price: RM ${double.tryParse(item['price'].toString().replaceAll('RM ', '').replaceAll(',', ''))?.toStringAsFixed(2) ?? '0.00'} • Purchased Qty: ${item['qty']}",
                                      style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12),
                                    ),
                                    value: isChecked,
                                    onChanged: (bool? checked) {
                                      setState(() {
                                        if (checked == true) {
                                          _selectedItemsWithQty.add({
                                            'item': item,
                                            'quantity': 1,
                                          });
                                        } else {
                                          _selectedItemsWithQty.removeAt(selectedIdx);
                                        }
                                      });
                                    },
                                  ),
                                  // Only display quantity controls if this specific item is checked
                                  if (isChecked) ...[
                                    const Divider(height: 1, indent: 16, endIndent: 16),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 4),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text("Quantity to refund:", style: TextStyle(fontSize: 13, color: Colors.grey, fontFamily: 'Plus Jakarta Sans')),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove_circle_outline, color: colorPrimary, size: 22), 
                                                onPressed: _selectedItemsWithQty[selectedIdx]['quantity'] > 1 
                                                    ? () => setState(() => _selectedItemsWithQty[selectedIdx]['quantity']--) 
                                                    : null,
                                              ),
                                              Text(
                                                "${_selectedItemsWithQty[selectedIdx]['quantity']}", 
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Plus Jakarta Sans'),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.add_circle_outline, color: colorPrimary, size: 22), 
                                                onPressed: _selectedItemsWithQty[selectedIdx]['quantity'] < int.parse(item['qty'].toString()) 
                                                    ? () => setState(() => _selectedItemsWithQty[selectedIdx]['quantity']++) 
                                                    : null,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    )
                                  ]
                                ],
                              ),
                            );
                          },
                        ),

                  const SizedBox(height: 0),
                  const Text("Reason for Refund", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedReason,
                    style: const TextStyle(fontFamily: 'Plus Jakarta Sans', color: Colors.black, fontWeight: FontWeight.w500),
                    decoration: _inputDecoration("Select Reason", Icons.help_outline),
                    items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) => setState(() => _selectedReason = val),
                    validator: (v) => v == null ? "Required" : null,
                  ),

                  const SizedBox(height: 20),
                  const Text("Details", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w500),
                    decoration: _inputDecoration("Describe the issue...", Icons.description_outlined),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),

                  const SizedBox(height: 20),
                  const Text("Proof Attachments (At least 1 required)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  
                  // 🌟 REPLACED: Multi-Image Grid Layout + Interactive Attacher Hub
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(12),
                      border: _proofFiles.isNotEmpty ? Border.all(color: colorPrimary.withOpacity(0.3), width: 1) : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_proofFiles.isNotEmpty) ...[
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                            itemCount: _proofFiles.length,
                            itemBuilder: (context, idx) {
                              final file = _proofFiles[idx];
                              final isPdf = file.path.toLowerCase().endsWith('.pdf');
                              
                              return Stack(
                                children: [
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: isPdf
                                          ? Container(
                                              color: colorSurface,
                                              child: const Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
                                                  SizedBox(height: 4),
                                                  Text("PDF", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            )
                                          : Image.file(file, fit: BoxFit.cover),
                                    ),
                                  ),
                                  // Remove image tag button overlay
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _proofFiles.removeAt(idx)),
                                      child: CircleAvatar(
                                        radius: 10,
                                        backgroundColor: Colors.black.withOpacity(0.7),
                                        child: const Icon(Icons.close, size: 12, color: Colors.white),
                                      ),
                                    ),
                                  )
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Add additional files action bar trigger
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: _handleAttachment,
                            icon: const Icon(Icons.add_a_photo_outlined, size: 18, color: colorPrimary),
                            label: Text(
                              _proofFiles.isEmpty ? "Upload Photo or Document" : "Add More Proof Items",
                              style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600, color: colorPrimary, fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: colorPrimary, width: 1.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  
                  // Live calculation box updates dynamically across getter properties
                  if (_selectedItemsWithQty.isNotEmpty) ...[
                    Center(
                      child: Text(
                        "Total Refund: RM ${_calculatedRefund.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorPrimary, fontFamily: 'Plus Jakarta Sans'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // SAVE/SUBMIT REQUEST TRIGGER BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text(
                              "SUBMIT REQUEST", 
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 13),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}