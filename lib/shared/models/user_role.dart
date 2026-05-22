/// User roles within a team
enum UserRole {
  publisher, // Can publish and manage scripts
  editor,    // Can write and edit scripts
  creator;   // Can read scripts and record
  
  String get displayName {
    switch (this) {
      case UserRole.publisher:
        return 'Publisher';
      case UserRole.editor:
        return 'Editor';
      case UserRole.creator:
        return 'Creator';
    }
  }
  
  String get description {
    switch (this) {
      case UserRole.publisher:
        return 'Manages and publishes scripts';
      case UserRole.editor:
        return 'Writes and edits scripts';
      case UserRole.creator:
        return 'Records content with teleprompter';
    }
  }
  
  /// Check if role has permission to edit scripts
  bool get canEdit => this == UserRole.publisher || this == UserRole.editor;
  
  /// Check if role has permission to publish scripts
  bool get canPublish => this == UserRole.publisher;
  
  /// Check if role has permission to record
  bool get canRecord => true; // All roles can record
}
