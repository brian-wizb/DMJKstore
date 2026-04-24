import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminOrdersScreen extends StatefulWidget {
  static const routeName = '/admin-orders';
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String _selectedFilter = 'all';

  Future<void> _markOrderOpened(String orderId) async {
    final docRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
    final doc = await docRef.get();
    final data = doc.data();
    if (doc.exists) {
      final opened =
          data != null && data.containsKey('opened') ? data['opened'] : null;
      if (opened == false || opened == null) {
        await docRef.update({'opened': true});
      }
    }
  }

  Future<void> _markCompleted(String orderId) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .update({'status': 'completed'});
  }

  Future<void> _deleteOrder(String orderId) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).delete();
  }

  Future<String?> _getProductImage(String productId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();

      final data = doc.data();
      if (data != null &&
          data['mediaUrls'] != null &&
          (data['mediaUrls'] as List).isNotEmpty) {
        return data['mediaUrls'][0];
      }
    } catch (e) {
      debugPrint('Error getting product image: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
          // Filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Icon(Icons.filter_list, color: Colors.green.shade700, size: 18),
                  const SizedBox(width: 8),
                  ...[
                    {'value': 'all', 'label': 'All Orders'},
                    {'value': 'pickup', 'label': 'Pickup'},
                    {'value': 'delivery', 'label': 'Delivery'},
                  ].map((entry) {
                    final selected = _selectedFilter == entry['value'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedFilter = entry['value']!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: selected ? Colors.green.shade700 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            entry['label']!,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Orders list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: Colors.green.shade700));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No orders found.', style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                      ],
                    ),
                  );
                }

                final orders = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (_selectedFilter == 'all') return true;
                  return data['orderType'] == _selectedFilter;
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  itemBuilder: (ctx, i) {
                    final doc = orders[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final timestamp = data['timestamp'] as Timestamp?;
                    final formattedDate = timestamp != null
                        ? DateFormat('MMM d, yyyy • h:mm a').format(timestamp.toDate())
                        : 'N/A';

                    final items = data['items'] ?? [];
                    final bool isNew = !(data.containsKey('opened') && data['opened'] == true);
                    final String status = data['status'] ?? 'pending';
                    final String orderType = data['orderType'] ?? '';
                    final bool isDelivery = orderType == 'delivery';

                    double total = 0;
                    for (var item in items) {
                      total += (item['quantity'] ?? 0) * (item['price']?.toDouble() ?? 0.0);
                    }

                    return Dismissible(
                      key: Key(doc.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_outline, color: Colors.white),
                            SizedBox(height: 4),
                            Text('Delete', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Order'),
                            content: const Text('Are you sure you want to delete this order?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (_) => _deleteOrder(doc.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: isNew ? Border.all(color: Colors.red.shade300, width: 1.5) : null,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: ExpansionTile(
                          onExpansionChanged: (expanded) {
                            if (expanded) _markOrderOpened(doc.id);
                          },
                          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          title: Row(
                            children: [
                              Container(
                                width: 38, height: 38,
                                decoration: BoxDecoration(
                                  color: isDelivery ? Colors.blue.shade50 : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isDelivery ? Icons.local_shipping_outlined : Icons.store_outlined,
                                  color: isDelivery ? Colors.blue.shade600 : Colors.green.shade600,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['customerName'] ?? data['userEmail'] ?? 'Unknown',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _statusChip(isNew ? 'NEW' : status),
                                  const SizedBox(height: 4),
                                  Text(
                                    'TZS ${total.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}',
                                    style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(left: 48, bottom: 6),
                            child: Wrap(
                              spacing: 8,
                              children: [
                                if (data['phone'] != null && (data['phone'] as String).isNotEmpty)
                                  _infoChip(Icons.phone_outlined, data['phone']),
                                _infoChip(isDelivery ? Icons.local_shipping_outlined : Icons.store_outlined, orderType),
                                if (isDelivery && data['address'] != null)
                                  _infoChip(Icons.location_on_outlined, data['address']),
                              ],
                            ),
                          ),
                          children: [
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                              child: Column(
                                children: [
                                  ...items.map<Widget>((item) {
                                    final String? productId = item['productId'];
                                    if (productId == null || productId.isEmpty) {
                                      return _orderItemTile(null, item);
                                    }
                                    return FutureBuilder<String?>(
                                      future: _getProductImage(productId),
                                      builder: (ctx, snap) => _orderItemTile(snap.data, item),
                                    );
                                  }),
                                  const Divider(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      Text(
                                        'TZS ${total.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}',
                                        style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (status != 'completed')
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _markCompleted(doc.id),
                                        icon: const Icon(Icons.check_circle_outline, size: 18),
                                        label: const Text('Mark as Completed'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green.shade700,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          elevation: 0,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.green.shade600, size: 18),
                                          const SizedBox(width: 6),
                                          Text('Order Completed', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String label) {
    Color bg;
    Color fg;
    switch (label.toLowerCase()) {
      case 'new': bg = Colors.red.shade50; fg = Colors.red.shade700; break;
      case 'completed': bg = Colors.green.shade50; fg = Colors.green.shade700; break;
      default: bg = Colors.orange.shade50; fg = Colors.orange.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label.toUpperCase(), style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade500),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderItemTile(String? imageUrl, dynamic item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48, height: 48,
              child: imageUrl != null
                  ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade100, child: const Icon(Icons.image_not_supported, size: 20)))
                  : Container(color: Colors.grey.shade100, child: const Icon(Icons.image_not_supported, size: 20)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                Text('${item['quantity']}× TZS ${item['price']}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          Text(
            'TZS ${((item['price'] ?? 0) * (item['quantity'] ?? 0)).toStringAsFixed(0)}',
            style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
