import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/cart_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

class CartScreen extends StatefulWidget {
  static const routeName = '/cart';

  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _phone = '';
  String _address = '';

  bool _isSubmitting = false;

  // Store contact number
  final String storePhoneNumber = "0792177148";

  String _normalizeTzNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0') && digits.length == 10) {
      return '255${digits.substring(1)}';
    }
    if (digits.startsWith('255')) {
      return digits;
    }
    return digits;
  }

  Future<void> _launchWhatsApp() async {
    final number = _normalizeTzNumber(storePhoneNumber);
    final message = 'Hello DMJK Store, I need help with my order.';

    final appUri = Uri.parse(
      'whatsapp://send?phone=$number&text=${Uri.encodeComponent(message)}',
    );
    final waMeUri = Uri.parse(
      'https://wa.me/$number?text=${Uri.encodeComponent(message)}',
    );
    final webUri = Uri.parse(
      'https://api.whatsapp.com/send?phone=$number&text=${Uri.encodeComponent(message)}',
    );

    final launchedApp = await launchUrl(
      appUri,
      mode: LaunchMode.externalApplication,
    );
    if (launchedApp) {
      return;
    }

    final launchedWaMe = await launchUrl(
      waMeUri,
      mode: LaunchMode.externalApplication,
    );
    if (launchedWaMe) {
      return;
    }

    final launchedWeb = await launchUrl(
      webUri,
      mode: LaunchMode.externalApplication,
    );
    if (launchedWeb) {
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not open WhatsApp. Number: $storePhoneNumber'),
      ),
    );
  }

  Future<void> _launchPhoneCall() async {
    final uri = Uri.parse('tel:$storePhoneNumber');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open phone app on this device.')),
    );
  }

  // Generate PDF document
  Future<pw.Document> _generatePdfDocument(
      String type, List<Map<String, dynamic>> items) async {
    final pdf = pw.Document();

    final totalAmount = items.fold<num>(
      0,
      (sum, item) => sum + (item['price'] * item['quantity']),
    );

    final ttf =
        await rootBundle.load("assets/fonts/Roboto-VariableFont_wdth,wght.ttf");
    final font = pw.Font.ttf(ttf);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Padding(
          padding: const pw.EdgeInsets.all(20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Order Summary",
                  style: pw.TextStyle(
                      font: font,
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text("Customer: $_name", style: pw.TextStyle(font: font)),
              pw.Text("Phone: $_phone", style: pw.TextStyle(font: font)),
              if (type == 'delivery')
                pw.Text("Address: $_address", style: pw.TextStyle(font: font)),
              pw.Text("Order Type: $type", style: pw.TextStyle(font: font)),
              pw.SizedBox(height: 15),
              pw.Text("Items:",
                  style:
                      pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              ...items.map((item) => pw.Text(
                  "${item['quantity']}x ${item['title']} - TZS ${(item['price'] * item['quantity']).toInt()}",
                  style: pw.TextStyle(font: font))),
              pw.SizedBox(height: 15),
              pw.Text("Total: TZS ${totalAmount.toInt()}",
                  style:
                      pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text("Thank you for your order!",
                  style:
                      pw.TextStyle(font: font, fontStyle: pw.FontStyle.italic)),
            ],
          ),
        ),
      ),
    );

    return pdf;
  }

  // Preview order and then save PDF
  Future<void> _previewOrderBeforePdf(
      String type, List<Map<String, dynamic>> items) async {
    final totalAmount = items.fold<num>(
      0,
      (sum, item) => sum + (item['price'] * item['quantity']),
    );

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Order Preview'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Customer: $_name"),
                Text("Phone: $_phone"),
                if (type == 'delivery') Text("Address: $_address"),
                Text("Order Type: $type"),
                const SizedBox(height: 10),
                const Text("Items:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...items.map((item) => Text(
                    "${item['quantity']}x ${item['title']} - TZS ${(item['price'] * item['quantity']).toInt()}")),
                const SizedBox(height: 10),
                Text("Total: TZS ${totalAmount.toInt()}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (mounted) Navigator.of(ctx).pop();

                final pdf = await _generatePdfDocument(type, items);

                Directory? saveDir;
                if (Platform.isAndroid) {
                  saveDir = Directory('/storage/emulated/0/Download');
                } else {
                  saveDir = await getApplicationDocumentsDirectory();
                }

                final file = File(
                    "${saveDir.path}/order_summary_${DateTime.now().millisecondsSinceEpoch}.pdf");
                await file.writeAsBytes(await pdf.save());

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("PDF saved at ${file.path}")),
                );

                if (!mounted) return;
                await OpenFile.open(file.path);
              },
              child: const Text('Save PDF'),
            ),
          ],
        );
      },
    );
  }

  // Submit order to Firestore
  Future<void> _submitOrder(String type) async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final items = cart.items.values
        .map((item) => {
              'productId': item.id,
              'title': item.title,
              'quantity': item.quantity,
              'price': item.price,
            })
        .toList();

    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'DMJK CUSTOMER';

    if (items.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance.collection('orders').add({
        'items': items,
        'userEmail': email,
        'customerName': _name,
        'orderType': type,
        'phone': _phone,
        'address': type == 'delivery' ? _address : null,
        'timestamp': Timestamp.now(),
      });

      // ✅ Notification will be handled automatically by your Cloud Function

      cart.clearCart();

      if (!mounted) return;
      await _previewOrderBeforePdf(type, items);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order submitted successfully!')),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit order: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showDeliveryForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.local_shipping_outlined,
                        color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text('Delivery Details',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.green.shade800)),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration:
                      _inputDecoration('Full Name', Icons.person_outline),
                  onSaved: (value) => _name = value!.trim(),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration:
                      _inputDecoration('Phone Number', Icons.phone_outlined),
                  keyboardType: TextInputType.phone,
                  onSaved: (value) => _phone = value!.trim(),
                  validator: (val) => val == null || val.length < 10
                      ? 'Enter a valid number'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: _inputDecoration(
                      'Delivery Address', Icons.location_on_outlined),
                  onSaved: (value) => _address = value!.trim(),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter an address' : null,
                ),
                const SizedBox(height: 20),
                if (_isSubmitting)
                  const Center(child: CircularProgressIndicator())
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          Navigator.of(ctx).pop();
                          _submitOrder('delivery');
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Submit Delivery Order',
                          style: TextStyle(fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPickupForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.store_outlined, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text('Pickup at Store',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.green.shade800)),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration:
                      _inputDecoration('Full Name', Icons.person_outline),
                  onSaved: (value) => _name = value!.trim(),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration:
                      _inputDecoration('Phone Number', Icons.phone_outlined),
                  keyboardType: TextInputType.phone,
                  onSaved: (value) => _phone = value!.trim(),
                  validator: (val) => val == null || val.length < 10
                      ? 'Enter a valid number'
                      : null,
                ),
                const SizedBox(height: 20),
                if (_isSubmitting)
                  const Center(child: CircularProgressIndicator())
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          Navigator.of(ctx).pop();
                          _submitOrder('pickup');
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Submit Pickup Order',
                          style: TextStyle(fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.green.shade600, size: 20),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade600, width: 2)),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final cartItems = cart.items.values.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Shopping Cart',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (cartItems.isNotEmpty)
                        GestureDetector(
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Clear Cart'),
                              content: const Text(
                                  'Remove all items from your cart?'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () {
                                    cart.clearCart();
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Clear',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Clear',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 13)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: cartItems.isEmpty
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_cart_outlined,
                        size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('Your cart is empty',
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('Add items to start shopping',
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade400)),
                  ],
                ),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  children: [
                    // Cart items
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                        itemCount: cartItems.length,
                        itemBuilder: (ctx, i) {
                          final item = cartItems[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.07),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Quantity badge
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF1B5E20),
                                          Color(0xFF388E3C)
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${item.quantity}×',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Name & price
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(item.title,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Text(
                                          'TZS ${item.price.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')} each',
                                          style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Subtotal & delete
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'TZS ${(item.price * item.quantity).toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      GestureDetector(
                                        onTap: () => cart.removeItem(item.id),
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(Icons.delete_outline,
                                              color: Colors.red.shade400,
                                              size: 18),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Order summary & checkout
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, -3))
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  '${cartItems.length} item${cartItems.length == 1 ? '' : 's'}',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 14)),
                              Text(
                                'TZS ${cart.totalAmount.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}',
                                style: TextStyle(
                                    color: Colors.grey.shade700, fontSize: 14),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17)),
                              Text(
                                'TZS ${cart.totalAmount.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_isSubmitting)
                            const Center(child: CircularProgressIndicator())
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _showDeliveryForm,
                                    icon: const Icon(
                                        Icons.local_shipping_outlined,
                                        size: 18),
                                    label: const Text('Delivery'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.green.shade700,
                                      side: BorderSide(
                                          color: Colors.green.shade700,
                                          width: 1.5),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _showPickupForm,
                                    icon: const Icon(Icons.store_outlined,
                                        size: 18),
                                    label: const Text('Pickup'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade700,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3FAF3),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFDDEEDC)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _launchWhatsApp,
                                    icon: const FaIcon(
                                        FontAwesomeIcons.whatsapp,
                                        size: 16),
                                    label: const Text('WhatsApp'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF25D366),
                                      side: const BorderSide(
                                          color: Color(0xFF25D366), width: 1.4),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _launchPhoneCall,
                                    icon: const Icon(Icons.call, size: 16),
                                    label: const Text('Call Store'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade700,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
