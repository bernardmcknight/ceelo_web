import 'package:ceelo_web/lobby_screen.dart';
import 'profile_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class MainMenuScreen extends StatelessWidget{
  MainMenuScreen({super.key});
  final String lobbyId = "default_lobby"; // Placeholder lobby ID
  final String userId = FirebaseAuth.instance.currentUser != null ? FirebaseAuth.instance.currentUser!.uid : "guest";

  
  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient:LinearGradient(
            colors: [Colors.redAccent, Colors.green],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:[
            // Logo
            Column(
              children: [
                const SizedBox(height: 40),
                Image.asset('assets/images/logo.png', height:100),
                const Text(
                  'Cee-Lo Big Bank',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    ),
                ), 
              ],
            ),
            // Player Bank Info
            Card(
              color: Colors.white10,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children:[
                    const Text("Welcome, Player!", style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                      "Bank: \$${(FirebaseAuth.instance.currentUser != null) ? '1000000' : '0'}", // Placeholder for bank amount
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Game Mode Buttons
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/single_player');
                  },
                  child: const Text('Single Player'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder:(context) =>  LobbyScreen(lobbyId: lobbyId)),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('Multiplayer Mode'),
                ),
              ],
            ),
            // Additional Options
            Column(
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/leaderboards');
                  },
                  child: const Text('Leaderboards', style: TextStyle(color: Colors.white)),
                ),
                OutlinedButton(
                  onPressed: () {
                    final userId = FirebaseAuth.instance.currentUser!.uid;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(userId: FirebaseAuth.instance.currentUser!.uid),
                      ),
                    );
                  },
                  child: const Text('Profile', style: TextStyle(color: Colors.white)),
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                  child: const Text('Settings', style: TextStyle(color: Colors.white)),
                ), 
              ],
            ),

            // Logout Button
            ElevatedButton.icon(
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            )

          ]

        )
      )
    );
  }
}