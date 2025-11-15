import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LobbyScreen extends StatefulWidget {
  final String lobbyId;

  const LobbyScreen({super.key, required this.lobbyId});
 
 @override
  State<LobbyScreen> createState() => LobbyScreenState();
}

class LobbyScreenState extends State<LobbyScreen>{
  late Stream<DocumentSnapshot>? lobbyStream;
  late String currentUserId;
  final TextEditingController _lobbyNameController = TextEditingController();
  final TextEditingController _joinLobbyIdController = TextEditingController();
  bool hasJoinedLobby = false;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    if(widget.lobbyId.isNotEmpty){
      hasJoinedLobby = true;
      lobbyStream = FirebaseFirestore.instance
        .collection('lobbies')
        .doc(widget.lobbyId)
        .snapshots();
    }
    
  }

  Future<void> startGame(DocumentSnapshot lobbySnapshot) async {
    final roomRef = FirebaseFirestore.instance.collection('rooms').doc();

    await roomRef.set({
      'roomId': roomRef.id,
      'players': lobbySnapshot['players'],
      'createdAt': FieldValue.serverTimestamp(),
      'gameStatus': 'waiting',
      'diceValues':[1,1,1],
      'currentTurn': lobbySnapshot['players'][0],
    });

    // Update lobby to indicate game has started
    await FirebaseFirestore.instance
        .collection('lobbies')
        .doc(widget.lobbyId)
        .update({'gameStarted': true, 'roomId': roomRef.id,
        });
    // Navigate to RoomScreen
    Navigator.pushReplacementNamed(context, '/room', arguments: roomRef.id);
  }
  Future<void> createLobby() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final name = _lobbyNameController.text.trim();

    if(name.isEmpty){
      _showError("Enter a lobby name.");
      return;
    }
    final doc = FirebaseFirestore.instance.collection('lobbies').doc();
    await doc.set({
      'lobbyId': doc.id,
      'lobbyName': name,
      'hostId': uid,
      'players': [uid],
      'gameStarted': false,
      'roomId': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    setState((){
      hasJoinedLobby = true;
      lobbyStream = FirebaseFirestore.instance
        .collection('lobbies')
        .doc(doc.id)
        .snapshots();
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LobbyScreen(lobbyId: doc.id),
      ),
    );
  }
  Future <void> joinLobby() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final lobbyId = _joinLobbyIdController.text.trim();

    if(lobbyId.isEmpty){
      _showError("Enter a valid lobby ID.");
      return;
    }
    final lobbyRef = FirebaseFirestore.instance.collection('lobbies').doc(lobbyId);
    final lobbySnapshot = await lobbyRef.get();

    if(!lobbySnapshot.exists){
      _showError("Lobby not found.");
      return;
    }
    final players = List<String>.from(lobbySnapshot['players'] ?? []);
    if(players.contains(uid)){
      _showError("You are already in this lobby.");
      return;
    }
    players.add(uid);
    await lobbyRef.update({'players': players});

    setState((){
      hasJoinedLobby = true;
      lobbyStream = FirebaseFirestore.instance
        .collection('lobbies')
        .doc(lobbyId)
        .snapshots();
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LobbyScreen(lobbyId: lobbyId),
      ),
    );
  }
  void _showError(String message){
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }
  @override
  Widget build(BuildContext context){
    if(!hasJoinedLobby){
      return Scaffold(
        backgroundColor: Colors.blueGrey[900],
        appBar: AppBar(title: const Text("Cee-Lo Lobby"), backgroundColor: Colors.redAccent),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              TextField(
                controller: _lobbyNameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Room Name",
                  filled: true,
                  fillColor: Colors.white12,
                  ),
                ),
              const SizedBox(height:20),
              ElevatedButton(
                onPressed: createLobby,
                child: const Text("Create Room")),

              const Divider(color: Colors.white),

              const Text("Join a Lobby by ID", style: TextStyle(color: Colors.white)),
              TextField(
                controller: _joinLobbyIdController,
                decoration: const InputDecoration(
                  hintText: "Lobby ID",
                  filled: true,
                  fillColor: Colors.white,
                  ),
                ),
              const SizedBox(height:20),
              ElevatedButton(
                onPressed: joinLobby,
                child: const Text("Join Room")),
            ],
          ),  
        ),  
      );  
    }
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: const Text("Dice Lobby"),
        backgroundColor: Colors.redAccent,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: lobbyStream,
        builder: (context, snapshot){
          if(!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final lobby = snapshot.data!;
          final List<dynamic> players = lobby['players'] ?? [];
          final bool isHost = lobby['hostId'] == currentUserId;
          final bool isStarted = lobby['gameStarted'] ?? false;

          if(isStarted){
            // If already started, navigate to RoomScreen
            Future.microtask((){
              Navigator.pushReplacementNamed(context, '/room', arguments: lobby['roomId']);
            });
            return const Center(child: Text("Starting  game...", style: TextStyle(color: Colors.white)));
          }

          return Column(
            children: [
              const SizedBox(height:20),
              Text("Lobby: ${lobby['lobbyName']}", style: const TextStyle(color: Colors.white, fontSize: 24)),
              const Divider(color: Colors.white38),
              ...players.map((uid)=> ListTile(
                title: Text(uid, style: const TextStyle(color: Colors.white)),
              )),
              const Spacer(),
              if(isHost)
                ElevatedButton(
                  onPressed: players.length >= 2 ? () => startGame(lobby) : null,
                  child: const Text("Start Game"),
                ),
              const SizedBox(height:30),
            ],
          );
        },
      ),
    );
  }
}