import 'package:flutter/material.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  String phone = '';
  String address = '';
  String method = 'pickup';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Checkout')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField(
                initialValue: method,
                onChanged: (value) => setState(() => method = value.toString()),
                items: [
                  DropdownMenuItem(value: 'pickup', child: Text('Pickup at Store')),
                  DropdownMenuItem(value: 'delivery', child: Text('Delivery')),
                ],
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Phone Number'),
                validator: (val) => val!.isEmpty ? 'Enter phone' : null,
                onSaved: (val) => phone = val!,
              ),
              if (method == 'delivery')
                TextFormField(
                  decoration: InputDecoration(labelText: 'Delivery Address'),
                  validator: (val) =>
                      method == 'delivery' && val!.isEmpty ? 'Enter address' : null,
                  onSaved: (val) => address = val!,
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text('Order Placed'),
                        content: Text(
                            method == 'pickup'
                                ? 'Your order will be prepared for pickup.'
                                : 'Your order will be delivered to $address.\nWe will contact you at $phone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context)
                                .popUntil((route) => route.isFirst),
                            child: Text('OK'),
                          )
                        ],
                      ),
                    );
                  }
                },
                child: Text('Place Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
