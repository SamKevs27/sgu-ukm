// lib/providers/cycle_provider.dart
import 'package:campus_club/models/cycle_model.dart';
import 'package:campus_club/services/cycle_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cycleServiceProvider = Provider<CycleService>((ref) => CycleService());

/// All cycles sorted newest first — used in BEM cycles screen.
final allCyclesProvider = StreamProvider<List<CycleModel>>((ref) {
  return ref.watch(cycleServiceProvider).watchAllCycles();
});

/// The currently active cycle — used when creating a club or meeting.
final activeCycleProvider = StreamProvider<CycleModel?>((ref) {
  return ref.watch(cycleServiceProvider).watchActiveCycle();
});