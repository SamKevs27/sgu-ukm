// lib/features/student/fyp/fyp_screen.dart
import 'package:campus_club/models/feed_model.dart';
import 'package:campus_club/providers/meeting_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class FypScreen extends ConsumerWidget {
  const FypScreen({super.key});

  static const _screenBackground = Color(0xFFFBFDFF);
  static const _textNavy = Color(0xFF101C3D);
  static const _mutedBlue = Color(0xFF8093C6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _screenBackground,
      body: feedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome_outlined,
                    size: 80,
                    color: _mutedBlue,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nothing here yet.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _textNavy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Clubs will post their meeting highlights here.',
                    style: TextStyle(
                      color: _mutedBlue,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
            itemCount: items.length,
            itemBuilder: (_, i) => _FeedCard(item: items[i]),
          );
        },
      ),
    );
  }
}

class _FeedCard extends StatefulWidget {
  final FeedModel item;
  const _FeedCard({required this.item});

  @override
  State<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<_FeedCard> {
  bool _expanded = false;

  static const _primaryBlue = Color(0xFF2F80FF);
  static const _textNavy = Color(0xFF101C3D);

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('dd MMM').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final hasLongDescription = item.description.length > 150;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4A7A).withValues(alpha: 0.05),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ClubAvatar(item: item),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FeedHeader(
                      item: item,
                      timeLabel: _timeAgo(item.createdAt),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: AnimatedCrossFade(
                        duration: const Duration(milliseconds: 180),
                        crossFadeState: _expanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: Text(
                          item.description,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: _textNavy,
                            fontWeight: FontWeight.w500,
                            height: 1.38,
                          ),
                        ),
                        secondChild: Text(
                          item.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: _textNavy,
                            fontWeight: FontWeight.w500,
                            height: 1.38,
                          ),
                        ),
                      ),
                    ),
                    if (hasLongDescription)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() => _expanded = !_expanded),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              _expanded ? 'See less' : 'See more',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _primaryBlue,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (item.photoUrls.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _PhotoCarousel(urls: item.photoUrls),
                    ],
                    const SizedBox(height: 14),
                    const _FeedActions(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClubAvatar extends StatelessWidget {
  final FeedModel item;

  const _ClubAvatar({required this.item});

  static const _softBlue = Color(0xFFEAF4FF);
  static const _primaryBlue = Color(0xFF2F80FF);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: _softBlue,
          backgroundImage: item.clubLogoUrl != null
              ? NetworkImage(item.clubLogoUrl!)
              : null,
          child: item.clubLogoUrl == null
              ? Text(
                  item.clubName[0].toUpperCase(),
                  style: const TextStyle(
                    color: _primaryBlue,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                )
              : null,
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 21,
            height: 21,
            decoration: BoxDecoration(
              color: _primaryBlue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 14),
          ),
        ),
      ],
    );
  }
}

class _FeedHeader extends StatelessWidget {
  final FeedModel item;
  final String timeLabel;

  const _FeedHeader({required this.item, required this.timeLabel});

  static const _primaryBlue = Color(0xFF2F80FF);
  static const _textNavy = Color(0xFF101C3D);
  static const _mutedBlue = Color(0xFF8093C6);
  static const _softBlue = Color(0xFFEAF4FF);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                item.clubName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _textNavy,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _softBlue,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_rounded, size: 12, color: _primaryBlue),
                    SizedBox(width: 4),
                    Text(
                      'Meeting',
                      style: TextStyle(
                        color: _primaryBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                timeLabel,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _mutedBlue,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // const Icon(Icons.auto_awesome_rounded, color: _primaryBlue, size: 21), // gtw ini buat apa lol
      ],
    );
  }
}

class _FeedActions extends StatelessWidget {
  const _FeedActions();

  static const _dividerBlue = Color(0xFFE9EEF8);

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _dividerBlue)),
      ),
      // child: Padding(
      //   padding: EdgeInsets.only(top: 12),
      //   child: Row(
      //     children: [
      //       _FeedActionIcon(icon: Icons.favorite_border_rounded),
      //       SizedBox(width: 26),
      //       _FeedActionIcon(icon: Icons.mode_comment_outlined, label: '0'),
      //       SizedBox(width: 26),
      //       _FeedActionIcon(icon: Icons.repeat_rounded),
      //       SizedBox(width: 26),
      //       _FeedActionIcon(icon: Icons.send_outlined),
      //     ],
      //   ),
      // ),
    );
  }
}

class _FeedActionIcon extends StatelessWidget {
  final IconData icon;
  final String? label;

  const _FeedActionIcon({required this.icon, this.label});

  static const _mutedBlue = Color(0xFF8093C6);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: _mutedBlue),
        if (label != null) ...[
          const SizedBox(width: 5),
          Text(
            label!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _mutedBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _PhotoCarousel extends StatefulWidget {
  final List<String> urls;
  const _PhotoCarousel({required this.urls});

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 1.16,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => Image.network(
                widget.urls[i],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined, size: 40),
                  ),
                ),
              ),
            ),
            if (widget.urls.length > 1)
              Positioned(
                bottom: 10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    widget.urls.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _page == i ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _page == i ? Colors.white : Colors.white54,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.urls.length > 1)
              Positioned(
                top: 10,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.52),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_page + 1} / ${widget.urls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
