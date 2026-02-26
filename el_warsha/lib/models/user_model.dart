class UserModel {
  final String id;
  final String email;
  final String name;
  final String photoUrl;
  final String inviteCode;
  final List<String> friends;
  final List<String> friendRequests; // الطلبات المعلقة
  final int weeklyFocusPoints;
  final int totalFocusMinutes; // إجمالي دقائق التركيز المتراكمة

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl = '',
    this.inviteCode = '',
    this.friends = const [],
    this.friendRequests = const [],
    this.weeklyFocusPoints = 0,
    this.totalFocusMinutes = 0,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      inviteCode: data['inviteCode'] ?? '',
      friends: List<String>.from(data['friends'] ?? []),
      friendRequests: List<String>.from(data['friendRequests'] ?? []),
      weeklyFocusPoints: data['weeklyFocusPoints'] ?? 0,
      totalFocusMinutes: data['totalFocusMinutes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'inviteCode': inviteCode,
      'friends': friends,
      'friendRequests': friendRequests,
      'weeklyFocusPoints': weeklyFocusPoints,
      'totalFocusMinutes': totalFocusMinutes,
    };
  }
}
