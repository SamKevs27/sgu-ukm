import 'package:campus_club/models/attendance_model.dart';
import 'package:campus_club/models/feed_model.dart';
import 'package:campus_club/models/meeting_model.dart';
import 'package:campus_club/services/meeting_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_club/models/comment_model.dart';
import 'package:campus_club/providers/auth_provider.dart';

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

final feedIsLikedProvider = StreamProvider.family<bool, String>((ref, feedId) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return Stream.value(false);
  return ref.watch(meetingServiceProvider).watchIsLiked(
        feedId: feedId,
        userId: user.uid,
      );
});

final feedCommentsProvider = StreamProvider.family<List<CommentModel>, String>((ref, feedId) {
  return ref.watch(meetingServiceProvider).watchComments(feedId);
});