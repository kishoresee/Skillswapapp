// user.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String email;
  final String name;
  final String skills;
  final String currentRole; // 'Student' or 'Mentor'
  final String skypeID;
  final String photoUrl;
  final int trustScore;
  final List followers;
  final List following;
  final List ratings;

  User({
    required this.uid,
    required this.email,
    required this.name,
    required this.skills,
    required this.currentRole,
    required this.skypeID,
    required this.photoUrl,
    required this.trustScore,
    required this.followers,
    required this.following,
    required this.ratings,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'name': name,
        'skills': skills,
        'currentRole': currentRole,
        'skypeID': skypeID,
        'photoUrl': photoUrl,
        'trustScore': trustScore,
        'followers': followers,
        'following': following,
        'ratings': ratings,
      };

  factory User.fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return User(
      uid: snapshot['uid'],
      email: snapshot['email'],
      name: snapshot['name'],
      skills: snapshot['skills'],
      currentRole: snapshot['currentRole'],
      skypeID: snapshot['skypeID'],
      photoUrl: snapshot['photoUrl'],
      trustScore: snapshot['trustScore'] ?? 0,
      followers: snapshot['followers'] ?? [],
      following: snapshot['following'] ?? [],
      ratings: snapshot['ratings'] ?? [],
    );
  }
}
