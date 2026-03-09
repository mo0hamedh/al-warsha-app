import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/admin_task.dart';

class AdminTaskCard extends StatelessWidget {
  final AdminTask task;
  final bool isCompleted;
  final VoidCallback onComplete;

  const AdminTaskCard({
    super.key,
    required this.task,
    required this.isCompleted,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF202020),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF333333)
              : const Color(0xFFFF6A00).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: isCompleted ? null : onComplete,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? const Color(0xFFFF6A00) : Colors.transparent,
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFFFF6A00)
                      : const Color(0xFFFF6A00).withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Center(
                      child: Text(
                        "✓",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  task.title,
                  style: GoogleFonts.ibmPlexSansArabic(
                    color: isCompleted
                        ? const Color(0xFF555555)
                        : const Color(0xFFEBEBEB),
                    fontSize: 14,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (task.description != null && task.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    task.description!,
                    style: GoogleFonts.ibmPlexSansArabic(
                      color: const Color(0xFF666666),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // النقاط
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "+${task.points} ⭐",
              style: GoogleFonts.ibmPlexSansArabic(
                color: const Color(0xFFFF6A00),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
