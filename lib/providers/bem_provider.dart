// lib/providers/bem_provider.dart
import 'package:campus_club/models/club_model.dart';
import 'package:campus_club/models/club_request_model.dart';
import 'package:campus_club/services/bem_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bemServiceProvider = Provider<BemService>((ref) => BemService());

/// Stream of ALL club requests (pending + reviewed), sorted newest first.
final allClubRequestsProvider =
    StreamProvider<List<ClubRequestModel>>((ref) {
  return ref.watch(bemServiceProvider).watchAllRequests();
});

/// Stream of ALL clubs (for BEM clubs screen).
final allClubsProvider = StreamProvider<List<ClubModel>>((ref) {
  return ref.watch(bemServiceProvider).watchAllClubs();
});

/// Fetches a single club by ID — used in the requests card to show club info.
final clubByIdProvider =
    FutureProvider.family<ClubModel?, String>((ref, clubId) {
  return ref.watch(bemServiceProvider).fetchClub(clubId);
});