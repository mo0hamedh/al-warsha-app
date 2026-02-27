import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:dotted_border/dotted_border.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../models/study_room_model.dart';
import '../models/user_model.dart';

class StudyRoomScreen extends StatefulWidget {
  final String roomCode;
  final bool isHost;

  const StudyRoomScreen({
    super.key,
    required this.roomCode,
    required this.isHost,
  });

  @override
  State<StudyRoomScreen> createState() => _StudyRoomScreenState();
}

class _StudyRoomScreenState extends State<StudyRoomScreen> {
  final DatabaseService _db = DatabaseService();
  late ConfettiController _confettiController;
  late Stream<StudyRoomModel?> _roomStream;
  Timer? _ticker;
  Duration _remaining = Duration.zero;
  bool _dialogShown = false;

  int _selectedDuration = 1500; // 25 mins
  String _selectedType = 'focus';

  @override
  void initState() {
    super.initState();
    _roomStream = _db.getStudyRoom(widget.roomCode);
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    setState(() {}); // trigger rebuild to recalculate diff in build
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _handleSessionEnd(StudyRoomModel room, ThemeProvider theme) {
    if (_dialogShown) return;
    _dialogShown = true;
    _confettiController.play();
    
    final names = room.members.map((m) => m.name).join(' و ');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: theme.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'أحسنتم! انتهت الجلسة 🎉',
              style: GoogleFonts.cairo(color: theme.primaryText, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            content: Text(
              '$names أكملوا جلسة تركيز بنجاح!',
              style: GoogleFonts.cairo(color: theme.textSecondary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _db.leaveRoom(widget.roomCode, context.read<AuthService>().currentUser?.uid ?? '');
                  if (mounted) Navigator.pop(context); // close screen
                },
                child: Text('إنهاء 👋', style: GoogleFonts.cairo(color: Colors.redAccent)),
              ),
              if (widget.isHost)
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    _dialogShown = false;
                    await _db.resetSession(widget.roomCode);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.accentOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('جلسة جديدة 🔄', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        );
      }
    );
  }

  void _leaveRoom(String uid) async {
    await _db.leaveRoom(widget.roomCode, uid);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.uid ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Stack(
          children: [
            SafeArea(
              child: StreamBuilder<StudyRoomModel?>(
                stream: _roomStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final room = snapshot.data;
                  if (room == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 60, color: theme.textSecondary),
                          const SizedBox(height: 16),
                          Text('الغرفة غير موجودة أو تم إغلاقها', style: GoogleFonts.cairo(color: theme.primaryText, fontSize: 18)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(backgroundColor: theme.card),
                            child: Text('عودة', style: GoogleFonts.cairo(color: Colors.white)),
                          )
                        ],
                      ),
                    );
                  }

                  // Timer Logic
                  double progress = 0.0;
                  String timeDisplay = '00:00';
                  
                  if (room.status == 'studying' && room.timerStartedAt != null) {
                    final elapsed = DateTime.now().difference(room.timerStartedAt!.toDate());
                    final remaining = Duration(seconds: room.timerDuration) - elapsed;
                    
                    if (remaining.inSeconds <= 0) {
                      // Session ended
                      if (widget.isHost && room.status != 'ended') {
                        _db.endSession(widget.roomCode); // triggers end state for everyone
                      }
                    } else {
                      final mins = remaining.inMinutes.toString().padLeft(2, '0');
                      final secs = (remaining.inSeconds % 60).toString().padLeft(2, '0');
                      timeDisplay = '$mins:$secs';
                      progress = 1.0 - (elapsed.inSeconds / room.timerDuration);
                    }
                  } else if (room.status == 'waiting') {
                    final mins = (room.timerDuration ~/ 60).toString().padLeft(2, '0');
                    final secs = (room.timerDuration % 60).toString().padLeft(2, '0');
                    timeDisplay = '$mins:$secs';
                    progress = 1.0;
                    _dialogShown = false; // reset flag
                  } else if (room.status == 'ended') {
                    timeDisplay = '00:00';
                    progress = 0.0;
                    WidgetsBinding.instance.addPostFrameCallback((_) => _handleSessionEnd(room, theme));
                  }

                  return Column(
                    children: [
                      // Header & Leave button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                              tooltip: 'مغادرة الغرفة',
                              onPressed: () => _leaveRoom(uid),
                            ),
                            Text(
                              'غرفة الدراسة 📚',
                              style: GoogleFonts.cairo(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 40), // dummy spacer for symmetry
                          ],
                        ),
                      ),
                      
                      // Room Code
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'كود الغرفة:',
                              style: GoogleFonts.cairo(color: theme.textSecondary, fontSize: 16),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '# ${room.roomCode}',
                              style: GoogleFonts.tajawal(
                                color: const Color(0xFFFF6A00),
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                                shadows: [Shadow(color: const Color(0xFFFF6A00).withOpacity(0.5), blurRadius: 10)],
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.copy, color: Colors.white54),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: room.roomCode));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الكود')));
                              },
                            )
                          ],
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Members
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildMember(room.members.isNotEmpty ? room.members[0] : null, theme),
                            if (room.members.length > 1)
                              _buildMember(room.members[1], theme)
                            else
                              _buildEmptySeat(theme, room.roomCode),
                          ],
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Status / Timer Card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(24),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Column(
                          children: [
                            if (room.status == 'waiting') ...[
                              Text(
                                room.members.length == 2 ? 'الجميع جاهز! ابدأ الجلسة' : 'في انتظار انضمام الجميع...',
                                style: GoogleFonts.cairo(color: Colors.white70, fontSize: 16),
                              ),
                            ] else if (room.status == 'studying') ...[
                              Text(
                                timeDisplay,
                                style: GoogleFonts.tajawal(
                                  color: Colors.white,
                                  fontSize: 64,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4,
                                  shadows: [Shadow(color: const Color(0xFFFF6A00).withOpacity(0.8), blurRadius: 20)],
                                ),
                              ),
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progress.clamp(0.0, 1.0),
                                  backgroundColor: Colors.white12,
                                  color: const Color(0xFFFF6A00),
                                  minHeight: 8,
                                ),
                              )
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Controls
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: widget.isHost && room.status == 'waiting'
                            ? _buildHostControls(room, theme)
                            : !widget.isHost && room.status == 'waiting'
                                ? Text(
                                    'في انتظار ${room.hostName} ليبدأ...',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.cairo(color: theme.accentOrange, fontSize: 16, fontWeight: FontWeight.bold),
                                  )
                                : widget.isHost && room.status == 'studying'
                                    ? ElevatedButton(
                                        onPressed: () => _db.endSession(room.roomCode),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                          minimumSize: const Size(double.infinity, 56),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                        child: Text('إنهاء الجلسة', style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                      )
                                    : const SizedBox.shrink(),
                      ),
                      
                      const SizedBox(height: 32),
                    ],
                  );
                },
              ),
            ),
            
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHostControls(StudyRoomModel room, ThemeProvider theme) {
    return Column(
      children: [
        Row(
          children: [
            _buildTypeOption('تركيز 🧠\n25 د', 1500, 'focus', theme),
            const SizedBox(width: 8),
            _buildTypeOption('طويل ⚡\n45 د', 2700, 'focus', theme),
            const SizedBox(width: 8),
            _buildTypeOption('استراحة ☕\n5 د', 300, 'break', theme),
          ],
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: room.members.length == 2
              ? () {
                  _db.startTimer(room.roomCode, _selectedDuration, _selectedType);
                }
              : null, // Disabled if not 2 members
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6A00),
            disabledBackgroundColor: Colors.grey.withOpacity(0.3),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            shadowColor: const Color(0xFFFF6A00).withOpacity(0.5),
          ),
          child: Text('ابدأ الجلسة 🚀', style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildTypeOption(String title, int duration, String type, ThemeProvider theme) {
    final isSelected = _selectedDuration == duration;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedDuration = duration;
            _selectedType = type;
          });
          // Also update the room's display timer duration continuously without starting the session.
          _db.updateRoomSettings(widget.roomCode, duration, type);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF6A00).withOpacity(0.15) : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? const Color(0xFFFF6A00) : Colors.transparent),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: isSelected ? const Color(0xFFFF6A00) : Colors.white54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMember(StudyRoomMemberModel? member, ThemeProvider theme) {
    if (member == null) return const SizedBox.shrink();
    
    final auth = context.read<AuthService>();
    final isMe = member.userId == auth.currentUser?.uid;
    final isReady = member.isReady;

    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isReady ? Colors.greenAccent : Colors.grey,
              width: 3,
            ),
            boxShadow: isReady ? [BoxShadow(color: Colors.greenAccent.withOpacity(0.4), blurRadius: 15)] : [],
          ),
          child: const Padding(
            padding: EdgeInsets.all(4.0),
            child: CircleAvatar(
              backgroundColor: Colors.white10,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(member.name, style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        if (!widget.isHost && isMe) // let member click to ready
          GestureDetector(
            onTap: () => _db.toggleMemberReadyStatus(widget.roomCode, member.userId),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isReady ? Colors.green.withOpacity(0.2) : theme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isReady ? Colors.greenAccent : Colors.grey),
              ),
              child: Text(isReady ? 'جاهز ✅' : 'انقر للجاهزية', style: GoogleFonts.cairo(color: isReady ? Colors.greenAccent : Colors.grey, fontSize: 12)),
            )
          )
        else 
          Text(isReady ? 'جاهز ✅' : 'في الانتظار ⏳', style: GoogleFonts.cairo(color: isReady ? Colors.greenAccent : Colors.grey, fontSize: 14)),
      ],
    );
  }

  Widget _buildEmptySeat(ThemeProvider theme, String code) {
    return Column(
      children: [
        DottedBorder(
          color: Colors.grey.withOpacity(0.5),
          strokeWidth: 2,
          dashPattern: const [8, 4],
          borderType: BorderType.Circle,
          child: Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Icon(Icons.person_add, size: 40, color: Colors.grey.withOpacity(0.5)),
          ),
        ),
        const SizedBox(height: 12),
        Text('في انتظار صديقك...', style: GoogleFonts.cairo(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 4),
        Text('كود الغرفة: $code', style: GoogleFonts.tajawal(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
