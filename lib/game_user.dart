import 'package:cloud_firestore/cloud_firestore.dart';

class GameUser {
  final String uid;
  final String email;
  final String username;
  final int bankAccount;
  GameUser({
    required this.uid,
    required this.email,
    required this.username,
    required this.bankAccount,
    
  }) {
    //print('Created GameUser: $uid, $name, $bankAccount');
    
  
  }
  

  factory GameUser.fromDocument(DocumentSnapshot doc, DocumentSnapshot<Object?> doc2) {
    final data = doc.data() as Map<String, dynamic>;
    return GameUser(
      uid: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      bankAccount: data['bankAccount'] ?? 0,
      
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'bankAccount': bankAccount,
      
    };
  }

  static fromCurrentUser() {}
}