import 'package:campus_club/models/club_model.dart';
import 'package:campus_club/models/club_request_model.dart';
import 'package:campus_club/models/member_model.dart';
import 'package:campus_club/providers/auth_provider.dart';
import 'package:campus_club/services/club_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final clubServiceProvider = Provider<ClubService>((ref) => ClubService());

/// All active clubs
final activeClubsProvider = StreamProvider<List<ClubModel>>((ref) {
  return ref.watch(clubServiceProvider).watchActiveClubs();
});

/// My member clubs
final myMemberClubsProvider = StreamProvider<List<ClubModel>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(clubServiceProvider).watchMyMemberClubs(user.uid);
});

/// My BoD clubs
final myBodClubsProvider = StreamProvider<List<ClubModel>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(clubServiceProvider).watchMyBodClubs(user.uid);
});

/// All clubs (BEM)
final allClubsProvider = StreamProvider<List<ClubModel>>((ref) {
  return ref.watch(clubServiceProvider).watchAllClubs();
});

/// Members of a specific club
final clubMembersProvider =
    StreamProvider.family<List<MemberModel>, String>((ref, clubId) {
  return ref.watch(clubServiceProvider).watchClubMembers(clubId);
});

/// Pending requests (BEM)
final pendingRequestsProvider =
    StreamProvider<List<ClubRequestModel>>((ref) {
  return ref.watch(clubServiceProvider).watchPendingRequests();
});