import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skill_swap_app/utils/colors.dart';
import 'package:skill_swap_app/utils/utils.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Requests'),
        backgroundColor: mobileBackgroundColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('connection_requests')
            .where('receiverId',
                isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return const Center(child: Text('No connection requests.'));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final senderId = request['senderId'];

              return ListTile(
                title: Text('Connection request from $senderId'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          acceptConnectionRequest(request.id, context),
                      child: const Text('Accept'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () =>
                          declineConnectionRequest(request.id, context),
                      child: const Text('Decline'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> acceptConnectionRequest(
      String requestId, BuildContext context) async {
    try {
      // Update request status to accepted
      await FirebaseFirestore.instance
          .collection('connection_requests')
          .doc(requestId)
          .update({'status': 'accepted'});

      // Here you might want to add the senderId to the receiver's followers
      // Add the sender to the receiver's followers list
      final requestDoc = await FirebaseFirestore.instance
          .collection('connection_requests')
          .doc(requestId)
          .get();

      final senderId = requestDoc['senderId'];
      final receiverId = FirebaseAuth.instance.currentUser!.uid;

      // Update followers in the users collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .update({
        'followers': FieldValue.arrayUnion([senderId]),
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .update({
        'followers': FieldValue.arrayUnion([receiverId]),
      });

      showSnackBar(context, 'Connection request accepted!');
    } catch (e) {
      showSnackBar(context, 'Failed to accept request: $e');
    }
  }

  Future<void> declineConnectionRequest(
      String requestId, BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('connection_requests')
          .doc(requestId)
          .delete();

      showSnackBar(context, 'Connection request declined.');
    } catch (e) {
      showSnackBar(context, 'Failed to decline request: $e');
    }
  }
}
