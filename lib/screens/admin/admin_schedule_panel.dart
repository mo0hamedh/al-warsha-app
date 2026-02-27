import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/theme_provider.dart';
import '../../services/database_service.dart';
import '../../models/schedule_model.dart';
import '../../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSchedulePanel extends StatefulWidget {
  const AdminSchedulePanel({super.key});

  @override
  State<AdminSchedulePanel> createState() => _AdminSchedulePanelState();
}

class _AdminSchedulePanelState extends State<AdminSchedulePanel> {
  final DatabaseService _dbService = DatabaseService();
  
  // Fields for Schedules Tab
  final TextEditingController _monthController = TextEditingController();
  int _weekNumber = 1;

  final List<ScheduleHabitModel> _defaultHabits = [
    ScheduleHabitModel(id: '1', name: 'بث الورشة', icon: '📻', type: 'checkbox'),
    ScheduleHabitModel(id: '2', name: 'اذكار الصباح', icon: '🌅', type: 'checkbox'),
    ScheduleHabitModel(id: '3', name: 'الضحى', icon: '☀️', type: 'checkbox'),
    ScheduleHabitModel(id: '4', name: 'النوافل / ١٢', icon: '🕌', type: 'checkbox'),
    ScheduleHabitModel(id: '5', name: 'الـ٥ صلوات', icon: '🕋', type: 'checkbox'),
    ScheduleHabitModel(id: '6', name: 'اذكار المساء', icon: '🌙', type: 'checkbox'),
    ScheduleHabitModel(id: '7', name: 'قيام الليل', icon: '✨', type: 'checkbox'),
    ScheduleHabitModel(id: '8', name: 'ورد المراجعة', icon: '📖', type: 'checkbox'),
    ScheduleHabitModel(id: '9', name: 'ذكرت ربنا كام مرة', icon: '📿', type: 'number'),
    ScheduleHabitModel(id: '10', name: 'ورد القرآن', icon: '📗', type: 'checkbox'),
    ScheduleHabitModel(id: '11', name: 'الصدقة', icon: '💝', type: 'checkbox'),
    ScheduleHabitModel(id: '12', name: 'ذاكرت كام ساعة', icon: '📚', type: 'number'),
  ];
  
  late List<ScheduleHabitModel> _selectedHabits;

  // Fields for Subscriptions Tab
  final TextEditingController _searchController = TextEditingController();
  UserModel? _searchedUser;
  bool _isSearching = false;
  String? _searchError;

  // Fields for Users Progress
  List<Map> _usersProgress = [];
  bool _isLoadingProgress = false;
  String? _currentLoadedWeekId;

  Future<void> _loadProgress(String activeWeekId) async {
    setState(() => _isLoadingProgress = true);
    final data = await _dbService.getPremiumUsersProgress(activeWeekId);
    if (mounted) {
      setState(() {
        _usersProgress = data;
        _isLoadingProgress = false;
        _currentLoadedWeekId = activeWeekId;
      });
    }
  }

  // Fields for Notifications Tab
  final TextEditingController _notifTitleController = TextEditingController();
  final TextEditingController _notifBodyController = TextEditingController();
  String _notifTargetGroup = 'الكل';


  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _monthController.text = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _selectedHabits = List.from(_defaultHabits);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: theme.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('لوحة الإدارة', style: GoogleFonts.cairo(color: theme.primaryText, fontWeight: FontWeight.bold)),
          leading: IconButton(icon: Icon(Icons.arrow_back, color: theme.primaryText), onPressed: () => Navigator.pop(context)),
          bottom: TabBar(
            labelColor: theme.accentOrange,
            unselectedLabelColor: theme.textSecondary,
            indicatorColor: theme.accentOrange,
            labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'الجداول', icon: Icon(Icons.calendar_month)),
              Tab(text: 'الاشتراكات', icon: Icon(Icons.workspace_premium)),
              Tab(text: 'إشعارات', icon: Icon(Icons.campaign)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSchedulesTab(theme),
            _buildSubscriptionsTab(theme),
            _buildNotificationsTab(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsTab(ThemeProvider theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📢 إرسال إشعار جديد', style: GoogleFonts.cairo(color: theme.primaryText, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: _notifTitleController,
              style: TextStyle(color: theme.primaryText),
              decoration: InputDecoration(
                labelText: 'عنوان الإشعار',
                labelStyle: TextStyle(color: theme.textSecondary),
                filled: true,
                fillColor: theme.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notifBodyController,
              maxLines: 4,
              style: TextStyle(color: theme.primaryText),
              decoration: InputDecoration(
                labelText: 'نص الإشعار',
                labelStyle: TextStyle(color: theme.textSecondary),
                filled: true,
                fillColor: theme.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('إرسال إلى:', style: GoogleFonts.cairo(color: theme.primaryText, fontSize: 16)),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _notifTargetGroup,
                  dropdownColor: theme.card,
                  style: GoogleFonts.cairo(color: theme.primaryText, fontWeight: FontWeight.bold),
                  items: ['الكل', 'المشتركين فقط', 'غير المشتركين'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _notifTargetGroup = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final title = _notifTitleController.text.trim();
                  final body = _notifBodyController.text.trim();
                  if (title.isEmpty || body.isEmpty) return;

                  await _dbService.sendNotificationToAll(title, body, _notifTargetGroup);
                  
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم الإرسال بنجاح', style: GoogleFonts.cairo())));
                  _notifTitleController.clear();
                  _notifBodyController.clear();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.accentOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                child: Text('إرسال 📢', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulesTab(ThemeProvider theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إنشاء جدول جديد', style: GoogleFonts.cairo(color: theme.primaryText, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Month Input
            TextField(
              controller: _monthController,
              style: TextStyle(color: theme.primaryText),
              decoration: InputDecoration(
                labelText: 'الشهر (مثال: 2026-02)',
                labelStyle: TextStyle(color: theme.textSecondary),
                filled: true,
                fillColor: theme.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Week Selector
            Row(
              children: [
                Text('رقم الأسبوع:', style: GoogleFonts.cairo(color: theme.primaryText, fontSize: 16)),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: _weekNumber,
                  dropdownColor: theme.card,
                  style: GoogleFonts.cairo(color: theme.primaryText, fontWeight: FontWeight.bold),
                  items: [1, 2, 3, 4, 5].map((w) => DropdownMenuItem(value: w, child: Text('الأسبوع $w'))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _weekNumber = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('عادات الجدول المستهدفة:', style: GoogleFonts.cairo(color: theme.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => _showAddCustomHabitDialog(context, theme),
                  icon: Icon(Icons.add, color: theme.accentOrange, size: 18),
                  label: Text('إضافة مخصصة', style: GoogleFonts.cairo(color: theme.accentOrange, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Container(
              decoration: BoxDecoration(
                color: theme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.accentOrange.withOpacity(0.3)),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedHabits.length,
                itemBuilder: (context, index) {
                   final habit = _selectedHabits[index];
                   return ListTile(
                     leading: Text(habit.icon, style: const TextStyle(fontSize: 24)),
                     title: Text(habit.name, style: GoogleFonts.cairo(color: theme.primaryText)),
                     subtitle: Text(habit.type == 'checkbox' ? 'نوع: علامة صح' : 'نوع: إدخال الرقم', style: GoogleFonts.cairo(color: theme.textSecondary, fontSize: 12)),
                     trailing: IconButton(
                       icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                       onPressed: () {
                         setState(() => _selectedHabits.removeAt(index));
                       },
                     ),
                   );
                }
              ),
            ),

            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _publishSchedule,
              icon: const Icon(Icons.publish),
              label: Text('نشر الجدول وجعله النشط ✅', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.accentOrange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 48),

            // ── قسم تقدم المشتركين في الجدول الحالي ──
            StreamBuilder<WeeklyScheduleModel?>(
              stream: _dbService.getActiveSchedule(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return const SizedBox(); // لا يوجد جدول نشط
                }

                final activeSchedule = snapshot.data!;
                
                // جلب البيانات أول مرة عند ظهور الجدول
                if (_currentLoadedWeekId != activeSchedule.id && !_isLoadingProgress) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _loadProgress(activeSchedule.id);
                  });
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '👥 تقدم المشتركين - ${activeSchedule.month} أسبوع ${activeSchedule.weekNumber}',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: () => _loadProgress(activeSchedule.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isLoadingProgress)
                      const Center(child: CircularProgressIndicator(color: Color(0xFFFF6A00)))
                    else if (_usersProgress.isEmpty)
                      Center(
                        child: Text(
                          'لا يوجد تقدم للمشتركين بعد.',
                          style: GoogleFonts.cairo(color: theme.textSecondary),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _usersProgress.length,
                        itemBuilder: (context, index) {
                          final userMap = _usersProgress[index];
                          final double completionRate = userMap['completionRate'] ?? 0.0;
                          final Color progressColor = completionRate >= 0.8
                              ? const Color(0xFF66BB6A) // 80%+ -> أخضر
                              : completionRate >= 0.5
                                  ? const Color(0xFFFF6A00) // 50-79% -> برتقالي
                                  : const Color(0xFFFF5252); // أقل -> أحمر

                          return Card(
                            color: theme.card,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '#${index + 1} ${userMap['name']}',
                                          style: GoogleFonts.cairo(
                                            color: theme.primaryText,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '${(completionRate * 100).toInt()}%',
                                        style: GoogleFonts.tajawal(
                                          color: progressColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  LinearProgressIndicator(
                                    value: completionRate,
                                    backgroundColor: const Color(0xFF2A2A2A),
                                    color: progressColor,
                                    minHeight: 6,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      onPressed: () => _showUserDetailsSheet(
                                        context,
                                        theme,
                                        userMap,
                                        activeSchedule,
                                      ),
                                      icon: const Icon(Icons.remove_red_eye, size: 16, color: Colors.blueAccent),
                                      label: Text(
                                        'تفاصيل',
                                        style: GoogleFonts.cairo(color: Colors.blueAccent, fontSize: 13),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDetailsSheet(BuildContext context, ThemeProvider theme, Map userMap, WeeklyScheduleModel schedule) {
    final Map daysProgress = userMap['progress'] ?? {};
    final userName = userMap['name'] ?? 'مستخدم';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تفاصيل تقدم: $userName', style: GoogleFonts.cairo(color: theme.primaryText, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        controller: controller,
                        itemCount: 7,
                        itemBuilder: (context, dayIndex) {
                          final daysAr = ['السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
                          final currentDayStr = daysAr[dayIndex];
                          final Map todayMap = daysProgress[currentDayStr] ?? {};

                          return Card(
                            color: theme.card,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              collapsedIconColor: theme.textSecondary,
                              iconColor: theme.accentOrange,
                              title: Text(currentDayStr, style: GoogleFonts.cairo(color: theme.primaryText, fontWeight: FontWeight.bold)),
                              children: schedule.habits.map((habit) {
                                final val = todayMap[habit.name];
                                bool isCompleted = false;
                                String displayVal = '⬜';

                                if (habit.type == 'checkbox') {
                                  if (val == true) {
                                    isCompleted = true;
                                    displayVal = '✅';
                                  }
                                } else {
                                  if (val != null && val is num && val > 0) {
                                    isCompleted = true;
                                    displayVal = '✅ ($val)';
                                  }
                                }

                                return ListTile(
                                  leading: Text(habit.icon, style: const TextStyle(fontSize: 20)),
                                  title: Text(habit.name, style: GoogleFonts.cairo(color: isCompleted ? const Color(0xFF66BB6A) : theme.textSecondary)),
                                  trailing: Text(displayVal, style: GoogleFonts.tajawal(color: theme.primaryText)),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSubscriptionsTab(ThemeProvider theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إدارة الاشتراكات المميزة', style: GoogleFonts.cairo(color: theme.primaryText, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Search Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: theme.primaryText),
                    decoration: InputDecoration(
                      hintText: 'أدخل كود الدعوة',
                      hintStyle: TextStyle(color: theme.textSecondary),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E), // Required by prompt
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.accentOrange)),
                    ),
                    onChanged: (val) {
                      if (_searchedUser != null || _searchError != null) {
                        setState(() { _searchedUser = null; _searchError = null; });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSearching ? null : _searchUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.accentOrange,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSearching 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.search, color: Colors.white),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            if (_searchError != null)
              Text(_searchError!, style: GoogleFonts.cairo(color: const Color(0xFFFF5252), fontSize: 16)),
              
            if (_searchedUser != null)
              _buildUserSubscriptionCard(_searchedUser!, theme),
          ],
        ),
      ),
    );
  }

  Future<void> _searchUser() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    
    setState(() { _isSearching = true; _searchError = null; _searchedUser = null; });
    
    final user = await _dbService.searchByInviteCode(query);
    
    setState(() {
      _isSearching = false;
      if (user == null) {
        _searchError = 'لا يوجد مستخدم بهذا الكود';
      } else {
        _searchedUser = user;
      }
    });
  }

  Widget _buildUserSubscriptionCard(UserModel user, ThemeProvider theme) {
    final isActive = user.isPremium;
    final isExpired = !user.isPremium && user.premiumEndDate != null && user.premiumEndDate!.isBefore(DateTime.now());
    
    String badgeText = isActive ? 'نشط' : (isExpired ? 'منتهي' : 'غير مشترك');
    Color badgeColor = isActive ? Colors.green : (isExpired ? const Color(0xFFFF5252) : Colors.grey);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.accentOrange, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: GoogleFonts.cairo(color: theme.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(user.email, style: GoogleFonts.cairo(color: theme.textSecondary, fontSize: 14)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor),
                ),
                child: Text(badgeText, style: GoogleFonts.cairo(color: badgeColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          
          if (user.premiumEndDate != null && isActive) ...[
            const SizedBox(height: 16),
            Text(
              'تاريخ الانتهاء: ${user.premiumEndDate!.toLocal().toString().split(' ')[0]}',
              style: GoogleFonts.cairo(color: theme.textSecondary),
            ),
          ],
          
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleSubscriptionAction(user, true, theme),
                  icon: const Icon(Icons.check, color: Colors.white, size: 18),
                  label: Text('تفعيل 30 يوم', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleSubscriptionAction(user, false, theme),
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  label: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5252),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubscriptionAction(UserModel user, bool activate, ThemeProvider theme) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.card,
        title: Text(activate ? 'تفعيل الاشتراك؟' : 'إلغاء الاشتراك؟', style: GoogleFonts.cairo(color: theme.primaryText, fontWeight: FontWeight.bold)),
        content: Text(
          activate 
            ? 'سيتم تفعيل الاشتراك المميز للمستخدم لمدة 30 يوماً.' 
            : 'سيتم إلغاء الاشتراك المميز فوراً.',
          style: GoogleFonts.cairo(color: theme.textSecondary),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: activate ? Colors.green : const Color(0xFFFF5252)),
            child: Text('تأكيد', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (activate) {
        await _dbService.activatePremium(user.id);
      } else {
        await _dbService.deactivatePremium(user.id);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(activate ? 'تم التفعيل' : 'تم الإلغاء', style: GoogleFonts.cairo()),
          backgroundColor: activate ? Colors.green : const Color(0xFFFF5252),
        ));
        _searchUser(); // Refresh user data
      }
    }
  }

  Future<void> _publishSchedule() async {
     final id = '${_monthController.text}_W$_weekNumber';
     final newSchedule = WeeklyScheduleModel(
       id: id,
       weekNumber: _weekNumber,
       month: _monthController.text,
       habits: _selectedHabits,
       createdAt: Timestamp.now(),
       isActive: true, // Auto activates
     );

     // Show loading
     showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

     await _dbService.createWeeklySchedule(newSchedule);

     if (mounted) {
       Navigator.pop(context); // Close loading
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم نشر الجدول بنجاح!'), backgroundColor: Colors.green));
       Navigator.pop(context); // Close screen
     }
  }

  void _showAddCustomHabitDialog(BuildContext context, ThemeProvider theme) {
    final nameCtrl = TextEditingController();
    final iconCtrl = TextEditingController();
    String type = 'checkbox'; 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: EdgeInsets.only(
                  top: 24, left: 24, right: 24,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('إضافة عادة مخصصة للجدول', style: GoogleFonts.cairo(color: theme.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: theme.primaryText),
                      decoration: InputDecoration(
                        labelText: 'اسم العادة',
                        labelStyle: TextStyle(color: theme.textSecondary),
                        filled: true,
                        fillColor: theme.card,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: iconCtrl,
                      style: TextStyle(color: theme.primaryText),
                      decoration: InputDecoration(
                        labelText: 'أيقونة العادة (إيموجي)',
                        labelStyle: TextStyle(color: theme.textSecondary),
                        filled: true,
                        fillColor: theme.card,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('نوع التتبع:', style: GoogleFonts.cairo(color: theme.primaryText, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            contentPadding: EdgeInsets.zero,
                            title: Text('علامة صح (✅)', style: GoogleFonts.cairo(color: theme.primaryText, fontSize: 14)),
                            value: 'checkbox',
                            groupValue: type,
                            activeColor: theme.accentOrange,
                            onChanged: (val) => setModalState(() => type = val!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            contentPadding: EdgeInsets.zero,
                            title: Text('رقم (إدخال يدوي)', style: GoogleFonts.cairo(color: theme.primaryText, fontSize: 14)),
                            value: 'number',
                            groupValue: type,
                            activeColor: theme.accentOrange,
                            onChanged: (val) => setModalState(() => type = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.accentOrange,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (nameCtrl.text.trim().isEmpty || iconCtrl.text.trim().isEmpty) return;
                        setState(() {
                          _selectedHabits.add(ScheduleHabitModel(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: nameCtrl.text.trim(),
                            icon: iconCtrl.text.trim(),
                            type: type,
                          ));
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text('إضافة العادة', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
