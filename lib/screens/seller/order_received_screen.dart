import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OrderReceivedScreen extends StatefulWidget {
  const OrderReceivedScreen({super.key});

  @override
  State<OrderReceivedScreen> createState() => _OrderReceivedScreenState();
}

class _OrderReceivedScreenState extends State<OrderReceivedScreen> {
  String? sellerId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Orders")),
      body:
          sellerId == null
              ? const Center(child: Text("User not authenticated"))
              : StreamBuilder(
                stream:
                    FirebaseFirestore.instance
                        .collection("sellers")
                        .doc(sellerId)
                        .collection("orders")
                        .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No orders found"));
                  }

                  var orders = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      var order = orders[index].data() as Map<String, dynamic>;
                      return FutureBuilder(
                        future:
                            FirebaseFirestore.instance
                                .collection("users")
                                .doc(order['buyerId'])
                                .get(),
                        builder: (
                          context,
                          AsyncSnapshot<DocumentSnapshot> buyerSnapshot,
                        ) {
                          if (buyerSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          String buyerMobile =
                              buyerSnapshot.data?['mobile'] ?? "Unknown";
                          return Card(
                            margin: const EdgeInsets.all(10),
                            child: ListTile(
                              title: Text("Product: ${order['productName']}"),
                              subtitle: Text(
                                "Qty: ${order['quantity']} - Total: ₹${order['totalAmount']}",
                              ),
                              trailing: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "Status: ${order['status']}",
                                    style: TextStyle(
                                      color:
                                          order['status'] == 'Pending'
                                              ? Colors.orange
                                              : Colors.green,
                                    ),
                                  ),
                                  Text("Buyer: $buyerMobile"),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
    );
  }
}
