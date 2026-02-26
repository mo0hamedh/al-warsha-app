import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/task_provider.dart';

class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _timeController = TextEditingController();

  bool _isLoading = false;

  void _submit() async {
    if (_titleController.text.trim().isEmpty) return;
    
    // Convert time to int, default to 0 if invalid/empty
    int estimatedMinutes = int.tryParse(_timeController.text.trim()) ?? 0;

    setState(() => _isLoading = true);
    final error = await context.read<TaskProvider>().addTask(
      _titleController.text.trim(),
      _descController.text.trim(),
      estimatedMinutes,
    );
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error, style: GoogleFonts.cairo()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: theme.card,
        title: Text('مهمة جديدة', style: GoogleFonts.cairo(color: theme.primaryText, fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              style: GoogleFonts.cairo(color: theme.primaryText),
              decoration: InputDecoration(
                labelText: 'العنوان',
                labelStyle: GoogleFonts.cairo(color: theme.textSecondary),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.accentOrange, width: 2)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              style: GoogleFonts.cairo(color: theme.primaryText),
              decoration: InputDecoration(
                labelText: 'الوصف (اختياري)',
                labelStyle: GoogleFonts.cairo(color: theme.textSecondary),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.accentOrange, width: 2)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1))),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _timeController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.cairo(color: theme.primaryText),
              decoration: InputDecoration(
                labelText: 'الوقت المقدر (بالدقائق) - اختياري',
                labelStyle: GoogleFonts.cairo(color: theme.textSecondary),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.accentOrange, width: 2)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1))),
                suffixText: 'دقيقة',
                suffixStyle: GoogleFonts.cairo(color: theme.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.accentOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoading 
                ? const SizedBox(
                    height: 20, 
                    width: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : Text('إضافة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
