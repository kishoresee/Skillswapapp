// rating_screen.dart
import 'package:flutter/material.dart';
import 'package:skill_swap_app/resources/firestore_methods.dart';
import 'package:skill_swap_app/utils/colors.dart';
import 'package:skill_swap_app/utils/utils.dart';

class RatingScreen extends StatefulWidget {
  final String ratedUserId; // The user being rated
  const RatingScreen({Key? key, required this.ratedUserId}) : super(key: key);

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _rating = 0;
  bool isLoading = false;

  void submitRating() async {
    if (_rating < 1 || _rating > 5) {
      showSnackBar(context, 'Please select a rating between 1 and 5.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FireStoreMethods().updateTrustScore(widget.ratedUserId, _rating);
      showSnackBar(context, 'Thank you for your rating!');
      Navigator.of(context).pop();
    } catch (e) {
      showSnackBar(context, 'Failed to submit rating: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  Widget buildStar(int star) {
    return IconButton(
      icon: Icon(
        _rating >= star ? Icons.star : Icons.star_border,
        color: Colors.amber,
        size: 32,
      ),
      onPressed: () {
        setState(() {
          _rating = star;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Rate User'),
          backgroundColor: mobileBackgroundColor,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Rate your experience',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) => buildStar(index + 1)),
                ),
                const SizedBox(height: 20),
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: submitRating,
                        child: const Text('Submit Rating'),
                      ),
              ],
            ),
          ),
        ));
  }
}
