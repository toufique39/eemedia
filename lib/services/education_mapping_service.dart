
class EducationMappingService {
  static List<String> getDepartments(String educationLevel) {
    switch (educationLevel) {
      case 'school':
        return ['General'];

      case 'college':
        return ['Computer Science', 'Engineering', 'Business Studies'];

      case 'university':
        return [
          'IoT & Robotics Engineering',
          'Computer Science',
          'Software Engineering',
          'EEE',
          'Civil Engineering',
          'Business Studies',
          'Medical',
        ];

      case 'other':
        return ['General'];

      default:
        return ['General'];
    }
  }
}
