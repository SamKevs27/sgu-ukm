import 'package:campus_club/models/club_model.dart';
import 'package:campus_club/providers/auth_provider.dart';
import 'package:campus_club/providers/cycle_provider.dart';
import 'package:campus_club/providers/meeting_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateMeetingScreen extends ConsumerStatefulWidget {
  final ClubModel club;
  const CreateMeetingScreen({super.key, required this.club});

  @override
  ConsumerState<CreateMeetingScreen> createState() =>
      _CreateMeetingScreenState();
}

class _CreateMeetingScreenState
    extends ConsumerState<CreateMeetingScreen> {
  final _titleController = TextEditingController();
  int _qrMinutes = 30;
  bool _loading = false;
  String? _error;

  Future<void> _create() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a meeting title.');
      return;
    }

    final user = ref.read(currentUserProvider).valueOrNull;
    final cycle = ref.read(activeCycleProvider).valueOrNull;

    if (user == null || cycle == null) {
      setState(() => _error = 'Missing user or cycle info.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      await ref.read(meetingServiceProvider).createMeeting(
            clubId: widget.club.clubId,
            cycleId: cycle.cycleId,
            title: _titleController.text.trim(),
            createdBy: user.uid,
            qrValidMinutes: _qrMinutes,
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('New Meeting')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Meeting Title *',
                prefixIcon: Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: 24),
            Text('QR Code Valid For',
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 15, label: Text('15 min')),
                ButtonSegment(value: 30, label: Text('30 min')),
                ButtonSegment(value: 60, label: Text('1 hour')),
                ButtonSegment(value: 120, label: Text('2 hours')),
              ],
              selected: {_qrMinutes},
              onSelectionChanged: (s) =>
                  setState(() => _qrMinutes = s.first),
            ),
            const SizedBox(height: 8),
            Text(
              'A QR code will be generated automatically when the meeting is created.',
              style: TextStyle(
                  fontSize: 12, color: theme.colorScheme.outline),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!,
                  style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loading ? null : _create,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.rocket_launch_rounded),
              label: const Text('Create Meeting & Generate QR'),
            ),
          ],
        ),
      ),
    );
  }
}