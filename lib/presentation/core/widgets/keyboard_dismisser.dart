import 'package:flutter/material.dart';

/// A widget that dismisses the keyboard when the user taps outside of text fields
class KeyboardDismisser extends StatelessWidget {
  const KeyboardDismisser({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Global keyboard dismissal for the entire app
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: child,
    );
  }
}
