import 'package:campus_club/models/attendance_model.dart';
import 'package:campus_club/models/feed_model.dart';
import 'package:campus_club/models/meeting_model.dart';
import 'package:campus_club/services/meeting_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final meetingServiceProvider =
    Provider<MeetingService>((ref) => MeetingService());

final clubMeetingsProvider =
    StreamProvider.family<List<MeetingModel>, String>((ref, clubId) {
  return ref.watch(meetingServiceProvider).watchClubMeetings(clubId);
});

final meetingAttendanceProvider =
    StreamProvider.family<List<AttendanceModel>, ({String clubId, String meetingId})>(
        (ref, args) {
  return ref
      .watch(meetingServiceProvider)
      .watchMeetingAttendance(args.clubId, args.meetingId);
});

final feedProvider = StreamProvider<List<FeedModel>>((ref) {
  return ref.watch(meetingServiceProvider).watchFeed();
});