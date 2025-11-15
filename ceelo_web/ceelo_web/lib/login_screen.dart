
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'game_user.dart';
import 'main_menu_screen.dart';



class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  //final TextEditingController registerEmailController = TextEditingController();
  final TextEditingController resetPasswordController = TextEditingController();

  void login(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);
        final doc = await userDoc.get();
        if (!doc.exists){
          await userDoc.set({
            'username': user.email,
            'bankAccount': 1000000,
            'wins': 0,
            'losses': 0,
            'avatarUrl': '',
            'isOnline': true,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        await createUserInFirestore(user);
      }
      // ignore: use_build_context_synchronously
      Navigator.pushReplacementNamed(context, '/mainmenu'); // Go to Main Menu screen
    } catch (e) {
      // ignore: avoid_print
      print('Login error: $e');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    
    }
  }
  Future<GameUser?> fetchUserProfile() async{
    final user = FirebaseAuth.instance.currentUser;
    if(user != null){
      final userDoc = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid);
      await userDoc.get();
      
    }
    return null;
  }
 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
              TextField(controller: passwordController, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
              SizedBox(height: 30),
              ElevatedButton(onPressed: () => login(context), child: Text('Login')),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: Text('Register'),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/reset'),
                child: Text('Forgot Password?'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    UserCredential userCredential = await FirebaseAuth.instance
                    .signInWithEmailAndPassword(email: emailController.text.trim(), password: passwordController.text.trim());

                    await createUserInFirestore(userCredential.user!);

                    Navigator.pushReplacement(
                      // ignore: use_build_context_synchronously
                      context,
                      MaterialPageRoute(builder: (context) => MainMenuScreen()),
                    );
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: resetPasswordController.text.trim());
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Password reset email sent')),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    // ignore: avoid_print
                    print('Password reset error: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                },
                child: Text('Send Password Reset Email'),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> createUserInFirestore(User user) async{
    final userRef =FirebaseFirestore.instance.collection('users').doc(user.uid);

    final doc = await userRef.get();
    if(!doc.exists){
      await userRef.set({
        'username': user.email,
        'bankAccount': 1000000,
        'wins': 0,
        'losses': 0,
        'avatarUrl': '',
        'isOnline': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
