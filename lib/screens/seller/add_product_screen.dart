// ignore_for_file: use_build_context_synchronously

import 'dart:convert' show base64Encode;
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _sellerNameController = TextEditingController();

  File? _image;
  final picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadProduct() async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        _categoryController.text.isEmpty ||
        _sellerNameController.text.isEmpty ||
        _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields and pick an image"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
          );
        },
      );

      List<int> imageBytes = await _image!.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      await FirebaseFirestore.instance.collection('products').add({
        'name': _nameController.text,
        'price': double.parse(_priceController.text),
        'quantity': int.parse(_quantityController.text),
        'category': _categoryController.text,
        'seller_name': _sellerNameController.text,
        'image': base64Image,
        'sellerId': FirebaseAuth.instance.currentUser!.uid,
        'created_at': FieldValue.serverTimestamp(),
      });

      // Close loading dialog
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Product added successfully"),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error adding product: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add Product",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4CAF50), Color(0xFFF5F5F5)],
            stops: [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Image picker section
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(75),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child:
                            _image == null
                                ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 50,
                                      color: Color(0xFF4CAF50),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Add Image",
                                      style: TextStyle(
                                        color: Color(0xFF4CAF50),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                                : ClipRRect(
                                  borderRadius: BorderRadius.circular(75),
                                  child: Image.file(_image!, fit: BoxFit.cover),
                                ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Form Container
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Product Information",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(
                          _nameController,
                          "Product Name",
                          Icons.shopping_cart_outlined,
                        ),

                        _buildTextField(
                          _priceController,
                          "Price (\$)",
                          Icons.attach_money,
                          TextInputType.number,
                        ),

                        // Quantity Field with KG suffix
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                _quantityController,
                                "Quantity",
                                Icons.scale_outlined,
                                TextInputType.number,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "KG",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            ),
                          ],
                        ),

                        _buildTextField(
                          _categoryController,
                          "Category",
                          Icons.category_outlined,
                        ),

                        _buildTextField(
                          _sellerNameController,
                          "Seller Name",
                          Icons.person_outline,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Add Product Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _uploadProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        "Add Product",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, [
    TextInputType keyboardType = TextInputType.text,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF4CAF50)),
          filled: true,
          fillColor: Colors.grey[50],
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
