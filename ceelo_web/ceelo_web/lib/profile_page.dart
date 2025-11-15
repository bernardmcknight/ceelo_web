import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ProfilePage extends StatefulWidget {
  final String userId;
  const ProfilePage({super.key, required this.userId});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage>{
  Map<String, dynamic>? userData;
  bool hasError = false;

  @override
  void initState(){
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async{
    try {
      final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(widget.userId)
      .get();

      if(userDoc.exists){
        setState((){
          userData = userDoc.data();
        });
      }else{
        print("User document does not exist for userId: ${widget.userId}");
        setState((){
          hasError = true;
        });
      }
      
    } catch (e) {
      print("Error loading profile data: $e");
      setState((){
        hasError = true;
      });
    }
  }
  @override
  Widget build(BuildContext context){
    if(hasError){
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "Failed to load profile data or user does not exist.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red, fontSize: 18),
          ),
        ),
      );
    }
    if (userData == null){
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Player Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Avatar image(if exists)
            if(userData!['avatarUrl'] != null)
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(userData!['avatarUrl'].toString()),
                ),
              ),
                const SizedBox(height: 30),

              _profileItem("Player ID", userData!['playerId']?.toString()),
              _profileItem("Username", userData!['username']?.toString()),
              _profileItem("Bank Account", "\$${userData!['bankAccount']?.toString() ?? '0'}"),       
              _profileItem("Wins", userData!['wins']?.toString() ?? '0'),
              _profileItem("Losses", userData!['losses']?.toString() ?? '0'),
              _profileItem("Online Status", userData!['isOnline'] == true ? "Yes" : "No"),

          ],
        ),
      ),
    );
  }
  Widget _profileItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
      Text(
        "$label: ",
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      Text(
        value ?? "N/A",
        style: const TextStyle(color: Colors.blue, fontSize: 18),
      ),
    ],
      ),
    );
  }
}
