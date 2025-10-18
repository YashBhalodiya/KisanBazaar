import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kisanbazaar/screens/auth/login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? selectedRole;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Future<void> signup() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError("Passwords do not match");
      return;
    }
    if (selectedRole == null) {
      _showError("Please select a role");
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        "fullName": _fullNameController.text.trim(),
        "email": _emailController.text.trim(),
        "role": selectedRole,
        "image": null,
        "uid": userCredential.user!.uid,
        "createdAt": FieldValue.serverTimestamp(),
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = "An error occurred";
      if (e.code == 'email-already-in-use')
        errorMessage = "This email is already in use.";
      else if (e.code == 'weak-password')
        errorMessage = "The password is too weak.";
      _showError(errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade700, Colors.green.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Sign Up",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      _fullNameController,
                      "Full Name",
                      Icons.person,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(_emailController, "Email", Icons.email),
                    const SizedBox(height: 15),
                    _buildPasswordField(
                      _passwordController,
                      "Password",
                      _isPasswordVisible,
                      () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildPasswordField(
                      _confirmPasswordController,
                      "Confirm Password",
                      _isConfirmPasswordVisible,
                      () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildRoleDropdown(),
                    const SizedBox(height: 20),
                    _buildSignupButton(),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account?"),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Log in",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.green.shade700),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String label,
    bool isVisible,
    VoidCallback toggleVisibility,
  ) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.lock, color: Colors.green.shade700),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.green.shade700,
          ),
          onPressed: toggleVisibility,
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedRole,
      decoration: InputDecoration(
        labelText: "Select Role",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items:
          ["Buyer", "Seller"]
              .map(
                (role) => DropdownMenuItem(
                  value: role.toLowerCase(),
                  child: Text(role),
                ),
              )
              .toList(),
      onChanged: (value) => setState(() => selectedRole = value),
    );
  }

  Widget _buildSignupButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: _isLoading ? null : signup,
        child:
            _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                  "Sign Up",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
      ),
    );
  }
}
