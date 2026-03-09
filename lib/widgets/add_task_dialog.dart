import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import '../models/category_data.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import 'custom_category_dialog.dart';

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
  String _selectedCategory = 'other';

  void _submit() async {
    if (_titleController.text.trim().isEmpty) return;
    
    // Convert time to int, default to 0 if invalid/empty
    int estimatedMinutes = int.tryParse(_timeController.text.trim()) ?? 0;

    setState(() => _isLoading = true);
    final error = await context.read<TaskProvider>().addTask(
      _titleController.text.trim(),
      _descController.text.trim(),
      estimatedMinutes,
      category: _selectedCategory,
    );
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error, style: GoogleFonts.ibmPlexSansArabic()),
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
        title: Text('مهمة جديدة', style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: theme.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText),
              decoration: InputDecoration(
                labelText: 'العنوان',
                labelStyle: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.accentOrange, width: 2)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText),
              decoration: InputDecoration(
                labelText: 'الوصف (اختياري)',
                labelStyle: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.accentOrange, width: 2)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1))),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _timeController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText),
              decoration: InputDecoration(
                labelText: 'الوقت المقدر (بالدقائق) - اختياري',
                labelStyle: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.accentOrange, width: 2)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1))),
                suffixText: 'دقيقة',
                suffixStyle: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'التصنيف',
                style: GoogleFonts.ibmPlexSansArabic(
                  color: theme.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<TaskCategory>>(
              stream: context.read<AuthService>().currentUser != null
                  ? DatabaseService().getCustomCategories(context.read<AuthService>().currentUser!.uid)
                  : Stream.value([]),
              builder: (context, snapshot) {
                final customCategories = snapshot.data ?? [];
                final allCategories = [...taskCategories, ...customCategories];

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...allCategories.map((cat) {
                        final isSelected = _selectedCategory == cat.id;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: GestureDetector(
                            onLongPress: cat.isCustom ? () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  backgroundColor: theme.card,
                                  title: Text('حذف التصنيف؟', style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontWeight: FontWeight.bold)),
                                  content: Text('هل أنت متأكد من حذف تصنيف "${cat.name}"؟', style: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: Text('إلغاء')),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                      onPressed: () => Navigator.pop(context, true),
                                      child: Text('حذف', style: TextStyle(color: Colors.white)),
                                    ),
                                  ]
                                )
                              );
                              if (confirm == true) {
                                final user = context.read<AuthService>().currentUser;
                                if (user != null) {
                                  await DatabaseService().deleteCustomCategory(user.uid, cat.id);
                                  if (_selectedCategory == cat.id) setState(() => _selectedCategory = 'other');
                                }
                              }
                            } : null,
                            child: ChoiceChip(
                              label: Text(
                                cat.name,
                                style: GoogleFonts.ibmPlexSansArabic(
                                  color: isSelected ? Colors.white : theme.textSecondary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                              avatar: Icon(cat.icon, size: 16, color: isSelected ? Colors.white : cat.color),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() => _selectedCategory = cat.id);
                              },
                              selectedColor: cat.color,
                              backgroundColor: theme.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: isSelected ? cat.color : Colors.transparent),
                              ),
                              showCheckmark: false,
                            ),
                          ),
                        );
                      }),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                        child: ActionChip(
                          avatar: Icon(Icons.add, size: 16, color: theme.accentOrange),
                          label: Text('+ تصنيف جديد', style: GoogleFonts.ibmPlexSansArabic(fontSize: 12, color: theme.accentOrange, fontWeight: FontWeight.bold)),
                          backgroundColor: theme.accentOrange.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: theme.accentOrange.withOpacity(0.5)),
                          ),
                          onPressed: () async {
                            final newCategory = await showDialog<TaskCategory>(
                              context: context,
                              builder: (_) => const CustomCategoryDialog(),
                            );
                            if (newCategory != null) {
                              setState(() => _selectedCategory = newCategory.id);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.ibmPlexSansArabic(color: Colors.grey)),
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
                : Text('إضافة', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
