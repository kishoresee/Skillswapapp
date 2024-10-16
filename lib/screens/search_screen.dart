import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skill_swap_app/models/user.dart' as model;
import 'package:skill_swap_app/resources/firestore_methods.dart';
import 'package:skill_swap_app/screens/profile_screen.dart';
import 'package:skill_swap_app/utils/colors.dart';
import 'package:skill_swap_app/utils/utils.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<model.User> searchResults = [];
  bool isLoading = false;

  /// Searches users based on query
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      List<model.User> fetchedUsers =
          snap.docs.map((doc) => model.User.fromSnap(doc)).toList();

      setState(() {
        searchResults = fetchedUsers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showSnackBar(context, 'Error occurred while searching: $e');
    }
  }

  /// Sends a connection request to the specified user
  Future<void> sendConnectionRequest(String receiverId) async {
    try {
      await FireStoreMethods().sendConnectionRequest(
          FirebaseAuth.instance.currentUser!.uid, receiverId);
      showSnackBar(context, 'Connection request sent.');
    } catch (e) {
      showSnackBar(context, 'Failed to send request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Users'),
        backgroundColor: mobileBackgroundColor,
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or skills',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onSubmitted: searchUsers,
            ),
          ),
          if (isLoading) const CircularProgressIndicator(),
          if (!isLoading && searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  model.User user = searchResults[index];
                  return buildUserCard(user);
                },
              ),
            ),
          if (!isLoading && searchResults.isEmpty)
            const Expanded(
              child: Center(child: Text('No results found')),
            ),
        ],
      ),
    );
  }

  /// Builds each user card in the search results
  Widget buildUserCard(model.User user) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProfileScreen(uid: user.uid),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey,
                backgroundImage: user.photoUrl.isNotEmpty
                    ? NetworkImage(user.photoUrl)
                    : null,
                child: user.photoUrl.isEmpty
                    ? const Icon(
                        Icons.person,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Skills: ${user.skills}'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => sendConnectionRequest(user.uid),
                child: const Text('Connect'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
