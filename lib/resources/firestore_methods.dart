import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FireStoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Sends a connection request from [senderId] to [receiverId]
  Future<void> sendConnectionRequest(String senderId, String receiverId) async {
    try {
      if (senderId == receiverId) {
        throw Exception('You cannot send a connection request to yourself.');
      }

      QuerySnapshot existingRequest = await _firestore
          .collection('connection_requests')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequest.docs.isNotEmpty) {
        throw Exception('A connection request is already pending.');
      }

      DocumentSnapshot senderSnap =
          await _firestore.collection('users').doc(senderId).get();
      List<dynamic> senderFollowing = senderSnap['following'] ?? [];

      if (senderFollowing.contains(receiverId)) {
        throw Exception('You are already connected with this user.');
      }

      await _firestore.collection('connection_requests').add({
        'senderId': senderId,
        'receiverId': receiverId,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('Connection request sent from $senderId to $receiverId');
    } catch (e) {
      print('Error sending connection request: $e');
      throw e;
    }
  }

  /// Accepts a connection request with [requestId]
  Future<void> acceptConnectionRequest(
      String requestId, String senderId) async {
    try {
      DocumentSnapshot requestSnap = await _firestore
          .collection('connection_requests')
          .doc(requestId)
          .get();

      if (!requestSnap.exists) {
        throw Exception('Connection request does not exist.');
      }

      String currentUserId = _auth.currentUser!.uid;
      String receiverId = requestSnap['receiverId'];

      if (receiverId != currentUserId) {
        throw Exception('You are not authorized to accept this request.');
      }

      await _firestore
          .collection('connection_requests')
          .doc(requestId)
          .update({'status': 'accepted'});

      await _firestore.collection('users').doc(senderId).update({
        'following': FieldValue.arrayUnion([currentUserId]),
      });

      await _firestore.collection('users').doc(currentUserId).update({
        'followers': FieldValue.arrayUnion([senderId]),
      });

      await _firestore.collection('connections').add({
        'user1Id': senderId,
        'user2Id': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'meetLink': '',
      });

      print('Connection request $requestId accepted.');
    } catch (e) {
      print('Error accepting connection request: $e');
      throw e;
    }
  }

  /// Rejects a connection request with [requestId]
  Future<void> rejectConnectionRequest(String requestId) async {
    try {
      DocumentSnapshot requestSnap = await _firestore
          .collection('connection_requests')
          .doc(requestId)
          .get();

      if (!requestSnap.exists) {
        throw Exception('Connection request does not exist.');
      }

      String currentUserId = _auth.currentUser!.uid;
      String receiverId = requestSnap['receiverId'];

      if (receiverId != currentUserId) {
        throw Exception('You are not authorized to reject this request.');
      }

      await _firestore
          .collection('connection_requests')
          .doc(requestId)
          .update({'status': 'rejected'});

      print('Connection request $requestId rejected.');
    } catch (e) {
      print('Error rejecting connection request: $e');
      throw e;
    }
  }

  /// Follows or unfollows a user
  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      if (currentUserId == targetUserId) {
        throw Exception('You cannot follow yourself.');
      }

      DocumentSnapshot userSnap =
          await _firestore.collection('users').doc(targetUserId).get();

      if (!userSnap.exists) {
        throw Exception('The user you are trying to follow does not exist.');
      }

      List<dynamic> followers = List.from(userSnap['followers'] ?? []);

      if (followers.contains(currentUserId)) {
        await _firestore.collection('users').doc(targetUserId).update({
          'followers': FieldValue.arrayRemove([currentUserId]),
        });

        await _firestore.collection('users').doc(currentUserId).update({
          'following': FieldValue.arrayRemove([targetUserId]),
        });

        print('$currentUserId unfollowed $targetUserId');
      } else {
        await _firestore.collection('users').doc(targetUserId).update({
          'followers': FieldValue.arrayUnion([currentUserId]),
        });

        await _firestore.collection('users').doc(currentUserId).update({
          'following': FieldValue.arrayUnion([targetUserId]),
        });

        print('$currentUserId followed $targetUserId');
      }
    } catch (e) {
      print('Error following/unfollowing user: $e');
      throw e;
    }
  }

  /// Updates the trust score based on new rating
  Future<void> updateTrustScore(String userId, int rating) async {
    try {
      DocumentReference userRef = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userRef);

        if (!snapshot.exists) {
          throw Exception("User does not exist!");
        }

        List<dynamic> ratings = List.from(snapshot['ratings'] ?? []);
        ratings.add(rating);

        int newTrustScore = snapshot['trustScore'] ?? 0;

        if (rating >= 4) {
          newTrustScore += 1;
        }

        transaction.update(userRef, {
          'ratings': ratings,
          'trustScore': newTrustScore,
        });
      });

      print('Trust score updated for user $userId with rating $rating.');
    } catch (e) {
      print('Error updating trust score: $e');
      throw e;
    }
  }

  /// Uploads a post
  Future<String> uploadPost(
    String description,
    String details,
    List<Uint8List> files,
    String uid,
    String username,
    String profImage,
    String category,
  ) async {
    try {
      // Create a new post document
      DocumentReference postRef = await _firestore.collection('posts').add({
        'description': description,
        'details': details,
        'uid': uid,
        'username': username,
        'profImage': profImage,
        'category': category,
        'datePublished': FieldValue.serverTimestamp(),
        'likes': [],
        'postUrls': [], // Initialize an empty list for image URLs
      });

      // Upload each image to Firebase Storage
      List<String> imageUrls = [];
      for (Uint8List file in files) {
        String imageUrl = await uploadImageToStorage(file, postRef.id);
        imageUrls.add(imageUrl);
      }

      // Update the post document with the image URLs
      await postRef.update({
        'postUrls': imageUrls,
      });

      return "Post uploaded successfully";
    } catch (error) {
      return error.toString();
    }
  }
  Future<void> postComment(String postId, String commentText) async {
    try {
      String userId = _auth.currentUser!.uid; // Get the current user's ID
      String username = "User"; // Replace with logic to fetch username
      String profileImage =
          ""; // Replace with logic to fetch user's profile image

      // Create a new comment document
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add({
        'userId': userId,
        'username': username,
        'profileImage': profileImage,
        'commentText': commentText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('Comment posted successfully.');
    } catch (e) {
      print('Error posting comment: $e');
      throw e;
    }
  }

  /// Uploads an image to Firebase Storage
  Future<String> uploadImageToStorage(Uint8List file, String postId) async {
    try {
      Reference ref = _storage
          .ref()
          .child('posts/$postId/${DateTime.now().millisecondsSinceEpoch}');
      UploadTask uploadTask = ref.putData(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (error) {
      throw error; // Handle image upload error
    }
  }

  /// Likes a post
  Future<void> likePost(String postId, String uid, List likes) async {
    try {
      if (likes.contains(uid)) {
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayRemove([uid]),
        });
      } else {
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayUnion([uid]),
        });
      }
    } catch (error) {
      throw error; // Handle error
    }
  }

  /// Deletes a post
  Future<void> deletePost(String postId) async {
    try {
      DocumentSnapshot postDoc =
          await _firestore.collection('posts').doc(postId).get();
      if (postDoc.exists) {
        List<String> imageUrls = List<String>.from(postDoc['postUrls']);

        // Delete images from Firebase Storage
        for (String imageUrl in imageUrls) {
          String imagePath = imageUrl
              .split('%2F')
              .last
              .split('?')
              .first; // Adjust this as necessary
          await _storage.ref('posts/$imagePath').delete();
        }

        // Delete the post document from Firestore
        await _firestore.collection('posts').doc(postId).delete();
      }
    } catch (error) {
      throw error; // Handle error
    }
  }
}
