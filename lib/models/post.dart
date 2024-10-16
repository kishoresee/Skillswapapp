import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String description;
  final String details; // New field for scam details
  final String uid;
  final String username;
  final List<dynamic> likes; // Specify the type for `likes`
  final String postId;
  final DateTime datePublished;
  final List<String> postUrls; // Changed from single URL to list of URLs
  final String profImage;
  final String category; // New field for scam category

  const Post({
    required this.description,
    required this.details, // Initialize new field
    required this.uid,
    required this.username,
    required this.likes,
    required this.postId,
    required this.datePublished,
    required this.postUrls, // Changed to List<String>
    required this.profImage,
    required this.category, // Initialize new field
  });

  static Post fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return Post(
      description: snapshot["description"],
      details: snapshot["details"], // Extract new field from snapshot
      uid: snapshot["uid"],
      likes: snapshot["likes"],
      postId: snapshot["postId"],
      datePublished: (snapshot["datePublished"] as Timestamp)
          .toDate(), // Convert Timestamp to DateTime
      username: snapshot["username"],
      postUrls: List<String>.from(snapshot['postUrls']), // Extract list of URLs
      profImage: snapshot['profImage'],
      category: snapshot['category'], // Extract new field from snapshot
    );
  }

  Map<String, dynamic> toJson() => {
        "description": description,
        "details": details, // Add new field to JSON conversion
        "uid": uid,
        "likes": likes,
        "username": username,
        "postId": postId,
        "datePublished": datePublished,
        'postUrls': postUrls, // Changed to List<String>
        'profImage': profImage,
        'category': category, // Add new field to JSON conversion
      };
}
