class BadgeData {
  final String id;
  final String icon;
  final String label;

  const BadgeData({
    required this.id,
    required this.icon,
    required this.label,
  });
}

class AppBadges {
  static const Map<String, BadgeData> badges = {
    'gold_feb_2026': BadgeData(id: 'gold_feb_2026', icon: '🥇', label: 'متصدر فبراير 2026'),
    'silver_feb_2026': BadgeData(id: 'silver_feb_2026', icon: '🥈', label: 'ثاني فبراير 2026'),
    'bronze_feb_2026': BadgeData(id: 'bronze_feb_2026', icon: '🥉', label: 'ثالث فبراير 2026'),
    'top10_feb_2026': BadgeData(id: 'top10_feb_2026', icon: '🏅', label: 'Top 10 فبراير 2026'),
    // يمكن إضافة المزيد من الأوسمة مستقبلاً هنا
  };

  static BadgeData? getBadge(String id) {
    return badges[id];
  }
}
