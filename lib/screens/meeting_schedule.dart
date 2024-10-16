// meeting_schedule.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:url_launcher/url_launcher.dart'; // To launch the Google Meet link
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore

class MeetingScreen extends StatefulWidget {
  final String userId;

  const MeetingScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _MeetingScreenState createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  DateTime? selectedDateTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Meeting')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you comfortable with virtual or live meetings?'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _scheduleMeeting(context, 'Virtual');
              },
              child: const Text('Virtual Meeting'),
            ),
            ElevatedButton(
              onPressed: () {
                _scheduleMeeting(context, 'Live');
              },
              child: const Text('Live Meeting'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Not Now'),
            ),
            const SizedBox(height: 20),
            if (selectedDateTime != null)
              Text(
                  'Selected Date & Time: ${DateFormat.yMd().add_jm().format(selectedDateTime!)}'),
          ],
        ),
      ),
    );
  }

  void _scheduleMeeting(BuildContext context, String meetingType) async {
    // Show date and time picker
    selectedDateTime = await showDateTimePicker(context);
    if (selectedDateTime != null) {
      bool confirmed = await _showConfirmationDialog(context, meetingType);
      if (confirmed) {
        String meetLink = await _createMeetingLink(meetingType);
        _sendMeetingDetails(meetingType, meetLink);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Scheduled a $meetingType meeting. Join at $meetLink')),
        );
        Navigator.pop(context); // Close the dialog after scheduling
      }
    }
  }

  Future<DateTime?> showDateTimePicker(BuildContext context) async {
    DateTime now = DateTime.now();
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year, now.month + 1),
    );

    if (selectedDate != null) {
      TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now),
      );

      if (selectedTime != null) {
        return DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );
      }
    }
    return null;
  }

  Future<bool> _showConfirmationDialog(
      BuildContext context, String meetingType) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Meeting'),
          content: Text(
              'Schedule a $meetingType meeting on ${DateFormat.yMd().add_jm().format(selectedDateTime!)}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    ).then((value) => value ?? false);
  }

  Future<String> _createMeetingLink(String meetingType) async {
    // Here you would usually call an API to create a Google Meet link
    String meetLink = 'https://meet.google.com/new'; // Placeholder link

    // Launch Google Meet link
    _launchURL(meetLink);
    return meetLink;
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _sendMeetingDetails(String meetingType, String meetLink) async {
    final meetingDetails = {
      'senderId': FirebaseAuth.instance.currentUser!.uid,
      'receiverId': widget.userId,
      'meetingType': meetingType,
      'dateTime': selectedDateTime,
      'link': meetLink,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // Save meeting details to Firestore
    await FirebaseFirestore.instance.collection('meetings').add(meetingDetails);
  }
}
