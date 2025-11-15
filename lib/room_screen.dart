import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RoomScreen extends StatefulWidget{
  final String roomId;

  const RoomScreen({super.key, required this.roomId});

  @override
  State<RoomScreen> createState() => RoomScreenState();
}
class RoomScreenState extends State<RoomScreen>{
  late Stream<DocumentSnapshot> roomStream;
  late String currentUserId;

  @override
  void initState(){
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    roomStream = FirebaseFirestore.instance
      .collection('rooms')
      .doc(widget.roomId)
      .snapshots();
  }

  Future<void> rollDice()async{
    final random = DateTime.now().millisecondsSinceEpoch;
    final List<int> dice =[
      (random % 6) + 1,
      ((random ~/ 10) % 6) + 1,
      ((random ~/ 100) % 6) + 1,
    ];
    await FirebaseFirestore.instance
      .collection('rooms')
      .doc(widget.roomId)
      .update({
        'diceValues': dice,
        'gameStatus': 'rolled',
        'currentTurn': FieldValue.arrayUnion([]),
      });
  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Room")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: roomStream,
        builder: (context, snapshot){
          if(!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final roomData = snapshot.data!.data() as Map<String, dynamic>;
          final dice = roomData['diceValues'] ?? [1,1,1];
          final turnUid = roomData['currentTurn'] ?? '';
          final isMyTurn = currentUserId == turnUid;

          return Column(
            children: [
              const SizedBox(height: 20),
              Text("Current Turn: ${turnUid == currentUserId ? 'You' : 'Opponent' }",
                style: const TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 20),
              Text("Dice: ${dice.join(', ')}",
                style: const TextStyle(color: Colors.white, fontSize: 24)),
              const SizedBox(height: 30),
              if(isMyTurn)
                ElevatedButton(
                  onPressed: rollDice,
                  child: const Text("Roll Dice"),
              )
              else
              const Text("Waiting for opponent to roll...",
                style: TextStyle(color: Colors.white, fontSize: 16),),
            ]
          );
        },
      ),
    );
  }
}
