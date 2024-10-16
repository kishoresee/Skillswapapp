import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skill_swap_app/models/user.dart' as model;
import 'package:skill_swap_app/screens/profile_screen.dart';
import 'package:skill_swap_app/screens/chat_screen.dart'; // Import the Chat Screen
import 'package:skill_swap_app/utils/colors.dart';
import 'package:skill_swap_app/utils/utils.dart';

class ConnectionRequestsScreen extends StatefulWidget {
  const ConnectionRequestsScreen({Key? key}) : super(key: key);

  @override
  State<ConnectionRequestsScreen> createState() =>
      _ConnectionRequestsScreenState();
}

class _ConnectionRequestsScreenState extends State<ConnectionRequestsScreen> {
  List<model.User> requests = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchConnectionRequests();
  }

  Future<void> fetchConnectionRequests() async {
    setState(() {
      isLoading = true;
    });

    try {
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;

      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection('connection_requests')
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      List<model.User> fetchedUsers =
          await Future.wait(snap.docs.map((doc) async {
        String senderId = doc['senderId'];
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(senderId)
            .get();
        return model.User.fromSnap(userDoc);
      }).toList());

      setState(() {
        requests = fetchedUsers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showSnackBar(context, 'Error fetching requests: $e');
    }
  }

  /// Accepts a connection request
  Future<void> acceptRequest(String senderId) async {
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection('connection_requests')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId',
              isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .get();

      if (snap.docs.isNotEmpty) {
        String requestId = snap.docs.first.id;

        await FirebaseFirestore.instance
            .collection('connection_requests')
            .doc(requestId)
            .update({'status': 'accepted'});

        showSnackBar(context, 'Connection request accepted.');

        // Navigate to chat screen with the sender's user ID
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ChatScreen(userId: senderId)), // Pass senderId here
        );

        fetchConnectionRequests(); // Refresh the request list
      }
    } catch (e) {
      showSnackBar(context, 'Error accepting request: $e');
    }
  }

  /// Declines a connection request
  Future<void> declineRequest(String senderId) async {
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection('connection_requests')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId',
              isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .get();

      if (snap.docs.isNotEmpty) {
        String requestId = snap.docs.first.id;

        await FirebaseFirestore.instance
            .collection('connection_requests')
            .doc(requestId)
            .delete();

        showSnackBar(context, 'Connection request declined.');
        fetchConnectionRequests(); // Refresh the request list
      }
    } catch (e) {
      showSnackBar(context, 'Error declining request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Requests'),
        backgroundColor: mobileBackgroundColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : requests.isNotEmpty
              ? ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    model.User user = requests[index];
                    return buildRequestCard(user);
                  },
                )
              : const Center(child: Text('No connection requests')),
    );
  }

  /// Builds a card for each connection request
  Widget buildRequestCard(model.User user) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey,
          backgroundImage:
              user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
          child: user.photoUrl.isEmpty
              ? const Icon(
                  Icons.person,
                  color: Colors.white,
                )
              : null,
        ),
        title: Text(user.name),
        subtitle: Text('Skills: ${user.skills}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => acceptRequest(user.uid), // Only pass senderId
              tooltip: 'Accept',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => declineRequest(user.uid),
              tooltip: 'Decline',
            ),
          ],
        ),
      ),
    );
  }
}
