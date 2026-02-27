import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/theme_provider.dart';
import '../../services/database_service.dart';
import '../../models/habit_model.dart';
import '../../services/auth_service.dart';

class DailyCheckInDialog extends StatefulWidget {
  final List<HabitModel> unloggedHabits;

  const DailyCheckInDialog({super.key, required this.unloggedHabits});

  static Future<void> showIfNeeded(BuildContext context) async {
    final dbService = DatabaseService();
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user == null) return;

    final todayStr = DateTime.now().toIso8601String().split('T').first;

    // Fetch habits once for a quick check instead of listening to a stream globally here
    final habitsStream = dbService.getUserHabits(user.uid);
    final allHabits = await habitsStream.first;
    
    final List<HabitModel> unlogged = [];
    for (var h in allHabits) {
       if (h.lastCheckIn == null) {
          unlogged.add(h);
       } else {
          final lastCheckInStr = h.lastCheckIn!.toDate().toIso8601String().split('T').first;
          if (lastCheckInStr != todayStr) {
             unlogged.add(h);
          }
       }
    }

    if (unlogged.isNotEmpty && context.mounted) {
       showDialog(
         context: context,
         barrierDismissible: true, // Allow dismissal if busy
         builder: (ctx) => DailyCheckInDialog(unloggedHabits: unlogged),
       );
    }
  }

  @override
  State<DailyCheckInDialog> createState() => _DailyCheckInDialogState();
}

class _DailyCheckInDialogState extends State<DailyCheckInDialog> {
  final DatabaseService _dbService = DatabaseService();
  int _currentIndex = 0;
  bool _isSubmitting = false;

  void _submitAction(String status) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final habit = widget.unloggedHabits[_currentIndex];
    final authService = context.read<AuthService>();
    final user = authService.currentUser;

    if (user != null) {
       await _dbService.checkInHabit(user.uid, habit.id, status, null);
    }
    
    if (mounted) {
       if (_currentIndex < widget.unloggedHabits.length - 1) {
          setState(() {
            _currentIndex++;
            _isSubmitting = false;
          });
       } else {
          Navigator.pop(context); // All done
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.unloggedHabits.isEmpty) return const SizedBox.shrink();

    final theme = context.watch<ThemeProvider>();
    final habit = widget.unloggedHabits[_currentIndex];
    final color = Color(int.parse(habit.color.replaceAll('#', '0xff')));

    return Dialog(
      backgroundColor: theme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'كيف كان يومك؟', 
              style: GoogleFonts.cairo(color: theme.primaryText, fontSize: 24, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            Text(
              '(${_currentIndex + 1} من ${widget.unloggedHabits.length})', 
              style: GoogleFonts.tajawal(color: theme.textSecondary, fontSize: 14)
            ),
            
            const SizedBox(height: 24),
            CircleAvatar(backgroundColor: color.withValues(alpha: 0.2), radius: 40, child: Text(habit.icon, style: const TextStyle(fontSize: 40))),
            const SizedBox(height: 16),
            Text(habit.name, style: GoogleFonts.cairo(color: theme.primaryText, fontSize: 22, fontWeight: FontWeight.bold)),
            
            const SizedBox(height: 32),
            
            _isSubmitting 
              ? CircularProgressIndicator(color: theme.accentOrange)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  textDirection: TextDirection.rtl,
                  children: [
                    _buildBtn('✅', 'نظيف', Colors.green, () => _submitAction('clean')),
                    _buildBtn('⚠️', 'زلة', Colors.redAccent, () => _submitAction('slip')),
                    _buildBtn('⏭️', 'تخطي', Colors.grey, () => _submitAction('skip')),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildBtn(String icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.cairo(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
