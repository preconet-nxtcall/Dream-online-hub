class TestUserCredential {
  final String label;
  final String email;
  final String password;
  final String role;
  final String? uniqueId;
  final String? mobile;

  const TestUserCredential({
    required this.label,
    required this.email,
    required this.password,
    required this.role,
    this.uniqueId,
    this.mobile,
  });
}

class TestCredentials {
  static const List<TestUserCredential> users = [
    TestUserCredential(
      label: 'Admin',
      email: 'admin@gmail.com',
      password: '12345',
      role: 'ADMIN',
      uniqueId: 'ADMIN-1',
      mobile: '1234567890',
    ),
    TestUserCredential(
      label: 'Agency (Ritdz 4k)',
      email: 'agency@gmail.com',
      password: '12345',
      role: 'AGENCY',
      uniqueId: 'AGENCY-23',
      mobile: '9000000000',
    ),
    TestUserCredential(
      label: 'User (Jhon Smith)',
      email: 'user@gmail.com',
      password: '12345',
      role: 'USER',
      mobile: '9000000002',
    ),
    TestUserCredential(
      label: 'User (Lorem Ipsum)',
      email: 'sample@gmail.com',
      password: '12345',
      role: 'USER',
      mobile: '9000000055',
    ),
  ];
}
