import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/category_data.dart';

class CustomCategoryDialog extends StatefulWidget {
  const CustomCategoryDialog({super.key});

  @override
  State<CustomCategoryDialog> createState() => _CustomCategoryDialogState();
}

class _CustomCategoryDialogState extends State<CustomCategoryDialog> {
  final _nameController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();

  final List<Color> _colors = [
    Colors.redAccent,
    Colors.orangeAccent,
    Colors.yellowAccent,
    Colors.greenAccent,
    Colors.lightBlueAccent,
    Colors.purpleAccent,
    Colors.pinkAccent,
  ];

  final List<IconData> _icons = [
    Icons.star_rounded,
    Icons.favorite_rounded,
    Icons.flag_rounded,
    Icons.bolt_rounded,
    Icons.diamond_rounded,
    Icons.sports_esports_rounded,
    Icons.music_note_rounded,
    Icons.fitness_center_rounded,
  ];

  Color? _selectedColor;
  IconData? _selectedIcon;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedColor = _colors.first;
    _selectedIcon = _icons.first;
  }

  void _saveCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final user = context.read<AuthService>().currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    final newCategory = TaskCategory(
      id: const Uuid().v4(),
      name: name,
      icon: _selectedIcon!,
      color: _selectedColor!,
      isCustom: true,
    );

    try {
      await _dbService.saveCustomCategory(user.uid, newCategory);
      if (mounted) {
        Navigator.pop(context, newCategory); // Return the newly created category
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء الحفظ', style: GoogleFonts.ibmPlexSansArabic()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: theme.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
          ),
        ),
        title: Text('تصنيف جديد ✨', style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText),
                decoration: InputDecoration(
                  labelText: 'اسم التصنيف',
                  labelStyle: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.accentOrange, width: 2)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1))),
                ),
              ),
              const SizedBox(height: 24),
              Text('اختر اللون', style: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colors.map((color) {
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.white, width: 2) : Border.all(color: Colors.transparent),
                        
                      ),
                      child: isSelected ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text('اختر أيقونة', style: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _icons.map((icon) {
                  final isSelected = _selectedIcon == icon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? (_selectedColor ?? theme.accentOrange).withOpacity(0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? Border.all(color: _selectedColor ?? theme.accentOrange) : Border.all(color: Colors.transparent),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? (_selectedColor ?? theme.accentOrange) : theme.textSecondary,
                        size: 28,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.ibmPlexSansArabic(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveCategory,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.accentOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('حفظ', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
