// chat_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'meeting_schedule.dart'; // Import the meeting schedule screen

class ChatScreen extends StatefulWidget {
  final String userId;

  const ChatScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  List<QueryDocumentSnapshot>? messages;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('chats')
        .doc(getChatId(currentUserId, widget.userId))
        .collection('messages')
        .orderBy('timestamp')
        .get();

    setState(() {
      messages = snapshot.docs;
    });
  }

  String getChatId(String user1, String user2) {
    return user1.hashCode <= user2.hashCode
        ? '$user1\_$user2'
        : '$user2\_$user1';
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      final message = {
        'senderId': currentUserId,
        'receiverId': widget.userId,
        'text': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(getChatId(currentUserId, widget.userId))
          .collection('messages')
          .add(message);

      _messageController.clear();
      _fetchMessages(); // Update message list
    }
  }

  void _scheduleMeeting() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MeetingScreen(userId: widget.userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _scheduleMeeting,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages == null
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: messages!.length,
                    itemBuilder: (context, index) {
                      final msg = messages![index];
                      return ListTile(
                        title: Text(msg['text']),
                        subtitle: Text(msg['senderId']),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration:
                        const InputDecoration(labelText: 'Send a message'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
