import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/theme_provider.dart';
import '../../services/database_service.dart';
import '../../models/schedule_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSchedulePanel extends StatefulWidget {
  const AdminSchedulePanel({super.key});

  @override
  State<AdminSchedulePanel> createState() => _AdminSchedulePanelState();
}

class _AdminSchedulePanelState extends State<AdminSchedulePanel> {
  final DatabaseService _dbService = DatabaseService();
  
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
    
    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('لوحة الإدارة - الجداول', style: GoogleFonts.cairo(color: theme.primaryText, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: theme.primaryText), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
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
              
              Text('العادات الافتراضية للجدول:', style: GoogleFonts.cairo(color: theme.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              Container(
                decoration: BoxDecoration(
                  color: theme.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.accentOrange.withValues(alpha: 0.3)),
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
            ],
          ),
        ),
      ),
    );
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
}
