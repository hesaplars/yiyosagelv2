import 'package:firebase_core/firebase_core.dart';

class AppConstants {
  AppConstants._();

  static const firebaseOptions = FirebaseOptions(
    apiKey: 'AIzaSyCFoQPV3kyha6k15VxHRJhIr8qjgvYjVeo',
    authDomain: 'yarisma-live-e6281.firebaseapp.com',
    projectId: 'yarisma-live-e6281',
    storageBucket: 'yarisma-live-e6281.firebasestorage.app',
    messagingSenderId: '143964244900',
    appId: '1:143964244900:web:fc2fa0222cddedeafc8f31',
    databaseURL: 'https://yarisma-live-e6281-default-rtdb.europe-west1.firebasedatabase.app',
  );

  static const List<String> letters = [
    'A', 'B', 'C', 'Ç', 'D', 'E', 'F', 'G', 'H', 'I', 'İ', 'K', 'L', 'M', 'N', 'O', 'Ö', 'P', 'R', 'S', 'Ş', 'T', 'U', 'Ü', 'V', 'Y', 'Z'
  ];

  static const List<String> avatars = [
    '🦊', '🐱', '🐼', '🦁', '🐸', '🐵', '🐰', '🐻', '🦉', '🐺', '🐲', '🦄', '🐧', '🦋', '🐬', '🐯', '🍄'
  ];

  static const List<List<String>> marketTabs = [
    ['avatarFrame', 'Çerçeveler'],
    ['cover', 'Kapaklar'],
    ['badge', 'Biyografi Rozetleri'],
    ['avatarBadge', 'Avatar Rozetleri'],
    ['title', 'Unvanlar'],
    ['chatStyle', 'Sohbet'],
    ['limitBoost', 'Limitler'],
    ['discount', 'İndirimler'],
  ];

  // System Rules & Limits
  static const int wordleGameTime = 300; // in seconds
  static const int dailyGameTime = 300; // in seconds
  static const int liveGameRoundTime = 15; // in seconds
  static const int leaderboardDisplayLimit = 100;
}
