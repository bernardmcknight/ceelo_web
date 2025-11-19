import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RoomScreen extends StatefulWidget {
  final String roomId;

  const RoomScreen({super.key, required this.roomId});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  late final String currentUserId;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    currentUserId = user?.uid ?? '';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _rollDice() async {
    if (currentUserId.isEmpty) {
      _showError("Not logged in.");
      return;
    }

    final roomRef =
        FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);

    final newDice = List<int>.generate(3, (_) => _random.nextInt(6) + 1);

    try {
      await roomRef.update({
        // global dice (everyone sees)
        'diceValues': newDice,
        'lastRollBy': currentUserId,

        // per-player state for split screen
        'playerStates.$currentUserId': {
          'diceValues': newDice,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      });
    } catch (e) {
      _showError("Failed to roll dice: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: const Text("Room"),
        backgroundColor: Colors.redAccent,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "Room not found.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final data = snapshot.data!.data()!;
          final roomName = data['roomName'] ?? widget.roomId;
          final players = List<String>.from(data['players'] ?? []);
          final dice = List<int>.from(data['diceValues'] ?? [1, 1, 1]);
          final lastRollBy = data['lastRollBy'] as String?;
          final playerStatesRaw =
              (data['playerStates'] ?? {}) as Map<String, dynamic>;

          final Map<String, dynamic> playerStates =
              Map<String, dynamic>.from(playerStatesRaw);

          final myState = playerStates[currentUserId];
          final myDice = myState != null
              ? List<int>.from(myState['diceValues'] ?? dice)
              : dice;

          final otherPlayers =
              players.where((id) => id != currentUserId).toList();

          return Column(
            children: [
              const SizedBox(height: 8),
              Text(
                "Room: $roomName",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                "Room ID: ${widget.roomId}",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),

              // SPLIT SCREEN
              Expanded(
                child: Column(
                  children: [
                    // TOP: YOU
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "You",
                              style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: myDice
                                  .map((v) => _buildDieBox(v))
                                  .toList(),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Your ID: $currentUserId",
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // BOTTOM: OTHER PLAYERS
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        color: Colors.black38,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Other Players",
                              style: TextStyle(
                                  color: Colors.lightBlueAccent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            if (otherPlayers.isEmpty)
                              const Text(
                                "Waiting for others to join...",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              )
                            else
                              Expanded(
                                child: ListView.builder(
                                  itemCount: otherPlayers.length,
                                  itemBuilder: (context, index) {
                                    final playerId = otherPlayers[index];
                                    final ps = playerStates[playerId];
                                    final oppDice = ps != null
                                        ? List<int>.from(
                                            ps['diceValues'] ?? dice)
                                        : dice;
                                    final isLastRoller =
                                        lastRollBy == playerId;

                                    return Padding(
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              playerId +
                                                  (isLastRoller
                                                      ? " (last roll)"
                                                      : ""),
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Row(
                                            children: oppDice
                                                .map((v) => _buildDieBox(v,
                                                    small: true))
                                                .toList(),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // GLOBAL DICE DISPLAY + BUTTON
              Text(
                "Last Roll (everyone): ${dice.join(' - ')}",
                style:
                    const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _rollDice,
                child: const Text("Roll Dice"),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDieBox(int value, {bool small = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: EdgeInsets.all(small ? 8 : 16),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value.toString(),
        style: TextStyle(
          color: Colors.white,
          fontSize: small ? 18 : 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
