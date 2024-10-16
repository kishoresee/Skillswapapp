// profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skill_swap_app/resources/auth_methods.dart';
import 'package:skill_swap_app/resources/firestore_methods.dart';
import 'package:skill_swap_app/screens/login_screen.dart';
import 'package:skill_swap_app/screens/rating_screen.dart';
import 'package:skill_swap_app/utils/colors.dart';
import 'package:skill_swap_app/utils/utils.dart';
import 'package:skill_swap_app/widgets/follow_button.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  const ProfileScreen({Key? key, required this.uid}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  var userData = {};
  int postLen = 0;
  int followers = 0;
  int following = 0;
  bool isFollowing = false;
  bool isConnected = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getData();
  }

  /// Fetches user data and posts from Firestore
  Future<void> getData() async {
    setState(() {
      isLoading = true;
    });
    try {
      // Fetch user document
      var userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      if (!userSnap.exists) {
        throw Exception('User does not exist');
      }

      // Fetch posts by the user
      var postSnap = await FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: widget.uid)
          .get();

      // Update state with fetched data
      setState(() {
        postLen = postSnap.docs.length;
        userData = userSnap.data()!;
        followers = List.from(userData['followers']).length;
        following = List.from(userData['following']).length;
        isFollowing = List.from(userData['followers'])
            .contains(FirebaseAuth.instance.currentUser!.uid);
        isConnected = List.from(userData['followers'])
            .contains(FirebaseAuth.instance.currentUser!.uid);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showSnackBar(
        context,
        e.toString(),
      );
    }
  }

  /// Builds the statistics column (posts, followers, following)
  Column buildStatColumn(int num, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          num.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  /// Opens the rating screen
  void openRatingScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RatingScreen(ratedUserId: widget.uid),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : Scaffold(
            appBar: AppBar(
              backgroundColor: mobileBackgroundColor,
              title: Text(
                userData['name'] ?? 'Profile',
              ),
              centerTitle: false,
            ),
            body: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Profile Picture
                          CircleAvatar(
                            backgroundColor: Colors.grey,
                            backgroundImage: userData['photoUrl'].isNotEmpty
                                ? NetworkImage(userData['photoUrl'])
                                : null,
                            radius: 40,
                            child: userData['photoUrl'].isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                // Statistics (Posts, Followers, Following)
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    buildStatColumn(postLen, "posts"),
                                    buildStatColumn(followers, "followers"),
                                    buildStatColumn(following, "following"),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Follow/Unfollow or Sign Out Button
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    FirebaseAuth.instance.currentUser!.uid ==
                                            widget.uid
                                        ? FollowButton(
                                            text: 'Sign Out',
                                            backgroundColor:
                                                mobileBackgroundColor,
                                            textColor: primaryColor,
                                            borderColor: Colors.grey,
                                            function: () async {
                                              // Show confirmation dialog before signing out
                                              bool confirmed =
                                                  await showConfirmationDialog(
                                                context: context,
                                                title: 'Confirm Sign Out',
                                                content:
                                                    'Are you sure you want to sign out?',
                                              );

                                              if (confirmed) {
                                                await AuthMethods().signOut();
                                                if (context.mounted) {
                                                  Navigator.of(context)
                                                      .pushReplacement(
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          const LoginScreen(),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                          )
                                        : isFollowing
                                            ? FollowButton(
                                                text: 'Unfollow',
                                                backgroundColor: Colors.white,
                                                textColor: Colors.black,
                                                borderColor: Colors.grey,
                                                function: () async {
                                                  // Unfollow user
                                                  await FireStoreMethods()
                                                      .followUser(
                                                    FirebaseAuth.instance
                                                        .currentUser!.uid,
                                                    userData['uid'],
                                                  );

                                                  setState(() {
                                                    isFollowing = false;
                                                    followers--;
                                                  });
                                                },
                                              )
                                            : FollowButton(
                                                text: 'Connect',
                                                backgroundColor: Colors.blue,
                                                textColor: Colors.white,
                                                borderColor: Colors.blue,
                                                function: () async {
                                                  // Send connection request
                                                  await FireStoreMethods()
                                                      .sendConnectionRequest(
                                                    FirebaseAuth.instance
                                                        .currentUser!.uid,
                                                    userData['uid'],
                                                  );

                                                  setState(() {
                                                    isFollowing = true;
                                                    followers++;
                                                  });

                                                  showSnackBar(context,
                                                      'Connection request sent.');
                                                },
                                              )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // User Information (Name, Skills, Role, Skype ID, Trust Score)
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(
                          top: 15,
                        ),
                        child: Text(
                          userData['name'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(
                          top: 1,
                        ),
                        child: Text(
                          'Skills: ${userData['skills'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(
                          top: 1,
                        ),
                        child: Text(
                          'Role: ${userData['currentRole'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(
                          top: 1,
                        ),
                        child: Text(
                          'Skype ID: ${userData['skypeID'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(
                          top: 1,
                        ),
                        child: Text(
                          'Trust Score: ${userData['trustScore'] ?? 0}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      // Rating Button (Only if connected and not viewing own profile)
                      if (isConnected &&
                          FirebaseAuth.instance.currentUser!.uid != widget.uid)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: ElevatedButton(
                            onPressed: openRatingScreen,
                            child: const Text('Rate User'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: blueColor, // Replaced 'primary'
                              foregroundColor:
                                  Colors.white, // Replaced 'onPrimary'
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(),
                // User's Posts Grid
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('posts')
                      .where('uid', isEqualTo: widget.uid)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (!snapshot.hasData || (snapshot.data!.docs.isEmpty)) {
                      return const Center(
                        child: Text('No posts yet'),
                      );
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.docs.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 5,
                        mainAxisSpacing: 1.5,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        DocumentSnapshot snap = snapshot.data!.docs[index];

                        List<dynamic> postUrls = snap['postUrls'];

                        if (postUrls.isEmpty) {
                          return const SizedBox();
                        }

                        String firstUrl = postUrls[0];

                        return GestureDetector(
                          onTap: () {
                            // Implement navigation to post details if needed
                          },
                          child: Image.network(
                            firstUrl,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    );
                  },
                )
              ],
            ),
          );
  }
}
