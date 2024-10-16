import 'package:flutter/material.dart';
import 'package:skill_swap_app/screens/ChatSelectionScreen.dart';
import 'package:skill_swap_app/utils/colors.dart';
import 'package:skill_swap_app/utils/global_variable.dart';
import 'package:skill_swap_app/screens/notification.dart';
import 'package:skill_swap_app/screens/chat_screen.dart'; // Import the Chat Screen
import 'package:skill_swap_app/screens/feed_screen.dart'; // Import Feed Screen
import 'package:skill_swap_app/screens/search_screen.dart'; // Import Search Screen
import 'package:skill_swap_app/screens/add_post_screen.dart'; // Import Add Post Screen
import 'package:skill_swap_app/screens/profile_screen.dart'; // Import Profile Screen

class WebScreenLayout extends StatefulWidget {
  const WebScreenLayout({Key? key}) : super(key: key);

  @override
  State<WebScreenLayout> createState() => _WebScreenLayoutState();
}

class _WebScreenLayoutState extends State<WebScreenLayout> {
  int _page = 0;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }

  void onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  void navigationTapped(int page) {
    pageController.jumpToPage(page);
    setState(() {
      _page = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        centerTitle: false,
        title: Center(
          child: const Text(
            'SKILL SWAP APP',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.home,
              color: _page == 0 ? primaryColor : secondaryColor,
            ),
            onPressed: () => navigationTapped(0),
          ),
          IconButton(
            icon: Icon(
              Icons.search,
              color: _page == 1 ? primaryColor : secondaryColor,
            ),
            onPressed: () => navigationTapped(1),
          ),
          IconButton(
            icon: Icon(
              Icons.add_a_photo,
              color: _page == 2 ? primaryColor : secondaryColor,
            ),
            onPressed: () => navigationTapped(2),
          ),
          IconButton(
            icon: Icon(
              Icons.notifications,
              color: _page == 3 ? primaryColor : secondaryColor,
            ),
            onPressed: () => navigationTapped(3),
          ),
          IconButton(
            icon: Icon(
              Icons.person,
              color: _page == 4 ? primaryColor : secondaryColor,
            ),
            onPressed: () => navigationTapped(4),
          ),
          IconButton(
            icon: Icon(
              Icons.chat,
              color: _page == 5 ? primaryColor : secondaryColor,
            ),
            onPressed: () {
              // Navigate to chat screen with a specific userId
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ChatSelectionScreen()), // Update this as needed
              );
            },
          ),
        ],
      ),
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: pageController,
        onPageChanged: onPageChanged,
        children: homeScreenItems, // Ensure this contains all your screens
      ),
    );
  }
}
