// utils.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

/// Picks an image from the specified [source].
///
/// - [source]: The source from which to pick the image (e.g., gallery, camera).
///
/// Returns a [Uint8List] of the image bytes if an image is selected.
/// Returns `null` if no image is selected or an error occurs.
Future<Uint8List?> pickImage(ImageSource source) async {
  try {
    final ImagePicker imagePicker = ImagePicker();
    // Prompt the user to pick an image from the specified source
    XFile? file = await imagePicker.pickImage(source: source);
    if (file != null) {
      // Read the image as bytes and return
      return await file.readAsBytes();
    } else {
      // User canceled the picker
      return null;
    }
  } catch (e) {
    // Log the error for debugging purposes
    print('Error picking image: $e');
    // Optionally, you can handle the error more gracefully here
    return null;
  }
}

/// Displays a [SnackBar] with the provided [text] in the given [context].
///
/// - [context]: The BuildContext to display the SnackBar.
/// - [text]: The message to display inside the SnackBar.
/// - [duration]: (Optional) How long the SnackBar should be visible. Defaults to 2 seconds.
///
/// Example usage:
/// ```dart
/// showSnackBar(context, 'Profile updated successfully!');
/// ```
void showSnackBar(
  BuildContext context,
  String text, {
  Duration duration = const Duration(seconds: 2),
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      duration: duration,
      behavior: SnackBarBehavior
          .floating, // Makes the SnackBar float above the content
      backgroundColor: Colors.black87, // Sets a consistent background color
      action: SnackBarAction(
        label: 'Dismiss',
        textColor: Colors.white,
        onPressed: () {
          // Dismiss the SnackBar when the action is pressed
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ),
  );
}

/// Validates if the provided [email] has a valid email format.
///
/// - [email]: The email string to validate.
///
/// Returns `true` if the email is valid, otherwise `false`.
bool isValidEmail(String email) {
  // Regular expression for validating an email
  final RegExp emailRegex = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );
  return emailRegex.hasMatch(email);
}

/// Shows a confirmation dialog with [title] and [content].
///
/// - [context]: The BuildContext to display the dialog.
/// - [title]: The title of the dialog.
/// - [content]: The content/message of the dialog.
///
/// Returns `true` if the user confirms, otherwise `false`.
Future<bool> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: const Text('Confirm'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      ) ??
      false; // Returns false if the dialog is dismissed without a selection
}
