import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'room_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _roomCodeController = TextEditingController();
  bool _isBusy = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _createRoom() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError("You must be logged in to create a room.");
      return;
    }

    final name = _roomNameController.text.trim();
    if (name.isEmpty) {
      _showError("Enter a room name.");
      return;
    }

    setState(() => _isBusy = true);

    try {
      final roomRef =
          FirebaseFirestore.instance.collection('rooms').doc();

      await roomRef.set({
        'roomId': roomRef.id,
        'roomName': name,
        'players': [user.uid],
        'createdAt': FieldValue.serverTimestamp(),
        'gameStatus': 'waiting',
        'currentTurn': user.uid,
        'diceValues': [1, 1, 1],
        'playerStates': {
          user.uid: {
            'diceValues': [1, 1, 1],
            'updatedAt': FieldValue.serverTimestamp(),
          }
        },
      });

      // Go straight to RoomScreen
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RoomScreen(roomId: roomRef.id),
        ),
      );
    } catch (e) {
      _showError("Failed to create room: $e");
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _joinRoom() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError("You must be logged in to join a room.");
      return;
    }

    final code = _roomCodeController.text.trim();
    if (code.isEmpty) {
      _showError("Enter a room code.");
      return;
    }

    setState(() => _isBusy = true);

    try {
      final roomRef =
          FirebaseFirestore.instance.collection('rooms').doc(code);
      final snap = await roomRef.get();

      if (!snap.exists) {
        _showError("Room not found.");
        setState(() => _isBusy = false);
        return;
      }

      final data = snap.data() as Map<String, dynamic>;
      final players = List<String>.from(data['players'] ?? []);

      if (!players.contains(user.uid)) {
        players.add(user.uid);
        await roomRef.update({
          'players': players,
          'playerStates.${user.uid}': {
            'diceValues': [1, 1, 1],
            'updatedAt': FieldValue.serverTimestamp(),
          },
        });
      }

      // Go straight to RoomScreen
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RoomScreen(roomId: roomRef.id),
        ),
      );
    } catch (e) {
      _showError("Failed to join room: $e");
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: const Text("Cee-Lo Lobby"),
        backgroundColor: Colors.redAccent,
      ),
      body: AbsorbPointer(
        absorbing: _isBusy,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // CREATE ROOM
              TextField(
                controller: _roomNameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Room Name",
                  labelStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white12,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _createRoom,
                child: const Text("Create Room"),
              ),
              const SizedBox(height: 30),
              const Divider(color: Colors.white38),
              const SizedBox(height: 10),

              // JOIN ROOM
              const Text(
                "Join Existing Room by Code (Room ID)",
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _roomCodeController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: "Enter Room ID",
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _joinRoom,
                child: const Text("Join Room"),
              ),

              const SizedBox(height: 20),
              if (_isBusy)
                const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
