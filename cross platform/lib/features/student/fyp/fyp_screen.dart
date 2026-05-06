// lib/features/student/fyp/fyp_screen.dart
// lib/features/student/fyp/fyp_screen.dart
import 'package:campus_club/models/feed_model.dart';
import 'package:campus_club/providers/meeting_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class FypScreen extends ConsumerWidget {
  const FypScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: feedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_outlined,
                      size: 80, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('Nothing here yet.',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Clubs will post their meeting highlights here.',
                    style: TextStyle(color: theme.colorScheme.outline),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd MMM yyyy');
    final item = widget.item;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: item.clubLogoUrl != null
                      ? NetworkImage(item.clubLogoUrl!)
                      : null,
                  child: item.clubLogoUrl == null
                      ? Text(
                          item.clubName[0].toUpperCase(),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.clubName,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        fmt.format(item.createdAt),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_rounded,
                          size: 13,
                          color: theme.colorScheme.onSecondaryContainer),
                      const SizedBox(width: 4),
                      Text('Meeting',
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Photo carousel (if photos exist) ──
          if (item.photoUrls.isNotEmpty) _PhotoCarousel(urls: item.photoUrls),

          // ── Description ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: Text(
                  item.description,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                secondChild: Text(
                  item.description,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          ),

          // ── "See more" toggle ──
          if (item.description.length > 120)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: TextButton(
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4)),
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded ? 'See less' : 'See more',
                    style: const TextStyle(fontSize: 13)),
              ),
            ),

          const SizedBox(height: 10),
        ],
      ),
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

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => Image.network(
              widget.urls[i],
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                color: theme.colorScheme.surfaceVariant,
                child: const Center(
                  child: Icon(Icons.broken_image_outlined, size: 40),
                ),
              ),
            ),
          ),
        ),
        // Dots indicator (only if >1 photo)
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
        // Photo count badge
        if (widget.urls.length > 1)
          Positioned(
            top: 10,
            right: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_page + 1} / ${widget.urls.length}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
      ],
    );
  }
}