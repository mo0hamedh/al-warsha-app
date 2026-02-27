import 'package:cloud_firestore/cloud_firestore.dart';

class StudyRoomMemberModel {
  final String userId;
  final String name;
  final Timestamp joinedAt;
  final bool isReady;

  StudyRoomMemberModel({
    required this.userId,
    required this.name,
    required this.joinedAt,
    this.isReady = false,
  });

  factory StudyRoomMemberModel.fromMap(Map<String, dynamic> data) {
    return StudyRoomMemberModel(
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      joinedAt: data['joinedAt'] ?? Timestamp.now(),
      isReady: data['isReady'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'joinedAt': joinedAt,
      'isReady': isReady,
    };
  }
}

class StudyRoomModel {
  final String id;
  final String hostId;
  final String hostName;
  final String roomCode;
  final String status; // 'waiting', 'studying', 'break', 'ended'
  final String sessionType; // 'focus', 'break'
  final int timerDuration; // in seconds
  final Timestamp? timerStartedAt;
  final List<StudyRoomMemberModel> members;
  final int maxMembers;
  final Timestamp createdAt;

  StudyRoomModel({
    required this.id,
    required this.hostId,
    required this.hostName,
    required this.roomCode,
    required this.status,
    required this.sessionType,
    required this.timerDuration,
    this.timerStartedAt,
    required this.members,
    this.maxMembers = 2,
    required this.createdAt,
  });

  factory StudyRoomModel.fromMap(Map<String, dynamic> data, String documentId) {
    var membersData = data['members'] as List<dynamic>? ?? [];
    List<StudyRoomMemberModel> parsedMembers =
        membersData.map((m) => StudyRoomMemberModel.fromMap(m)).toList();

    return StudyRoomModel(
      id: documentId,
      hostId: data['hostId'] ?? '',
      hostName: data['hostName'] ?? '',
      roomCode: data['roomCode'] ?? '',
      status: data['status'] ?? 'waiting',
      sessionType: data['sessionType'] ?? 'focus',
      timerDuration: data['timerDuration'] ?? 1500, // default 25 mins
      timerStartedAt: data['timerStartedAt'],
      members: parsedMembers,
      maxMembers: data['maxMembers'] ?? 2,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hostId': hostId,
      'hostName': hostName,
      'roomCode': roomCode,
      'status': status,
      'sessionType': sessionType,
      'timerDuration': timerDuration,
      'timerStartedAt': timerStartedAt,
      'members': members.map((m) => m.toMap()).toList(),
      'maxMembers': maxMembers,
      'createdAt': createdAt,
    };
  }
}
