/// Application-wide constants
class AppConstants {
  // App Info
  static const String appName = 'Team Teleprompter';
  static const String appVersion = '0.1.0';
  
  // Teleprompter Settings
  static const double defaultScrollSpeed = 60.0; // pixels per second
  static const double minScrollSpeed = 10.0;
  static const double maxScrollSpeed = 300.0;
  static const double scrollSpeedIncrement = 10.0;
  
  static const double defaultFontSize = 32.0;
  static const double minFontSize = 16.0;
  static const double maxFontSize = 72.0;
  static const double fontSizeIncrement = 2.0;
  
  // Script Settings
  static const int maxScriptNameLength = 100;
  static const int maxScriptContentLength = 50000;
  
  // Team Settings
  static const int maxTeamNameLength = 50;
  static const int maxTeamMembers = 50;
  
  // Cache Settings
  static const String hiveBoxName = 'teleprompter_cache';
  static const String hiveScriptsBox = 'scripts_cache';
  static const String hiveUserBox = 'user_cache';
  
  // Recording Settings
  static const int maxRecordingDuration = 3600; // 1 hour in seconds
  
  // Remote Control
  static const Duration remoteControlTimeout = Duration(seconds: 30);
  
  // Sync Settings
  static const Duration syncInterval = Duration(seconds: 5);
  
  // Firebase Collections
  static const String teamsCollection = 'teams';
  static const String usersCollection = 'users';
  static const String scriptsCollection = 'scripts';
  static const String sessionsCollection = 'sessions';
  static const String recordingsCollection = 'recordings';
}
