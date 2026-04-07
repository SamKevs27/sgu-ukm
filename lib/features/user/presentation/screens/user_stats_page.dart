import 'package:flutter/material.dart';

import '../../../../state/app_state.dart';

class UserStatsPage extends StatefulWidget {
  const UserStatsPage({super.key, required this.username});

  final String username;

  @override
  State<UserStatsPage> createState() => _UserStatsPageState();
}

class _UserStatsPageState extends State<UserStatsPage> {
  late final PageController _certificateController;
  int _activeCertificateIndex = 0;

  @override
  void initState() {
    super.initState();
    _certificateController = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _certificateController.dispose();
    super.dispose();
  }

  List<_CertificateData> _buildCertificates(AppState app) {
    final items = <_CertificateData>[];
    for (final stat in app.userStats) {
      for (var i = 0; i < stat.certificates; i++) {
        items.add(
          _CertificateData(
            clubName: app.clubName(stat.clubId),
            content: i.isEven ? 'Participation of International Competition' : '1st Winner of PIC Competition',
            color: i.isEven ? const Color(0xFFE4F0FF) : const Color(0xFFFFEEE5),
          ),
        );
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return AnimatedBuilder(
      animation: app,
      builder: (context, _) {
        final myStats = app.userStats;
        final certificates = _buildCertificates(app);
        final certificateCount = certificates.length;

        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 96 + bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Color(0xFFBFE4FF),
                    child: Icon(Icons.person, size: 30, color: Color(0xFF0A2C82)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello!', style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          widget.username,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications, size: 30, color: Color(0xFF20253A)),
                      Positioned(
                        right: -1,
                        top: -1,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(color: Color(0xFF2454D5), shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF113A9C), Color(0xFF2258D6)]),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Student ID: 12202009', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
                    SizedBox(height: 6),
                    Text('Major: Information Technology', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
                    SizedBox(height: 6),
                    Text('Batch: 2022', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: 'Certificates', count: certificateCount),
              const SizedBox(height: 12),
              if (certificates.isEmpty)
                const Card(child: ListTile(title: Text('No certificates yet.')))
              else ...[
                SizedBox(
                  height: 170,
                  child: PageView.builder(
                    controller: _certificateController,
                    itemCount: certificates.length,
                    onPageChanged: (index) => setState(() => _activeCertificateIndex = index),
                    itemBuilder: (context, index) {
                      final item = certificates[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _CertificateCard(
                          clubName: item.clubName,
                          content: item.content,
                          color: item.color,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    certificates.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: index == _activeCertificateIndex ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: index == _activeCertificateIndex ? const Color(0xFF2454D5) : const Color(0xFFCBD6F2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _SectionTitle(title: 'Attendance', count: myStats.length),
              const SizedBox(height: 12),
              if (myStats.isEmpty)
                const Card(child: ListTile(title: Text('No attendance records yet.')))
              else
                ...myStats.map((stat) {
                  final attended = ((stat.attendance / 10).round()).clamp(0, 10);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AttendanceTile(
                      clubName: app.clubName(stat.clubId),
                      attended: attended,
                      total: 10,
                      percent: attended / 10,
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(width: 10),
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(color: Color(0xFFE6E4FF), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(count.toString(), style: const TextStyle(color: Color(0xFF5B4ED9), fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({required this.clubName, required this.content, required this.color});

  final String clubName;
  final String content;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(clubName, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: const Color(0xFF65708E)))),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: Colors.pink.shade100, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.work_outline, color: Colors.pink),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            content,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  const _AttendanceTile({required this.clubName, required this.attended, required this.total, required this.percent});

  final String clubName;
  final int attended;
  final int total;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x110B2456), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: const Color(0xFFFFDCEC), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.work_outline, color: Color(0xFFE96DB2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(clubName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('$total Meetings - $attended Attended', style: const TextStyle(color: Color(0xFF6B6C82), fontSize: 16)),
              ],
            ),
          ),
          _ProgressRing(value: percent),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final safe = value.clamp(0.0, 1.0);
    return SizedBox(
      width: 68,
      height: 68,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: 1,
            strokeWidth: 6,
            valueColor: const AlwaysStoppedAnimation(Color(0xFFE6EAF5)),
          ),
          CircularProgressIndicator(
            value: safe,
            strokeWidth: 6,
            strokeCap: StrokeCap.round,
            valueColor: const AlwaysStoppedAnimation(Color(0xFF2454D5)),
          ),
          Center(
            child: Text(
              '${(safe * 100).round()}%',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificateData {
  const _CertificateData({required this.clubName, required this.content, required this.color});

  final String clubName;
  final String content;
  final Color color;
}
