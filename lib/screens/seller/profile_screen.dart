import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _mobileController = TextEditingController();
  String? name, email, imageUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(userId).get();

        if (userDoc.exists) {
          setState(() {
            name = userDoc['fullName'];
            email = userDoc['email'];
            _mobileController.text = userDoc['mobile'] ?? '';
            imageUrl = userDoc['image'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      String userId = _auth.currentUser!.uid;
      Reference storageRef = FirebaseStorage.instance.ref().child(
        'profile_images/$userId.jpg',
      );
      await storageRef.putFile(imageFile);
      String downloadUrl = await storageRef.getDownloadURL();

      await _firestore.collection('users').doc(userId).update({
        'image': downloadUrl,
      });
      setState(() {
        imageUrl = downloadUrl;
      });
    }
  }

  Future<void> _updateProfile() async {
    String userId = _auth.currentUser!.uid;
    await _firestore.collection('users').doc(userId).update({
      'mobile': _mobileController.text,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage:
                                imageUrl != null
                                    ? NetworkImage(imageUrl!)
                                    : null,
                            backgroundColor: Colors.grey.shade300,
                          ),
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green,
                                ),
                                padding: const EdgeInsets.all(6),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name ?? 'Name',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              email ?? 'Email',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _mobileController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Mobile Number',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon: const Icon(Icons.phone),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _updateProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'Update Profile',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
