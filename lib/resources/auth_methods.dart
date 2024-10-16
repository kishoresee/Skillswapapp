// auth_methods.dart
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap_app/models/user.dart' as model;
import 'package:skill_swap_app/resources/storage_methods.dart';

class AuthMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user details
  Future<model.User> getUserDetails() async {
    User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('No user is currently logged in');
    }

    String userId = currentUser.uid;
    print('Fetching user document with UID: $userId');

    DocumentSnapshot documentSnapshot =
        await _firestore.collection('users').doc(userId).get();

    if (!documentSnapshot.exists) {
      print('Document data: ${documentSnapshot.data()}');
      throw Exception('User document does not exist');
    }

    return model.User.fromSnap(documentSnapshot);
  }

  // Signing Up User
  Future<String> signUpUser({
    required String email,
    required String password,
    required String name,
    required String skills,
    required String currentRole, // 'Student' or 'Mentor'
    required String skypeID,
    required Uint8List file,
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty &&
          password.isNotEmpty &&
          name.isNotEmpty &&
          skills.isNotEmpty &&
          currentRole.isNotEmpty &&
          skypeID.isNotEmpty &&
          file.isNotEmpty) {
        // Registering user in auth with email and password
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Uploading profile picture
        String photoUrl = await StorageMethods()
            .uploadImageToStorage('profilePics', file, false);

        // Creating user model with new fields
        model.User user = model.User(
          uid: cred.user!.uid,
          email: email,
          name: name,
          skills: skills,
          currentRole: currentRole,
          skypeID: skypeID,
          photoUrl: photoUrl,
          trustScore: 0, // Initialize trust score to 0
          followers: [],
          following: [],
          ratings: [],
        );

        // Adding user to the database
        await _firestore
            .collection("users")
            .doc(cred.user!.uid)
            .set(user.toJson())
            .then((_) => print(
                'User document created successfully with UID: ${cred.user!.uid}'))
            .catchError(
                (error) => print('Failed to create user document: $error'));

        res = "success";
      } else {
        res = "Please enter all the fields";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Logging in user
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        // Logging in user with email and password
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        res = "success";
      } else {
        res = "Please enter all the fields";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Signing out user
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
