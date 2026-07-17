import 'package:campus_club/models/club_model.dart';
import 'package:campus_club/models/club_request_model.dart';
import 'package:campus_club/models/member_model.dart';
import 'package:campus_club/providers/auth_provider.dart';
import 'package:campus_club/providers/cycle_provider.dart';
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

/// Helper to get effective club status considering cycle status
/// If a club's cycle is inactive, the club should be displayed as inactive
ClubModel _getClubWithCycleStatus(
  ClubModel club,
  Map<String, bool> cycleActiveMap,
) {
  final isCycleActive = cycleActiveMap[club.cycleId] ?? true;

  // If cycle is inactive and club is active, mark it as expired
  if (!isCycleActive && club.status == ClubStatus.active) {
    return club.copyWith(status: ClubStatus.expired);
  }
  return club;
}

/// All clubs (BEM) with cycle status — marks clubs as inactive if their cycle is inactive
final allClubsWithCycleStatusProvider =
    StreamProvider<List<ClubModel>>((ref) {
  final clubService = ref.watch(clubServiceProvider);
  final cycleService = ref.watch(cycleServiceProvider);

  // Combine both streams
  return clubService.watchAllClubs().asyncMap((clubs) async {
    // Get the latest cycles data
    final cycles = await cycleService.watchAllCycles().first;

    // Create a map of cycleId -> isActive for quick lookup
    final cycleActiveMap = {for (final c in cycles) c.cycleId: c.isActive};

    // Update each club's status based on its cycle
    return clubs
        .map((club) => _getClubWithCycleStatus(club, cycleActiveMap))
        .toList();
  });
});

/// Active clubs for students with cycle status applied
final activeClubsWithCycleStatusProvider =
    StreamProvider<List<ClubModel>>((ref) {
  final clubService = ref.watch(clubServiceProvider);
  final cycleService = ref.watch(cycleServiceProvider);

  // Combine both streams
  return clubService.watchActiveClubs().asyncMap((clubs) async {
    // Get the latest cycles data
    final cycles = await cycleService.watchAllCycles().first;

    // Create a map of cycleId -> isActive for quick lookup
    final cycleActiveMap = {for (final c in cycles) c.cycleId: c.isActive};

    // Update each club's status based on its cycle
    return clubs
        .map((club) => _getClubWithCycleStatus(club, cycleActiveMap))
        .toList();
  });
});

/// My BoD clubs with cycle status applied
final myBodClubsWithCycleStatusProvider =
    StreamProvider<List<ClubModel>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return const Stream.empty();

  final clubService = ref.watch(clubServiceProvider);
  final cycleService = ref.watch(cycleServiceProvider);

  // Combine both streams
  return clubService.watchMyBodClubs(user.uid).asyncMap((clubs) async {
    // Get the latest cycles data
    final cycles = await cycleService.watchAllCycles().first;

    // Create a map of cycleId -> isActive for quick lookup
    final cycleActiveMap = {for (final c in cycles) c.cycleId: c.isActive};

    // Update each club's status based on its cycle
    return clubs
        .map((club) => _getClubWithCycleStatus(club, cycleActiveMap))
        .toList();
  });
});