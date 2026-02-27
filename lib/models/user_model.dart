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
  final int weeklyFocusMinutes; // دقائق التركيز الأسبوعية
  final List<Map<String, dynamic>> focusSessions; // سجل الجلسات
  final int monthlyPoints; // نقاط الشهر الحالي
  final List<String> allTimeBadges; // الأوسمة الدائمة
  final int bestRank; // أفضل مركز وصل إليه
  final bool isAdmin; // صلاحيات المشرف
  final bool isPremium; // مشترك في الخطة المميزة
  final DateTime? premiumEndDate; // تاريخ انتهاء الاشتراك

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
    this.weeklyFocusMinutes = 0,
    this.focusSessions = const [],
    this.monthlyPoints = 0,
    this.allTimeBadges = const [],
    this.bestRank = 0,
    this.isAdmin = false,
    this.isPremium = false,
    this.premiumEndDate,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      inviteCode: (data['inviteCode'] != null && data['inviteCode'].toString().isNotEmpty) 
          ? data['inviteCode'] 
          : (id.length >= 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase()),
      friends: List<String>.from(data['friends'] ?? []),
      friendRequests: List<String>.from(data['friendRequests'] ?? []),
      weeklyFocusPoints: data['weeklyFocusPoints'] ?? 0,
      totalFocusMinutes: data['totalFocusMinutes'] ?? 0,
      weeklyFocusMinutes: data['weeklyFocusMinutes'] ?? 0,
      focusSessions: List<Map<String, dynamic>>.from(data['focusSessions'] ?? []),
      monthlyPoints: data['monthlyPoints'] ?? 0,
      allTimeBadges: List<String>.from(data['allTimeBadges'] ?? []),
      bestRank: data['bestRank'] ?? 0,
      isAdmin: data['isAdmin'] ?? false,
      isPremium: data['isPremium'] ?? false,
      premiumEndDate: data['premiumEndDate'] != null ? (data['premiumEndDate'] as dynamic).toDate() : null,
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
      'weeklyFocusMinutes': weeklyFocusMinutes,
      'focusSessions': focusSessions,
      'monthlyPoints': monthlyPoints,
      'allTimeBadges': allTimeBadges,
      'bestRank': bestRank,
      'isAdmin': isAdmin,
      'isPremium': isPremium,
      'premiumEndDate': premiumEndDate,
    };
  }
}
