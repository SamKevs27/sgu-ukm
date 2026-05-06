// lib/features/student/clubs/create_club_screen.dart
import 'dart:io';
import 'package:campus_club/models/club_model.dart';
import 'package:campus_club/models/user_model.dart';
import 'package:campus_club/providers/auth_provider.dart';
import 'package:campus_club/providers/club_provider.dart';
import 'package:campus_club/providers/cycle_provider.dart';
import 'package:campus_club/services/auth_service.dart';
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

  String? _selectedDay;
  TimeOfDay? _selectedTime;
  File? _logoFile;
  bool _loading = false;
  String? _error;

  // BoD resolved users (null = not assigned)
  UserModel? _vicePick;
  UserModel? _treasurerPick;
  UserModel? _secretaryPick;

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

  /// Opens a bottom sheet to search for a user by email,
  /// then calls [onPicked] with the resolved UserModel.
  Future<void> _pickBodMember({
    required String role,
    required ValueChanged<UserModel?> onPicked,
    UserModel? current,
  }) async {
    final result = await showModalBottomSheet<UserModel?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _UserSearchSheet(
        role: role,
        excludeUids: _getExcludedUids(),
      ),
    );
    // result == null means sheet was dismissed without picking
    // result can also be a sentinel "clear" value — handled below
    if (!mounted) return;
    onPicked(result);
  }

  List<String> _getExcludedUids() {
    final self = ref.read(currentUserProvider).valueOrNull?.uid;
    return [
      if (self != null) self,
      if (_vicePick != null) _vicePick!.uid,
      if (_treasurerPick != null) _treasurerPick!.uid,
      if (_secretaryPick != null) _secretaryPick!.uid,
    ];
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

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      String? logoUrl;
      if (_logoFile != null) {
        logoUrl =
            await StorageService().uploadClubLogo(_logoFile!, const Uuid().v4());
      }

      final bod = BodModel(
        headId: user!.uid,
        viceId: _vicePick?.uid,
        treasurerId: _treasurerPick?.uid,
        secretaryId: _secretaryPick?.uid,
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
              content: Text('✅ Club submitted! Waiting for BEM approval.')),
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
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Create New Club')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Active cycle banner ──
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
                    Text('Cycle: ${cycle.name}',
                        style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600)),
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
                child: Text('No active cycle. BEM must create one first.',
                    style: TextStyle(
                        color: theme.colorScheme.onErrorContainer)),
              ),

            const SizedBox(height: 24),

            // ── Logo picker ──
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

            // ── Club info ──
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

            const SizedBox(height: 28),

            // ── Board of Directors ──
            Text('Board of Directors',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Assigned members will see this club in their "My BoD" page.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 16),

            // Head (always the current user, read-only)
            _BodTile(
              roleLabel: 'Head',
              user: currentUser,
              isFixed: true,
              onTap: null,
              onClear: null,
            ),
            const SizedBox(height: 10),

            _BodTile(
              roleLabel: 'Vice Head',
              user: _vicePick,
              onTap: () => _pickBodMember(
                role: 'Vice Head',
                onPicked: (u) => setState(() => _vicePick = u),
                current: _vicePick,
              ),
              onClear: _vicePick != null
                  ? () => setState(() => _vicePick = null)
                  : null,
            ),
            const SizedBox(height: 10),

            _BodTile(
              roleLabel: 'Treasurer',
              user: _treasurerPick,
              onTap: () => _pickBodMember(
                role: 'Treasurer',
                onPicked: (u) => setState(() => _treasurerPick = u),
                current: _treasurerPick,
              ),
              onClear: _treasurerPick != null
                  ? () => setState(() => _treasurerPick = null)
                  : null,
            ),
            const SizedBox(height: 10),

            _BodTile(
              roleLabel: 'Secretary',
              user: _secretaryPick,
              onTap: () => _pickBodMember(
                role: 'Secretary',
                onPicked: (u) => setState(() => _secretaryPick = u),
                current: _secretaryPick,
              ),
              onClear: _secretaryPick != null
                  ? () => setState(() => _secretaryPick = null)
                  : null,
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
                      child: CircularProgressIndicator(strokeWidth: 2))
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

// ── BoD tile widget ────────────────────────────────────────────────────────────

class _BodTile extends StatelessWidget {
  final String roleLabel;
  final UserModel? user;
  final bool isFixed;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  const _BodTile({
    required this.roleLabel,
    required this.user,
    this.isFixed = false,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assigned = user != null;

    return InkWell(
      onTap: isFixed ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: assigned
                ? theme.colorScheme.primary.withOpacity(0.5)
                : theme.colorScheme.outline.withOpacity(0.4),
          ),
          borderRadius: BorderRadius.circular(12),
          color: assigned
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: assigned
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceVariant,
              child: assigned
                  ? Text(user!.name[0].toUpperCase(),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer))
                  : Icon(Icons.person_add_rounded,
                      size: 18, color: theme.colorScheme.outline),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(roleLabel,
                      style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.outline,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    assigned ? user!.name : 'Tap to assign',
                    style: TextStyle(
                      fontWeight:
                          assigned ? FontWeight.w600 : FontWeight.normal,
                      color: assigned
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.outline,
                    ),
                  ),
                  if (assigned)
                    Text(user!.email,
                        style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.outline)),
                ],
              ),
            ),
            if (!isFixed && assigned)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: onClear,
                color: theme.colorScheme.outline,
              )
            else if (!isFixed && !assigned)
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }
}

// ── User search bottom sheet ───────────────────────────────────────────────────

class _UserSearchSheet extends StatefulWidget {
  final String role;
  final List<String> excludeUids;

  const _UserSearchSheet({required this.role, required this.excludeUids});

  @override
  State<_UserSearchSheet> createState() => _UserSearchSheetState();
}

class _UserSearchSheetState extends State<_UserSearchSheet> {
  final _searchController = TextEditingController();
  List<UserModel> _results = [];
  bool _searching = false;
  String? _error;

  Future<void> _search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.length < 3) {
      setState(() => _results = []);
      return;
    }

    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final results = await AuthService().searchStudents(q);
      // Filter out already-assigned uids and self
      final filtered = results
          .where((u) => !widget.excludeUids.contains(u.uid))
          .toList();
      if (mounted) setState(() => _results = filtered);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Assign ${widget.role}',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Search by name or email (@student.sgu.ac.id)',
              style: TextStyle(
                  color: theme.colorScheme.outline, fontSize: 13)),
          const SizedBox(height: 16),

          TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'e.g. John or john@student.sgu.ac.id',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            onChanged: _search,
          ),

          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],

          const SizedBox(height: 8),

          // Results list (constrained height)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: _results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _searchController.text.length < 3
                            ? 'Type at least 3 characters to search'
                            : 'No students found',
                        style:
                            TextStyle(color: theme.colorScheme.outline),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final u = _results[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.primaryContainer,
                          child: Text(u.name[0].toUpperCase(),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme
                                      .onPrimaryContainer)),
                        ),
                        title: Text(u.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(u.email),
                        trailing: const Icon(Icons.add_circle_rounded),
                        onTap: () => Navigator.pop(context, u),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}