import 'package:flutter/material.dart';

import '../../../../models/app_models.dart';

class RequestStatusChip extends StatelessWidget {
  const RequestStatusChip({super.key, required this.status});

  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case ApplicationStatus.pending:
        return const Chip(
          label: Text('Pending'),
          backgroundColor: Color(0xFFE8EEFF),
          labelStyle: TextStyle(color: Color(0xFF355DBF), fontWeight: FontWeight.w700),
        );
      case ApplicationStatus.approved:
        return const Chip(
          label: Text('Approved'),
          backgroundColor: Color(0xFFE6F8EE),
          labelStyle: TextStyle(color: Color(0xFF1C9A61), fontWeight: FontWeight.w700),
        );
      case ApplicationStatus.rejected:
        return const Chip(
          label: Text('Rejected'),
          backgroundColor: Color(0xFFFFE9EE),
          labelStyle: TextStyle(color: Color(0xFFD53E63), fontWeight: FontWeight.w700),
        );
    }
  }
}
