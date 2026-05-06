import 'package:campus_club/models/cycle_model.dart';
import 'package:campus_club/services/cycle_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cycleServiceProvider = Provider<CycleService>((ref) => CycleService());

final activeCycleProvider = StreamProvider<CycleModel?>((ref) {
  return ref.watch(cycleServiceProvider).watchActiveCycle();
});

final allCyclesProvider = StreamProvider<List<CycleModel>>((ref) {
  return ref.watch(cycleServiceProvider).watchAllCycles();
});