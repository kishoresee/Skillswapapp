// feed_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skill_swap_app/models/user.dart' as model;
import 'package:skill_swap_app/screens/profile_screen.dart';
import 'package:skill_swap_app/resources/firestore_methods.dart';
import 'package:skill_swap_app/utils/colors.dart';
import 'package:skill_swap_app/utils/global_variable.dart';
import 'package:skill_swap_app/utils/utils.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<model.User> users = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() {
      isLoading = true;
    });
    try {
      QuerySnapshot snap =
          await FirebaseFirestore.instance.collection('users').get();

      List<model.User> fetchedUsers = snap.docs
          .map((doc) => model.User.fromSnap(doc))
          .where((user) => user.uid != FirebaseAuth.instance.currentUser!.uid)
          .toList();

      setState(() {
        users = fetchedUsers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showSnackBar(context, e.toString());
    }
  }

  Widget buildUserItem(model.User user) {
    bool isConnected =
        user.followers.contains(FirebaseAuth.instance.currentUser!.uid);

    return ListTile(
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
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Skills: ${user.skills}'),
          Text('Role: ${user.currentRole}'),
          Text('Trust Score: ${user.trustScore}'),
        ],
      ),
      trailing: ElevatedButton(
        onPressed: () async {
          await sendConnectionRequest(user.uid);
        },
        child: const Text('Connect'),
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProfileScreen(uid: user.uid),
          ),
        );
      },
    );
  }

  Future<void> sendConnectionRequest(String receiverId) async {
    try {
      QuerySnapshot existingRequest = await FirebaseFirestore.instance
          .collection('connection_requests')
          .where('senderId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequest.docs.isNotEmpty) {
        showSnackBar(context, 'Connection request already sent.');
        return;
      }

      await FirebaseFirestore.instance.collection('connection_requests').add({
        'senderId': FirebaseAuth.instance.currentUser!.uid,
        'receiverId': receiverId,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      connectionRequests.add(receiverId); // Add to local list
      unreadNotifications++; // Increment unread notifications
      showSnackBar(context, 'Connection request sent.');
    } catch (e) {
      showSnackBar(context, 'Failed to send request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: mobileBackgroundColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchUsers,
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  return buildUserItem(users[index]);
                },
              ),
            ),
    );
  }
}
