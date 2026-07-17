// lib/models/cycle_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class CycleModel extends Equatable {
  final String cycleId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;

  const CycleModel({
    required this.cycleId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
  });

  bool get isExpired => DateTime.now().isAfter(endDate);

  factory CycleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CycleModel(
      cycleId: doc.id,
      name: data['name'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? false,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'isActive': isActive,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  CycleModel copyWith({bool? isActive}) => CycleModel(
        cycleId: cycleId,
        name: name,
        startDate: startDate,
        endDate: endDate,
        isActive: isActive ?? this.isActive,
        createdBy: createdBy,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [cycleId, name, startDate, endDate, isActive];
}