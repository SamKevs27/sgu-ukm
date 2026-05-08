import 'package:campus_club/providers/auth_provider.dart';
import 'package:campus_club/services/attendance_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final attendanceServiceProvider =
    Provider<AttendanceService>((ref) => AttendanceService());

// === Params classes ====

class AttendanceParams {
  final String clubId;
  final String cycleId;
  final String userId;

  const AttendanceParams({
    required this.clubId,
    required this.cycleId,
    required this.userId,
  });

  @override
  bool operator ==(Object other) =>
      other is AttendanceParams &&
      other.clubId == clubId &&
      other.cycleId == cycleId &&
      other.userId == userId;

  @override
  int get hashCode => Object.hash(clubId, cycleId, userId);
}

// === Providers =====

/// Attendance detail stream for a user in a club + cycle (real-time)
final attendanceDetailProvider =
    StreamProvider.family<List<Map<String, dynamic>>, AttendanceParams>(
        (ref, params) {
  return ref.watch(attendanceServiceProvider).watchAttendanceDetail(
        clubId: params.clubId,
        cycleId: params.cycleId,
        userId: params.userId,
      );
});

/// Full attendance data (percentage + meeting detail list) for a user in a club + cycle
final attendanceDataProvider =
    FutureProvider.family<Map<String, dynamic>, AttendanceParams>(
        (ref, params) {
  return ref.watch(attendanceServiceProvider).getAttendanceData(
        clubId: params.clubId,
        cycleId: params.cycleId,
        userId: params.userId,
      );
});

/// Convenience provider — attendance % only, for showing in My Club card
final attendancePercentageProvider =
    FutureProvider.family<double, AttendanceParams>((ref, params) async {
  final data = await ref.watch(attendanceDataProvider(params).future);
  return data['percentage'] as double;
});

/// Check if current user attended a specific meeting
final hasAttendedProvider =
    FutureProvider.family<bool, ({String clubId, String meetingId})>(
        (ref, params) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return Future.value(false);
  return ref.watch(attendanceServiceProvider).hasAttended(
        clubId: params.clubId,
        meetingId: params.meetingId,
        userId: user.uid,
      );
});