class APIConstants {
  // Private constructor to prevent instantiation
  APIConstants._();

  // Apple Sign In Configuration
  static const String appleClientId = 'com.example.viralApp';
  static const String appleRedirectUri = 'https://viral-app-firebase.firebaseapp.com/__/auth/handler';
  
  // Apple Sign In Provider
  static const String appleProvider = 'apple.com';

  // Google AI / Gemini API Configuration
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image-preview:generateContent';
  static const String geminiVisionUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
}
