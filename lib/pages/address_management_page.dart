import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class AddressManagementPage extends StatefulWidget {
  final String userId;
  const AddressManagementPage({super.key, required this.userId});

  @override
  State<AddressManagementPage> createState() => _AddressManagementPageState();
}

class _AddressManagementPageState extends State<AddressManagementPage> {
  List<dynamic> _addresses = [];
  bool _isLoading = true;

  static const colorPrimary = Color(0xFF91462E);
  static const colorSurface = Color(0xFFF7F6F3);

  final List<String> _westMalaysia = [
    'Johor', 'Kedah', 'Kelantan', 'Melaka', 'Negeri Sembilan', 
    'Pahang', 'Pulau Pinang', 'Perak', 'Perlis', 'Selangor', 
    'Terengganu', 'Kuala Lumpur', 'Putrajaya'
  ];
  final List<String> _eastMalaysia = ['Sabah', 'Sarawak', 'Labuan'];

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getAddresses(widget.userId);
    setState(() {
      _addresses = data;
      _isLoading = false;
    });
  }

  // Formats raw phone number (e.g., 60123456789 or 123456789) to (+60) 12-345 6789 or (+60) 12-3456 7890
  String _formatPhoneDisplay(String? rawPhone) {
    if (rawPhone == null || rawPhone.isEmpty) return '';
    String digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('60')) {
      digits = digits.substring(2);
    }

    if (digits.length == 9) {
      return '(+60) ${digits.substring(0, 2)}-${digits.substring(2, 5)} ${digits.substring(5)}';
    } else if (digits.length == 10) {
      return '(+60) ${digits.substring(0, 2)}-${digits.substring(2, 6)} ${digits.substring(6)}';
    }
    return rawPhone;
  }

  Future<void> _setDefault(String addressId) async {
    final success = await ApiService.setDefaultAddress(addressId, widget.userId);
    if (success) {
      _fetchAddresses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default address updated'), backgroundColor: Colors.green),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update default address'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteAddress(String addressId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Address', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to remove this address?', style: TextStyle(fontFamily: 'Plus Jakarta Sans')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Plus Jakarta Sans', color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(fontFamily: 'Plus Jakarta Sans', color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ApiService.deleteAddress(addressId, widget.userId);
      if (success) {
        _fetchAddresses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address deleted'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete address'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _openAddressForm({Map<String, dynamic>? addressToEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: _AddressFormSheet(
          userId: widget.userId,
          addressToEdit: addressToEdit,
          westMalaysia: _westMalaysia,
          eastMalaysia: _eastMalaysia,
          onSaved: () {
            Navigator.pop(context);
            _fetchAddresses();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorSurface,
      appBar: AppBar(
        title: const Text(
          "My Saved Addresses",
          style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, color: colorPrimary),
        ),
        centerTitle: true,
        backgroundColor: colorSurface,
        elevation: 0,
        foregroundColor: colorPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: colorPrimary))
          : _addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // const Icon(Icons.location_off_outlined, size: 64, color: Colors.grey),
                      // const SizedBox(height: 16),
                      const Text(
                        "No saved addresses yet.",
                        style: TextStyle(fontFamily: 'Plus Jakarta Sans', color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 0,
                          ),
                          onPressed: () => _openAddressForm(),
                          child: const Text(
                            "ADD NEW ADDRESS",
                            style: TextStyle(color: Colors.white, fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  itemCount: _addresses.length,
                  itemBuilder: (context, index) {
                    final addr = _addresses[index];
                    final isDefault = addr['is_default'] == 1;
                    final formattedPhone = _formatPhoneDisplay(addr['phone']);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDefault ? colorPrimary : Colors.transparent,
                          width: isDefault ? 2 : 0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  addr['recipient_name'] ?? '',
                                  style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 16, color: colorPrimary),
                                ),
                                if (isDefault)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colorPrimary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      "Default",
                                      style: TextStyle(color: colorPrimary, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans'),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Phone: $formattedPhone",
                              style: const TextStyle(color: Colors.grey, fontSize: 13, fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "${addr['address_line_1']}${addr['address_line_2'] != null && addr['address_line_2'].isNotEmpty ? ', ${addr['address_line_2']}' : ''}",
                              style: const TextStyle(fontSize: 14, fontFamily: 'Plus Jakarta Sans', color: Colors.black87),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${addr['postcode']} ${addr['city']}, ${addr['state']}, ${addr['region']}",
                              style: const TextStyle(fontSize: 14, fontFamily: 'Plus Jakarta Sans', color: Colors.black87),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (!isDefault)
                                  TextButton(
                                    onPressed: () => _setDefault(addr['id'].toString()),
                                    child: const Text(
                                      "Set as Default",
                                      style: TextStyle(color: colorPrimary, fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20, color: colorPrimary),
                                  onPressed: () => _openAddressForm(addressToEdit: addr),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                  onPressed: () => _deleteAddress(addr['id'].toString()),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: _addresses.isNotEmpty
          ? FloatingActionButton(
              backgroundColor: colorPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              onPressed: () => _openAddressForm(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _AddressFormSheet extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? addressToEdit;
  final List<String> westMalaysia;
  final List<String> eastMalaysia;
  final VoidCallback onSaved;

  const _AddressFormSheet({
    required this.userId,
    this.addressToEdit,
    required this.westMalaysia,
    required this.eastMalaysia,
    required this.onSaved,
  });

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addr1Ctrl;
  late TextEditingController _addr2Ctrl;
  late TextEditingController _postcodeCtrl;
  late TextEditingController _cityCtrl;
  String? _selectedState;
  bool _isDefault = false;
  bool _isSaving = false;

  static const colorPrimary = Color(0xFF91462E);

  @override
  void initState() {
    super.initState();
    final edit = widget.addressToEdit;
    
    String rawPhone = edit?['phone'] ?? '';
    if (rawPhone.startsWith('60')) rawPhone = rawPhone.substring(2);

    _nameCtrl = TextEditingController(text: edit?['recipient_name'] ?? '');
    _phoneCtrl = TextEditingController(text: rawPhone);
    _addr1Ctrl = TextEditingController(text: edit?['address_line_1'] ?? '');
    _addr2Ctrl = TextEditingController(text: edit?['address_line_2'] ?? '');
    _postcodeCtrl = TextEditingController(text: edit?['postcode'] ?? '');
    _cityCtrl = TextEditingController(text: edit?['city'] ?? '');
    
    final stateVal = edit?['state'];
    if ([...widget.westMalaysia, ...widget.eastMalaysia].contains(stateVal)) {
      _selectedState = stateVal;
    }
    _isDefault = edit?['is_default'] == 1;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    Map<String, dynamic> payload = {
      "user_id": widget.userId,
      "recipient_name": _nameCtrl.text.trim(),
      "phone": '60' + _phoneCtrl.text.trim(),
      "address_line_1": _addr1Ctrl.text.trim(),
      "address_line_2": _addr2Ctrl.text.trim(),
      "postcode": _postcodeCtrl.text.trim(),
      "city": _cityCtrl.text.trim(),
      "state": _selectedState,
      "region": "Malaysia",
      "is_default": _isDefault ? 1 : 0,
    };

    if (widget.addressToEdit != null) {
      payload["id"] = widget.addressToEdit!['id'];
    }

    final success = await ApiService.saveAddress(payload);
    setState(() => _isSaving = false);

    if (success) {
      widget.onSaved();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save address'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.addressToEdit == null ? "Add New Address" : "Edit Address",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorPrimary, fontFamily: 'Plus Jakarta Sans'),
            ),
            const SizedBox(height: 20),

            const Text("Contact Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans')),
            const SizedBox(height: 10),

            TextFormField(
              controller: _nameCtrl,
              style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (val) => val!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),

            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.number,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Phone Number',
                hintText: '123456789',
                prefixText: '+60 ',
                prefixStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                counterText: "",
                prefixIcon: Icon(Icons.phone_android_rounded),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Required';
                if (val.length < 9 || val.length > 10) return 'Must be 9 or 10 digits';
                return null;
              },
            ),
            const SizedBox(height: 20),

            const Text("Shipping Address (Malaysia)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans')),
            const SizedBox(height: 10),
            
            TextFormField(
              controller: _addr1Ctrl,
              style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Address Line 1',
                hintText: 'Unit, Floor, Building',
              ),
              validator: (val) => val!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            
            TextFormField(
              controller: _addr2Ctrl,
              style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Address Line 2 (Optional)',
                hintText: 'Street Name, Area',
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _postcodeCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [LengthLimitingTextInputFormatter(5), FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Postcode',
                    ),
                    validator: (val) => (val == null || val.length < 5) ? 'Invalid' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _cityCtrl,
                    style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'City',
                    ),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: _selectedState,
              style: const TextStyle(fontFamily: 'Plus Jakarta Sans', color: Colors.black87),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'State',
              ),
              items: [...widget.westMalaysia, ...widget.eastMalaysia].map((state) {
                return DropdownMenuItem(value: state, child: Text(state));
              }).toList(),
              onChanged: (val) => setState(() => _selectedState = val),
              validator: (val) => val == null ? 'Please select a state' : null,
            ),
            const SizedBox(height: 10),

            CheckboxListTile(
              title: const Text("Set as default address", style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13, fontWeight: FontWeight.w500)),
              value: _isDefault,
              activeColor: colorPrimary,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (v) => setState(() => _isDefault = v ?? false),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        "SAVE ADDRESS",
                        style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans', letterSpacing: 1),
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}