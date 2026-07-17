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

// ── Shared design tokens (mirrors BEM dashboard) ─────────────────────────────
const _screenBackground = Color(0xFFFBFDFF);
const _softBlue         = Color(0xFFEAF4FF);
const _primaryBlue      = Color(0xFF2F80FF);
const _textNavy         = Color(0xFF101C3D);
const _mutedBlue        = Color(0xFF8093C6);
const _dividerBlue      = Color(0xFFE9EEF8);

// ── Glass card (identical to BEM dashboard's _GlassCard) ─────────────────────
class _GlassCard extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  final Color? borderColor;
  final EdgeInsetsGeometry? margin;

  const _GlassCard({
    required this.child,
    this.gradient,
    this.borderColor,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4A7A).withValues(alpha: 0.06),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: gradient == null ? Colors.white : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor ?? _dividerBlue, width: 1),
        ),
        child: child,
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _textNavy,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 13,
                color: _mutedBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Themed input decoration ───────────────────────────────────────────────────
InputDecoration _inputDecoration({
  required String label,
  required IconData icon,
  bool alignLabelWithHint = false,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: _mutedBlue, fontWeight: FontWeight.w500),
    prefixIcon: Icon(icon, color: _mutedBlue, size: 20),
    alignLabelWithHint: alignLabelWithHint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _dividerBlue),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _dividerBlue),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
    ),
  );
}

// ── Main screen ───────────────────────────────────────────────────────────────
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

  UserModel? _vicePick;
  UserModel? _treasurerPick;
  UserModel? _secretaryPick;

  final _days = [
    'Monday', 'Tuesday', 'Wednesday',
    'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _logoFile = File(picked.path));
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: _primaryBlue,
              ),
        ),
        child: child!,
      ),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _pickBodMember({
    required String role,
    required ValueChanged<UserModel?> onPicked,
    UserModel? current,
  }) async {
    final result = await showModalBottomSheet<UserModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserSearchSheet(
        role: role,
        excludeUids: _getExcludedUids(),
      ),
    );
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
        logoUrl = await StorageService()
            .uploadClubLogo(_logoFile!, const Uuid().v4());
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
          SnackBar(
            content: const Text('Club submitted! Waiting for BEM approval.'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
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
    final cycle = ref.watch(activeCycleProvider).valueOrNull;
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: _screenBackground,
      appBar: AppBar(
        backgroundColor: _screenBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const BackButton(color: _textNavy),
        title: const Text(
          'Create New Club',
          style: TextStyle(
            color: _textNavy,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Active cycle banner ──────────────────────────────────────
            if (cycle != null)
              _GlassCard(
                gradient: LinearGradient(
                  colors: [
                    _primaryBlue.withValues(alpha: 0.11),
                    _softBlue,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderColor: _primaryBlue.withValues(alpha: 0.2),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.calendar_month_rounded,
                            color: _primaryBlue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Registering for cycle',
                            style: TextStyle(
                              fontSize: 11,
                              color: _mutedBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cycle.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: _textNavy,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              _GlassCard(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withValues(alpha: 0.10),
                    Colors.orange.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderColor: Colors.red.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.warning_rounded,
                            color: Colors.red, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'No active cycle. BEM must create one first.',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 28),

            // ── Logo picker ──────────────────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: _pickLogo,
                child: _GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: _softBlue,
                              backgroundImage: _logoFile != null
                                  ? FileImage(_logoFile!)
                                  : null,
                              child: _logoFile == null
                                  ? const Icon(Icons.business_rounded,
                                      size: 36, color: _primaryBlue)
                                  : null,
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _primaryBlue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.add_a_photo_rounded,
                                  size: 13, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _logoFile == null
                              ? 'Upload Club Logo'
                              : 'Tap to change logo',
                          style: const TextStyle(
                            fontSize: 13,
                            color: _mutedBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Club info ────────────────────────────────────────────────
            const _SectionHeader(
              title: 'Club Details',
              subtitle: 'Basic information about your club',
            ),
            _GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(
                          color: _textNavy, fontWeight: FontWeight.w600),
                      decoration: _inputDecoration(
                        label: 'Club Name *',
                        icon: Icons.flag_rounded,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _descController,
                      maxLines: 3,
                      style: const TextStyle(color: _textNavy),
                      decoration: _inputDecoration(
                        label: 'Description *',
                        icon: Icons.description_rounded,
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _roomController,
                      style: const TextStyle(color: _textNavy),
                      decoration: _inputDecoration(
                        label: 'Room Number *',
                        icon: Icons.room_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Meeting schedule ─────────────────────────────────────────
            const _SectionHeader(
              title: 'Meeting Schedule',
              subtitle: 'When and where does your club meet?',
            ),
            _GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Day dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedDay,
                      style: const TextStyle(
                          color: _textNavy, fontWeight: FontWeight.w600),
                      dropdownColor: Colors.white,
                      decoration: _inputDecoration(
                        label: 'Meeting Day *',
                        icon: Icons.calendar_today_rounded,
                      ),
                      items: _days
                          .map((d) =>
                              DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedDay = v),
                    ),
                    const SizedBox(height: 14),
                    // Time picker tile
                    GestureDetector(
                      onTap: _pickTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _selectedTime != null
                                ? _primaryBlue.withValues(alpha: 0.5)
                                : _dividerBlue,
                            width: _selectedTime != null ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                color: _mutedBlue, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedTime == null
                                    ? 'Select Meeting Time *'
                                    : _selectedTime!.format(context),
                                style: TextStyle(
                                  color: _selectedTime == null
                                      ? _mutedBlue
                                      : _textNavy,
                                  fontWeight: _selectedTime == null
                                      ? FontWeight.w500
                                      : FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: _selectedTime != null
                                  ? _primaryBlue
                                  : _mutedBlue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Board of Directors ───────────────────────────────────────
            const _SectionHeader(
              title: 'Board of Directors',
              subtitle: 'Assigned members will see this club in their "My BoD" page.',
            ),
            _GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _BodTile(
                      roleLabel: 'Head',
                      user: currentUser,
                      isFixed: true,
                      onTap: null,
                      onClear: null,
                    ),
                    _BodDivider(),
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
                    _BodDivider(),
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
                    _BodDivider(),
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
                  ],
                ),
              ),
            ),

            // ── Error message ────────────────────────────────────────────
            if (_error != null) ...[
              const SizedBox(height: 16),
              _GlassCard(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withValues(alpha: 0.08),
                    Colors.red.withValues(alpha: 0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderColor: Colors.red.withValues(alpha: 0.25),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.red, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),

            // ── Submit button ────────────────────────────────────────────
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: (_loading || cycle == null) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  disabledBackgroundColor:
                      _primaryBlue.withValues(alpha: 0.4),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Submit for Approval',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Divider between BoD rows ──────────────────────────────────────────────────
class _BodDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: _dividerBlue, thickness: 1);
  }
}

// ── BoD tile (inside card, no own border) ────────────────────────────────────
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
    final assigned = user != null;

    return InkWell(
      onTap: isFixed ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor:
                  assigned ? _softBlue : _dividerBlue,
              child: assigned
                  ? Text(
                      user!.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _primaryBlue,
                        fontSize: 14,
                      ),
                    )
                  : const Icon(Icons.person_add_rounded,
                      size: 16, color: _mutedBlue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roleLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _mutedBlue,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    assigned ? user!.name : 'Tap to assign',
                    style: TextStyle(
                      fontWeight: assigned
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: assigned ? _textNavy : _mutedBlue,
                      fontSize: 14,
                    ),
                  ),
                  if (assigned)
                    Text(
                      user!.email,
                      style: const TextStyle(
                          fontSize: 11, color: _mutedBlue),
                    ),
                ],
              ),
            ),
            if (isFixed)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: _primaryBlue.withValues(alpha: 0.2)),
                ),
                child: const Text(
                  'You',
                  style: TextStyle(
                    color: _primaryBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else if (!isFixed && assigned)
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    size: 16, color: _mutedBlue),
                onPressed: onClear,
                visualDensity: VisualDensity.compact,
              )
            else
              const Icon(Icons.chevron_right_rounded, color: _mutedBlue),
          ],
        ),
      ),
    );
  }
}

// ── User search bottom sheet ──────────────────────────────────────────────────
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
      final filtered =
          results.where((u) => !widget.excludeUids.contains(u.uid)).toList();
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
    return Container(
      decoration: const BoxDecoration(
        color: _screenBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: _dividerBlue,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),

          Text(
            'Assign ${widget.role}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _textNavy,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Search by name or email (@student.sgu.ac.id)',
            style: TextStyle(color: _mutedBlue, fontSize: 13),
          ),
          const SizedBox(height: 18),

          TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(
                color: _textNavy, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'e.g. John or john@student.sgu.ac.id',
              hintStyle: const TextStyle(color: _mutedBlue),
              prefixIcon:
                  const Icon(Icons.search_rounded, color: _mutedBlue, size: 20),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _primaryBlue),
                      ),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _dividerBlue),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _dividerBlue),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: _primaryBlue, width: 1.5),
              ),
            ),
            onChanged: _search,
          ),

          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],

          const SizedBox(height: 12),

          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: _results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded,
                              size: 36, color: _mutedBlue),
                          const SizedBox(height: 8),
                          Text(
                            _searchController.text.length < 3
                                ? 'Type at least 3 characters to search'
                                : 'No students found',
                            style: const TextStyle(
                                color: _mutedBlue,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : _GlassCard(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _results.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: _dividerBlue),
                      itemBuilder: (_, i) {
                        final u = _results[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            backgroundColor: _softBlue,
                            child: Text(
                              u.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _primaryBlue,
                              ),
                            ),
                          ),
                          title: Text(
                            u.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _textNavy),
                          ),
                          subtitle: Text(u.email,
                              style: const TextStyle(
                                  color: _mutedBlue, fontSize: 12)),
                          trailing: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _primaryBlue.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add_rounded,
                                color: _primaryBlue, size: 18),
                          ),
                          onTap: () => Navigator.pop(context, u),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}