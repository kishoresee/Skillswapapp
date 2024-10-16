// global_variable.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skill_swap_app/screens/add_post_screen.dart';
import 'package:skill_swap_app/screens/feed_screen.dart';
import 'package:skill_swap_app/screens/profile_screen.dart';
import 'package:skill_swap_app/screens/search_screen.dart';
import 'package:skill_swap_app/screens/notification.dart'; // Import notifications
import 'package:skill_swap_app/screens/chat_screen.dart'; // Import chat screen

const webScreenSize = 600;

List<Widget> homeScreenItems = [
  const FeedScreen(),
  const SearchScreen(),
  const AddPostScreen(),
  const NotificationsScreen(), // Change to Notifications Screen
  ProfileScreen(uid: FirebaseAuth.instance.currentUser!.uid),
   // Add Chat Screen
];


List<String> connectionRequests = []; // List to hold connection requests
int unreadNotifications = 0; // Counter for unread notifications
