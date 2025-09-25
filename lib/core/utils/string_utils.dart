/// Utility functions for string manipulation.
class StringUtils {
  StringUtils._();

  /// Converts text to title case (first letter of each word capitalized).
  static String toTitleCase(String text) {
    return text
        .split(' ')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : word)
        .join(' ');
  }
}
