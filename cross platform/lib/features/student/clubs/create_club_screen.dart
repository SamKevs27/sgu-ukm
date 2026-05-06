import 'dart:io';
import 'package:campus_club/models/club_model.dart';
import 'package:campus_club/providers/auth_provider.dart';
import 'package:campus_club/providers/club_provider.dart';
import 'package:campus_club/providers/cycle_provider.dart';
import 'package:campus_club/services/club_service.dart';
import 'package:campus_club/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class CreateClubScreen extends ConsumerStatefulWidget {
  const CreateClubScreen({super.key});

  @override
  ConsumerState<CreateClubScreen> createState() => _CreateClubScreenState();
}

class _CreateClubScreenState extends ConsumerState<CreateClubScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _roomController = TextEditingController();
  final _viceController = TextEditingController();
  final _treasurerController = TextEditingController();
  final _secretaryController = TextEditingController();

  String? _selectedDay;
  TimeOfDay? _selectedTime;
  File? _logoFile;
  bool _loading = false;
  String? _error;

  final _days = [
    'Monday', 'Tuesday', 'Wednesday',
    'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _logoFile = File(picked.path));
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final cycle = ref.read(activeCycleProvider).valueOrNull;

    if (_nameController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty ||
        _roomController.text.trim().isEmpty ||
        _selectedDay == null ||
        _selectedTime == null) {
      setState(() => _error = 'Please fill in all required fields.');
      return;
    }

    if (cycle == null) {
      setState(() => _error =
          'No active semester cycle. Please wait for BEM to create one.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      String? logoUrl;

      // Upload logo if selected
      if (_logoFile != null) {
        final tempId = const Uuid().v4();
        logoUrl = await StorageService()
            .uploadClubLogo(_logoFile!, tempId);
      }

      final bod = BodModel(
        headId: user!.uid,
        viceId: _viceController.text.trim().isEmpty
            ? null
            : _viceController.text.trim(),
        treasurerId: _treasurerController.text.trim().isEmpty
            ? null
            : _treasurerController.text.trim(),
        secretaryId: _secretaryController.text.trim().isEmpty
            ? null
            : _secretaryController.text.trim(),
      );

      await ref.read(clubServiceProvider).createClub(
            cycleId: cycle.cycleId,
            name: _nameController.text.trim(),
            description: _descController.text.trim(),
            meetingDay: _selectedDay!,
            meetingTime: _selectedTime!.format(context),
            roomNumber: _roomController.text.trim(),
            bod: bod,
            createdBy: user.uid,
            logoUrl: logoUrl,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '✅ Club submitted! Waiting for BEM approval.'),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cycle = ref.watch(activeCycleProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Create New Club')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Active cycle info
            if (cycle != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        color: theme.colorScheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Cycle: ${cycle.name}',
                      style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'No active cycle. BEM must create one first.',
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),

            const SizedBox(height: 24),

            // Logo picker
            Center(
              child: GestureDetector(
                onTap: _pickLogo,
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage:
                      _logoFile != null ? FileImage(_logoFile!) : null,
                  child: _logoFile == null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_a_photo_rounded,
                                color: theme.colorScheme.primary),
                            const SizedBox(height: 4),
                            Text('Logo',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.primary)),
                          ],
                        )
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Club info fields
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Club Name *',
                prefixIcon: Icon(Icons.flag_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description *',
                prefixIcon: Icon(Icons.description_rounded),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _roomController,
              decoration: const InputDecoration(
                labelText: 'Room Number *',
                prefixIcon: Icon(Icons.room_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // Meeting day
            DropdownButtonFormField<String>(
              value: _selectedDay,
              decoration: const InputDecoration(
                labelText: 'Meeting Day *',
                prefixIcon: Icon(Icons.calendar_today_rounded),
              ),
              items: _days
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedDay = v),
            ),
            const SizedBox(height: 16),

            // Meeting time
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outline),
              ),
              leading: const Icon(Icons.access_time_rounded),
              title: Text(_selectedTime == null
                  ? 'Select Meeting Time *'
                  : 'Meeting Time: ${_selectedTime!.format(context)}'),
              onTap: _pickTime,
            ),

            const SizedBox(height: 24),

            // BoD section
            Text('Board of Directors',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'You are the Head. Enter the User IDs of your BoD members.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _viceController,
              decoration: const InputDecoration(
                labelText: 'Vice Head (User ID)',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _treasurerController,
              decoration: const InputDecoration(
                labelText: 'Treasurer (User ID)',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _secretaryController,
              decoration: const InputDecoration(
                labelText: 'Secretary (User ID)',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!,
                  style: TextStyle(color: theme.colorScheme.error)),
            ],

            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: (_loading || cycle == null) ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: const Text('Submit for Approval'),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}