// chat_selection_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skill_swap_app/screens/chat_screen.dart';
import 'package:skill_swap_app/models/user.dart' as model;

class ChatSelectionScreen extends StatefulWidget {
  const ChatSelectionScreen({Key? key}) : super(key: key);

  @override
  _ChatSelectionScreenState createState() => _ChatSelectionScreenState();
}

class _ChatSelectionScreenState extends State<ChatSelectionScreen> {
  List<model.User> acceptedUsers = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchAcceptedConnections();
  }

  Future<void> fetchAcceptedConnections() async {
    setState(() {
      isLoading = true;
    });

    try {
      String currentUserId = FirebaseAuth.instance.currentUser!.uid;

      // Fetch accepted connections
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection('connection_requests')
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'accepted')
          .get();

      List<model.User> fetchedUsers = await Future.wait(
        snap.docs.map((doc) async {
          String senderId = doc['senderId'];
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(senderId)
              .get();
          return model.User.fromSnap(userDoc);
        }).toList(),
      );

      setState(() {
        acceptedUsers = fetchedUsers;
      });
    } catch (e) {
      // Handle errors
      print('Error fetching accepted connections: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select a User to Chat')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : acceptedUsers.isEmpty
              ? const Center(child: Text('No accepted connections'))
              : ListView.builder(
                  itemCount: acceptedUsers.length,
                  itemBuilder: (context, index) {
                    model.User user = acceptedUsers[index];
                    return ListTile(
                      title: Text(user.name),
                      subtitle: Text('Skills: ${user.skills}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(userId: user.uid),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
