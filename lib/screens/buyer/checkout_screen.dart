// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kisanbazaar/screens/buyer/order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.totalAmount,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPaymentMethod = "Cash on Delivery";

  Future<void> placeOrder() async {
    print("Placing order...");

    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print("User not logged in!");
      return;
    }

    FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // Create the order document
      DocumentReference orderRef = await firestore.collection('orders').add({
        'buyerId': userId,
        'items': widget.cartItems,
        'totalAmount': widget.totalAmount,
        'status': 'Pending',
        'paymentMethod': _selectedPaymentMethod,
        'orderDate': DateTime.now().toIso8601String(),
      });

      String orderId = orderRef.id;
      print("Order placed with ID: $orderId");

      for (var item in widget.cartItems) {
        String? sellerId = item['sellerId']; // Ensure this is not null

        if (sellerId == null) {
          print("Error: Seller ID is null for product ${item['name']}");
          continue; // Skip this item to prevent crashes
        }

        // Reduce product stock
        DocumentReference productRef = firestore
            .collection('products')
            .doc(item['productId']);
        DocumentSnapshot productSnapshot = await productRef.get();

        if (productSnapshot.exists) {
          int newQuantity =
              (productSnapshot['quantity'] ?? 0) - item['quantity'];
          await productRef.update({'quantity': newQuantity});
          print("Updated stock for ${item['name']} to $newQuantity");
        } else {
          print("Product ${item['productId']} not found!");
        }

        // Store order under seller's collection
        await firestore
            .collection('sellers')
            .doc(sellerId)
            .collection('orders')
            .doc(orderId)
            .set({
              'orderId': orderId,
              'buyerId': userId,
              'productId': item['productId'],
              'productName': item['name'],
              'quantity': item['quantity'],
              'price': item['price'],
              'totalAmount': widget.totalAmount,
              'status': 'Pending',
              'paymentMethod': _selectedPaymentMethod,
              'orderDate': DateTime.now().toIso8601String(),
            });

        print("Order added to seller's collection for ${item['name']}");

        // Notify seller
        await firestore.collection('notifications').add({
          'sellerId': sellerId,
          'message': "You have a new order for ${item['name']}",
          'orderId': orderId,
          'timestamp': DateTime.now().toIso8601String(),
        });

        print("Seller notified about ${item['name']}");
      }

      // Navigate to Order Confirmation Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => OrderConfirmationScreen(
                orderId: orderId,
                totalPrice: widget.totalAmount,
                paymentMethod: _selectedPaymentMethod,
              ),
        ),
      );
    } catch (e) {
      print("Error placing order: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Order Summary",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.cartItems.length,
                itemBuilder: (context, index) {
                  var item = widget.cartItems[index];
                  return ListTile(
                    leading:
                        item['image'] != null && item['image'].isNotEmpty
                            ? Image.memory(
                              base64Decode(
                                item['image'].split(',').last,
                              ), // ✅ Decode correctly
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                            : const Icon(Icons.image, size: 50),

                    title: Text(item['name']),
                    subtitle: Text(
                      "Qty: ${item['quantity']} | Price: ₹${item['price']}",
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Select Payment Method",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ListTile(
              title: const Text("Cash on Delivery"),
              leading: Radio(
                value: "Cash on Delivery",
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value.toString();
                  });
                },
              ),
            ),
            // Add more payment options here
            const SizedBox(height: 10),
            Text(
              "Total: ₹${widget.totalAmount}",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: placeOrder,
                child: const Text(
                  "Place Order",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
