import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/habit_model.dart';
import '../../models/habit_categories.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final DatabaseService _dbService = DatabaseService();
  final PageController _pageController = PageController();
  
  int _currentStep = 0;

  // Selected Data
  String? _selectedType; // 'positive' or 'negative'
  PredefinedHabit? _selectedHabit;
  int _selectedTargetDays = 21;
  final TextEditingController _customDaysController = TextEditingController();

  void _nextStep() {
    if (_currentStep < 3) {
       _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
       setState(() { _currentStep++; });
    } else {
       _submitHabit();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
       _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
       setState(() { _currentStep--; });
    } else {
       Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _customDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    
    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.primaryText, size: 20),
          onPressed: _prevStep,
        ),
        title: Text(
          'إضافة عادة جديدة',
          style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / 4,
                  backgroundColor: theme.card,
                  color: theme.accentOrange,
                  minHeight: 6,
                ),
              ),
            ),
            
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Prevent manual swipe
                children: [
                  _buildStep1TypeSelection(theme),
                  _buildStep2HabitSelection(theme),
                  _buildStep3DurationSelection(theme),
                  _buildStep4Summary(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Positive vs Negative ──────────────────────────────────────────
  Widget _buildStep1TypeSelection(ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('اختر نوع العادة', style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          _typeCard(
             title: 'بناء عادة إيجابية',
             subtitle: 'أريد الالتزام بشيء مفيد لحياتي',
             type: 'positive',
             color: Colors.green,
             icon: Icons.add_task,
             theme: theme,
          ),
          const SizedBox(height: 24),
          _typeCard(
             title: 'الإقلاع عن عادة سلبية',
             subtitle: 'أريد التخلص من عادة تضرني',
             type: 'negative',
             color: Colors.redAccent,
             icon: Icons.block,
             theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _typeCard({required String title, required String subtitle, required String type, required Color color, required IconData icon, required ThemeProvider theme}) {
    final bool isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          _selectedHabit = null; // reset if changed
        });
        Future.delayed(const Duration(milliseconds: 300), _nextStep);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : theme.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : (theme.isDarkMode ? Colors.white12 : Colors.black12), width: isSelected ? 2 : 1),
          
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            CircleAvatar(backgroundColor: color.withValues(alpha: 0.2), radius: 30, child: Icon(icon, color: color, size: 30)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary, fontSize: 13)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // ── Step 2: Select Predefined Habit ───────────────────────────────────────
  Widget _buildStep2HabitSelection(ThemeProvider theme) {
    if (_selectedType == null) return const SizedBox.shrink();

    final habitsList = _selectedType == 'positive' 
        ? HabitCategoryData.positiveHabits 
        : HabitCategoryData.negativeHabits;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0).copyWith(bottom: 0),
          child: Text('اختر العادة', style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            itemCount: habitsList.length,
            itemBuilder: (context, index) {
              final habit = habitsList[index];
              final isSelected = _selectedHabit?.id == habit.id;
              final accentColor = Color(int.parse(habit.color.replaceAll('#', '0xff')));
              
              return GestureDetector(
                onTap: () {
                   setState(() => _selectedHabit = habit);
                   Future.delayed(const Duration(milliseconds: 300), _nextStep);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor.withValues(alpha: 0.15) : theme.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? accentColor : (theme.isDarkMode ? Colors.white12 : Colors.black12), width: isSelected ? 2 : 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(habit.icon, style: const TextStyle(fontSize: 40, fontFamilyFallback: ['NotoColorEmoji'])),
                      const SizedBox(height: 12),
                      Text(habit.name, style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(habit.category, style: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Step 3: Select Duration Target ────────────────────────────────────────
  Widget _buildStep3DurationSelection(ThemeProvider theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
           Text('ما هو هدفك؟', style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontSize: 24, fontWeight: FontWeight.bold)),
           const SizedBox(height: 8),
           Text('اختر مدة التحدي لتعويد عقلك', style: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary, fontSize: 16)),
           const SizedBox(height: 40),
           
           _durationTile(21, '21 يوم', 'الوقت الكافي لتكوين مسار عصبي جديد 🧠', theme),
           const SizedBox(height: 16),
           _durationTile(30, '30 يوم', 'تحدي الشهر، لبناء التزام أقوى 💪', theme),
           const SizedBox(height: 16),
           _durationTile(90, '90 يوم', 'تغيير أسلوب حياة كامل 👑', theme),
           const SizedBox(height: 16),
           _customDurationTile(theme),
           
           const SizedBox(height: 40),
           ElevatedButton(
             onPressed: _nextStep,
             style: ElevatedButton.styleFrom(
               backgroundColor: theme.accentOrange,
               minimumSize: const Size(double.infinity, 54),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
             ),
             child: Text('التالي', style: GoogleFonts.ibmPlexSansArabic(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
           )
        ],
      ),
    );
  }

  Widget _durationTile(int days, String title, String subtitle, ThemeProvider theme) {
    bool isSelected = _selectedTargetDays == days;
    return GestureDetector(
      onTap: () => setState(() => _selectedTargetDays = days),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? theme.accentOrange.withValues(alpha: 0.1) : theme.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? theme.accentOrange : (theme.isDarkMode ? Colors.white12 : Colors.black12), width: isSelected ? 2 : 1),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(title, style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
                   Text(subtitle, style: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: theme.accentOrange, size: 28)
            else Icon(Icons.circle_outlined, color: theme.textSecondary, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _customDurationTile(ThemeProvider theme) {
    bool isSelected = _selectedTargetDays != 21 && _selectedTargetDays != 30 && _selectedTargetDays != 90;
    return GestureDetector(
      onTap: () {
         setState(() {
            _selectedTargetDays = int.tryParse(_customDaysController.text) ?? 60;
         });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? theme.accentOrange.withValues(alpha: 0.1) : theme.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? theme.accentOrange : (theme.isDarkMode ? Colors.white12 : Colors.black12), width: isSelected ? 2 : 1),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('مدة مخصصة', style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
                   if (isSelected)
                     Padding(
                       padding: const EdgeInsets.only(top: 8.0),
                       child: TextField(
                         controller: _customDaysController,
                         keyboardType: TextInputType.number,
                         style: TextStyle(color: theme.primaryText),
                         decoration: InputDecoration(
                           hintText: 'أدخل عدد الأيام...',
                           hintStyle: TextStyle(color: theme.textSecondary),
                           isDense: true,
                           border: UnderlineInputBorder(borderSide: BorderSide(color: theme.accentOrange)),
                         ),
                         onChanged: (val) {
                           setState(() {
                             _selectedTargetDays = int.tryParse(val) ?? 60;
                           });
                         },
                       ),
                     ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: theme.accentOrange, size: 28)
            else Icon(Icons.circle_outlined, color: theme.textSecondary, size: 28),
          ],
        ),
      ),
    );
  }

  // ── Step 4: Summary ───────────────────────────────────────────────────────
  Widget _buildStep4Summary(ThemeProvider theme) {
    if (_selectedHabit == null) return const SizedBox.shrink();
    
    final color = Color(int.parse(_selectedHabit!.color.replaceAll('#', '0xff')));
    final typeText = _selectedType == 'positive' ? 'بناء عادة' : 'إقلاع عن';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(backgroundColor: color.withValues(alpha: 0.2), radius: 60, child: Text(_selectedHabit!.icon, style: const TextStyle(fontSize: 60, fontFamilyFallback: ['NotoColorEmoji']))),
          const SizedBox(height: 24),
          Text(typeText, style: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary, fontSize: 18)),
          Text(_selectedHabit!.name, style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
             decoration: BoxDecoration(color: theme.card, borderRadius: BorderRadius.circular(8), border: Border.all(color: color)),
             child: Text('الهدف: $_selectedTargetDays يوم', style: GoogleFonts.ibmPlexSansArabic(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          
          const Spacer(),
          ElevatedButton(
            onPressed: () => _submitHabit(),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.accentOrange,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 8,
              shadowColor: theme.accentOrange.withValues(alpha: 0.5),
            ),
            child: Text('ابدأ التحدي 🚀', style: GoogleFonts.ibmPlexSansArabic(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _submitHabit() async {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user == null || _selectedHabit == null) return;

    final habitId = DateTime.now().millisecondsSinceEpoch.toString();

    final newHabit = HabitModel(
      id: habitId,
      name: _selectedHabit!.name,
      type: _selectedHabit!.type,
      category: _selectedHabit!.category,
      icon: _selectedHabit!.icon,
      color: _selectedHabit!.color,
      targetDays: _selectedTargetDays,
      startDate: Timestamp.now(),
    );

    // Show loading
    showDialog(context: context, barrierDismissible: false, builder: (_) => Center(child: CircularProgressIndicator(color: context.read<ThemeProvider>().accentOrange)));

    await _dbService.addHabit(user.uid, newHabit);

    if (mounted) {
      Navigator.pop(context); // close dialog
      Navigator.pop(context); // close screen
    }
  }
}
