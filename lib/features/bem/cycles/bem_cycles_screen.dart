// lib/features/bem/cycles/bem_cycles_screen.dart
import 'package:campus_club/models/cycle_model.dart';
import 'package:campus_club/providers/auth_provider.dart';
import 'package:campus_club/providers/cycle_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

const _screenBackground = Color(0xFFF4F6FA);
const _surfaceWhite = Color(0xFFFDFEFF);
const _primaryBlue = Color(0xFF3A78F2);
const _textNavy = Color(0xFF1A2647);
const _mutedBlue = Color(0xFF7B8FC2);
const _dividerBlue = Color(0xFFE3EAF6);

class BemCyclesScreen extends ConsumerWidget {
  const BemCyclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cyclesAsync = ref.watch(allCyclesProvider);
    final theme = Theme.of(context);
    const fabBottomOffset = 96.0;

    return Scaffold(
      backgroundColor: _screenBackground,
      body: cyclesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _primaryBlue)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cycles) {
          if (cycles.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month_outlined,
                      size: 80, color: _mutedBlue),
                  const SizedBox(height: 16),
                  Text(
                    'No cycles yet.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _textNavy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Create the first semester cycle to get started.',
                      style: const TextStyle(color: _mutedBlue),
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 126),
            itemCount: cycles.length,
            itemBuilder: (_, i) => _CycleCard(cycle: cycles[i]),
          );
        },
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: fabBottomOffset),
        child: FloatingActionButton.extended(
          onPressed: () => _showCreateDialog(context, ref),
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Cycle'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _screenBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CreateCycleSheet(),
    );
  }
}

class _CycleCard extends ConsumerWidget {
  final CycleModel cycle;
  const _CycleCard({required this.cycle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd MMM yyyy');
    final isExpired = cycle.isExpired;

    Color statusColor;
    String statusLabel;
    if (cycle.isActive && !isExpired) {
      statusColor = const Color(0xFF43AF61);
      statusLabel = 'Active';
    } else if (isExpired) {
      statusColor = const Color(0xFF9AA3B7);
      statusLabel = 'Expired';
    } else {
      statusColor = const Color(0xFFCF9627);
      statusLabel = 'Inactive';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surfaceWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _dividerBlue),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17396A).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(cycle.name,
                      style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800, color: _textNavy)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                    Border.all(color: statusColor.withValues(alpha: 0.35)),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.date_range_rounded,
                    size: 14, color: _mutedBlue),
                const SizedBox(width: 6),
                Text(
                  '${fmt.format(cycle.startDate)} – ${fmt.format(cycle.endDate)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: _mutedBlue, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            // Toggle active button (only if not expired)
            if (!isExpired) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cycle.isActive
                        ? const Color(0xFFE14D4D)
                        : _primaryBlue,
                    side: BorderSide(
                      color: cycle.isActive
                          ? const Color(0xFFE14D4D)
                          : _dividerBlue,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: () async {
                    try {
                      await ref
                          .read(cycleServiceProvider)
                          .setActiveCycle(
                            cycleId: cycle.cycleId,
                            activate: !cycle.isActive,
                          );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  icon: Icon(
                    cycle.isActive
                        ? Icons.pause_circle_outline_rounded
                        : Icons.play_circle_outline_rounded,
                    size: 18,
                  ),
                  label: Text(
                      cycle.isActive ? 'Deactivate' : 'Set as Active'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Create cycle bottom sheet ────────────────────────────────────────────────

class _CreateCycleSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CreateCycleSheet> createState() =>
      _CreateCycleSheetState();
}

class _CreateCycleSheetState extends ConsumerState<_CreateCycleSheet> {
  final _nameController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _loading = false;
  String? _error;

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? now : (_startDate ?? now),
      firstDate: isStart ? now.subtract(const Duration(days: 365)) : (_startDate ?? now),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Reset end date if it's before new start
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a cycle name.');
      return;
    }
    if (_startDate == null || _endDate == null) {
      setState(() => _error = 'Please select start and end dates.');
      return;
    }

    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(cycleServiceProvider).createCycle(
            name: _nameController.text.trim(),
            startDate: _startDate!,
            endDate: _endDate!,
            createdBy: user.uid,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');

    return Container(
      decoration: const BoxDecoration(
        color: _screenBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: _mutedBlue.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Text('New Semester Cycle',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800, color: _textNavy)),
            const SizedBox(height: 4),
            const Text(
              'Clubs created during this period will belong to this cycle.',
              style: TextStyle(color: _mutedBlue, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Cycle Name *',
                hintText: 'e.g. Even Semester 2026',
                prefixIcon: const Icon(Icons.label_rounded, color: _mutedBlue),
                filled: true,
                fillColor: _surfaceWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _dividerBlue),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _dividerBlue),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _DateTile(
                    label: 'Start Date *',
                    value: _startDate != null ? fmt.format(_startDate!) : null,
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateTile(
                    label: 'End Date *',
                    value: _endDate != null ? fmt.format(_endDate!) : null,
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Color(0xFFE14D4D)),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 46,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ))
                    : const Icon(Icons.rocket_launch_rounded),
                label: const Text('Create Cycle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;
  const _DateTile(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: _surfaceWhite,
          border: Border.all(color: _dividerBlue),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: _mutedBlue)),
            const SizedBox(height: 4),
            Text(
              value ?? 'Select',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: value != null ? _textNavy : _mutedBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}