import 'package:flutter/material.dart';
import '../services/api_service.dart';

class VoucherWalletPage extends StatefulWidget {
  final String userId;
  final double cartSubtotal;
  final bool isSelecting; // Set true when opened from checkout page

  const VoucherWalletPage({
    super.key,
    required this.userId,
    this.cartSubtotal = 0.0,
    this.isSelecting = false,
  });

  @override
  State<VoucherWalletPage> createState() => _VoucherWalletPageState();
}

class _VoucherWalletPageState extends State<VoucherWalletPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _vouchers = {'active': [], 'used': [], 'expired': []};

  final Color colorPrimary = const Color(0xFF91462E);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchVouchers();
  }

  Future<void> _fetchVouchers() async {
    setState(() => _isLoading = true);
    final response = await ApiService.getVouchers(widget.userId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response['status'] == 'success') {
          _vouchers = response['vouchers'];
        }
      });
    }
  }

  void _handleVoucherTap(Map<String, dynamic> voucher) {
    if (!widget.isSelecting) return;
    if (voucher['status'] != 'active') return;

    // Validate and compute discount via backend when selected at checkout
    ApiService.applyVoucher(widget.userId, voucher['voucher_code'], widget.cartSubtotal).then((res) {
      if (!mounted) return;
      if (res['status'] == 'success') {
        Navigator.pop(context, res); // Return selected voucher data back to checkout
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Cannot apply voucher'), backgroundColor: Colors.red[700]),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSelecting ? "Select Voucher" : "My Vouchers", style: TextStyle(fontWeight: FontWeight.bold, color: colorPrimary)),
        backgroundColor: const Color(0xFFF7F6F3),
        foregroundColor: colorPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorPrimary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: colorPrimary,
          tabs: const [
            Tab(text: "Active"),
            Tab(text: "Used"),
            Tab(text: "Expired"),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorPrimary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVoucherList(_vouchers['active'], isActionable: widget.isSelecting),
                _buildVoucherList(_vouchers['used'], isActionable: false),
                _buildVoucherList(_vouchers['expired'], isActionable: false),
              ],
            ),
    );
  }

  Widget _buildVoucherList(List<dynamic> vouchers, {required bool isActionable}) {
    if (vouchers.isEmpty) {
      return const Center(child: Text("No vouchers found", style: TextStyle(color: Colors.grey, fontSize: 15)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vouchers.length,
      itemBuilder: (context, index) {
        final v = vouchers[index];
        final bool isInactive = v['status'] != 'active';

        return Opacity(
          opacity: isInactive ? 0.6 : 1.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              border: Border.all(color: isActionable && !isInactive ? colorPrimary : Colors.transparent, width: 1.5),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isInactive ? Colors.grey[200] : colorPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  v['discount_type'] == 'free_shipping' ? Icons.local_shipping : Icons.discount,
                  color: isInactive ? Colors.grey : colorPrimary,
                ),
              ),
              title: Text(v['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text("Code: ${v['voucher_code']}", style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text("Valid until: ${v['expires_at']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              trailing: isActionable && !isInactive
                  ? ElevatedButton(
                      onPressed: () => _handleVoucherTap(v),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text("Use", style: TextStyle(color: Colors.white)),
                    )
                  : null,
              onTap: () => _handleVoucherTap(v),
            ),
          ),
        );
      },
    );
  }
}