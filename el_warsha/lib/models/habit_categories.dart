class PredefinedHabit {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String category;
  final String type; // 'negative' | 'positive'

  const PredefinedHabit({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.category,
    required this.type,
  });
}

class HabitCategoryData {
  static const List<PredefinedHabit> negativeHabits = [
    // إدمان
    PredefinedHabit(id: 'smoking', name: 'تدخين', icon: '🚭', color: '#FF5252', category: 'إدمان', type: 'negative'),
    PredefinedHabit(id: 'alcohol', name: 'كحول', icon: '🍺', color: '#FF7043', category: 'إدمان', type: 'negative'),
    PredefinedHabit(id: 'drugs', name: 'مخدرات', icon: '💊', color: '#AB47BC', category: 'إدمان', type: 'negative'),
    PredefinedHabit(id: 'masturbation', name: 'استمناء', icon: '🚫', color: '#EC407A', category: 'إدمان', type: 'negative'),
    
    // سوشيال ميديا
    PredefinedHabit(id: 'instagram', name: 'انستجرام', icon: '📸', color: '#E91E63', category: 'سوشيال ميديا', type: 'negative'),
    PredefinedHabit(id: 'tiktok', name: 'تيك توك', icon: '🎵', color: '#000000', category: 'سوشيال ميديا', type: 'negative'),
    PredefinedHabit(id: 'twitter', name: 'تويتر', icon: '🐦', color: '#1DA1F2', category: 'سوشيال ميديا', type: 'negative'),
    PredefinedHabit(id: 'youtube', name: 'يوتيوب', icon: '▶️', color: '#FF0000', category: 'سوشيال ميديا', type: 'negative'),
    
    // طعام
    PredefinedHabit(id: 'sugar', name: 'سكريات', icon: '🍬', color: '#FFA726', category: 'طعام', type: 'negative'),
    PredefinedHabit(id: 'fastfood', name: 'فاست فود', icon: '🍔', color: '#FF7043', category: 'طعام', type: 'negative'),
    PredefinedHabit(id: 'caffeine', name: 'كافيين زيادة', icon: '☕', color: '#795548', category: 'طعام', type: 'negative'),
    
    // أخرى
    PredefinedHabit(id: 'latesleep', name: 'سهر زيادة', icon: '🌙', color: '#5C6BC0', category: 'أخرى', type: 'negative'),
    PredefinedHabit(id: 'series', name: 'مسلسلات', icon: '📺', color: '#26C6DA', category: 'أخرى', type: 'negative'),
    PredefinedHabit(id: 'gambling', name: 'قمار', icon: '🎰', color: '#66BB6A', category: 'أخرى', type: 'negative'),
  ];

  static const List<PredefinedHabit> positiveHabits = [
    // صحة
    PredefinedHabit(id: 'exercise', name: 'رياضة', icon: '💪', color: '#FF6A00', category: 'صحة', type: 'positive'),
    PredefinedHabit(id: 'sleep', name: 'نوم مبكر', icon: '😴', color: '#5C6BC0', category: 'صحة', type: 'positive'),
    PredefinedHabit(id: 'water', name: 'شرب مية', icon: '💧', color: '#29B6F6', category: 'صحة', type: 'positive'),
    PredefinedHabit(id: 'healthyfood', name: 'أكل صحي', icon: '🥗', color: '#66BB6A', category: 'صحة', type: 'positive'),
    
    // تطوير
    PredefinedHabit(id: 'reading', name: 'قراءة', icon: '📚', color: '#FF6A00', category: 'تطوير', type: 'positive'),
    PredefinedHabit(id: 'learning', name: 'تعلم مهارة', icon: '🎯', color: '#AB47BC', category: 'تطوير', type: 'positive'),
    PredefinedHabit(id: 'studying', name: 'مذاكرة', icon: '✏️', color: '#26C6DA', category: 'تطوير', type: 'positive'),
    
    // روحاني
    PredefinedHabit(id: 'prayer', name: 'صلاة', icon: '🕌', color: '#66BB6A', category: 'روحاني', type: 'positive'),
    PredefinedHabit(id: 'quran', name: 'قرآن', icon: '📖', color: '#FFA726', category: 'روحاني', type: 'positive'),
    PredefinedHabit(id: 'meditation', name: 'تأمل', icon: '🧘', color: '#26C6DA', category: 'روحاني', type: 'positive'),
  ];
}
