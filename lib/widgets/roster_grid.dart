import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// One person on a roster, from a session participant or a player picked
/// before the session exists.
class RosterPerson {
  const RosterPerson({
    required this.id,
    required this.name,
    required this.initials,
    required this.colorIndex,
    this.username,
    this.status = 'confirmed',
    this.tags = const [],
    this.isCreator = false,
    this.source,
  });

  /// Participant id on a session; player id while setting one up.
  final String id;
  final String name;
  final String initials;
  final int colorIndex;
  final String? username;

  /// confirmed | waitlisted | requested | withdrawn
  final String status;

  /// host, no_show
  final List<String> tags;
  final bool isCreator;
  final String? source;

  bool get isHost => tags.contains('host');
  bool get isNoShow => tags.contains('no_show');
  bool get isConfirmed => status == 'confirmed';

  /// Can be put into a match: confirmed and actually here.
  bool get canPlay => isConfirmed && !isNoShow;

  String get handle => username == null ? '' : '@$username';

  factory RosterPerson.fromParticipant(Map<String, dynamic> p) {
    final initials = '${p['initials'] ?? ''}'.trim();
    final name = '${p['display_name'] ?? '?'}';
    return RosterPerson(
      id: '${p['id']}',
      name: name,
      initials: initials.isNotEmpty ? initials.toUpperCase() : (name.length >= 2 ? name.substring(0, 2) : name).toUpperCase(),
      colorIndex: ((p['avatar_color_index'] as num?)?.toInt() ?? 0) % 8,
      username: (p['player'] as Map?)?['username'] as String?,
      status: '${p['status'] ?? 'confirmed'}',
      tags: ((p['tags'] as List?) ?? const []).map((t) => '$t').toList(),
      isCreator: p['is_creator'] == true,
      source: p['source'] as String?,
    );
  }
}

/// Labels for statuses and tags, shared by the grid and the manage sheet.
const Map<String, String> rosterStatusLabels = {
  'confirmed': 'Confirmed',
  'waitlisted': 'Waitlisted',
  'requested': 'Requested',
};

/// Avatars in a grid: initials circle, name, and a caption. Badges show
/// what matters at a glance — a gold star for hosts, an amber ring for the
/// waitlist, a dashed teal ring for requests, and a faded tile for no-shows.
class RosterGrid extends StatelessWidget {
  const RosterGrid({
    super.key,
    required this.people,
    this.onTap,
    this.onAdd,
    this.addLabel = 'Add',
    this.columns = 5,
  });

  final List<RosterPerson> people;

  /// Tapping a tile; null makes the tiles read-only.
  final ValueChanged<RosterPerson>? onTap;

  /// Shows an "Add" tile first when set.
  final VoidCallback? onAdd;
  final String addLabel;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 4,
      childAspectRatio: 0.70,
      children: [
        if (onAdd != null) _AddTile(label: addLabel, onTap: onAdd!),
        for (final p in people) RosterTile(person: p, onTap: onTap == null ? null : () => onTap!(p)),
      ],
    );
  }
}

class RosterTile extends StatelessWidget {
  const RosterTile({super.key, required this.person, this.onTap});

  final RosterPerson person;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = person;
    final i = p.colorIndex;
    final caption = p.isNoShow
        ? 'No-show'
        : switch (p.status) {
            'waitlisted' => 'Waitlist',
            'requested' => 'Request',
            _ => p.handle,
          };
    final captionColor = p.isNoShow
        ? AppColors.error
        : switch (p.status) {
            'waitlisted' => const Color(0xFFB07800),
            'requested' => AppColors.tealDark,
            _ => AppColors.textFaint,
          };

    final ring = switch (p.status) {
      'waitlisted' => Border.all(color: const Color(0xFFE0A800), width: 2.5),
      'requested' => Border.all(color: AppColors.teal, width: 2.5),
      _ => null,
    };

    final avatar = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.chipPairsBg[i], shape: BoxShape.circle, border: ring),
          child: Text(p.initials, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.chipPairsFg[i])),
        ),
        if (p.isHost)
          Positioned(
            right: -3,
            top: -3,
            child: _Badge(color: const Color(0xFFF2B705), child: const Icon(Icons.star_rounded, size: 11, color: Colors.white)),
          ),
        if (p.isNoShow)
          Positioned(
            right: -3,
            bottom: -3,
            child: _Badge(color: AppColors.error, child: const Icon(Icons.person_off_rounded, size: 10, color: Colors.white)),
          ),
        if (p.status == 'requested')
          Positioned(
            left: -3,
            bottom: -3,
            child: _Badge(color: AppColors.teal, child: const Icon(Icons.question_mark_rounded, size: 10, color: Colors.white)),
          ),
      ],
    );

    final tile = Opacity(
      opacity: p.isNoShow ? 0.5 : 1,
      child: Column(
        children: [
          avatar,
          const SizedBox(height: 5),
          Text(
            p.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.navy),
          ),
          if (caption.isNotEmpty)
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9, fontWeight: p.isConfirmed && !p.isNoShow ? FontWeight.w400 : FontWeight.w800, color: captionColor),
            ),
        ],
      ),
    );

    return Tooltip(
      message: [p.name, if (p.username != null) p.handle, rosterStatusLabels[p.status] ?? p.status, if (p.isHost) 'Host', if (p.isNoShow) 'No-show'].join(' · '),
      child: onTap == null
          ? tile
          : InkWell(borderRadius: BorderRadius.circular(12), onTap: onTap, child: tile),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: 18,
        height: 18,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
        child: child,
      );
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.tealSurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.teal, width: 1.5),
            ),
            child: const Icon(Icons.add_rounded, color: AppColors.tealDark, size: 22),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.tealDark)),
        ],
      ),
    );
  }
}

/// Overlapping avatars for a collapsed roster: the first few, then "+N".
class AvatarStack extends StatelessWidget {
  const AvatarStack({super.key, required this.people, this.max = 6});

  final List<RosterPerson> people;
  final int max;

  // Each avatar shows 22 of its 28px, enough for two initials.
  static const double _size = 28;
  static const double _step = 22;

  @override
  Widget build(BuildContext context) {
    // Fit to the space given: show as many avatars as fit, keeping a slot
    // for "+N", rather than letting the last one be cut off.
    return LayoutBuilder(builder: (context, constraints) {
      final fits = constraints.maxWidth < _size ? 0 : ((constraints.maxWidth - _size) ~/ _step) + 1;
      var take = people.length.clamp(0, max).clamp(0, fits);
      if (take < people.length && take == fits && take > 0) take -= 1; // room for "+N"
      final shown = people.take(take).toList();
      final extra = people.length - shown.length;
      final count = shown.length + (extra > 0 ? 1 : 0);

      return Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          height: _size,
          width: count == 0 ? 0 : _size + _step * (count - 1),
          child: Stack(
            children: [
              for (var i = 0; i < shown.length; i++)
                Positioned(left: _step * i, child: _circle(shown[i].initials, AppColors.chipPairsBg[shown[i].colorIndex], AppColors.chipPairsFg[shown[i].colorIndex])),
              if (extra > 0) Positioned(left: _step * shown.length, child: _circle('+$extra', AppColors.navy, Colors.white)),
            ],
          ),
        ),
      );
    });
  }

  Widget _circle(String text, Color bg, Color fg) => Container(
        width: _size,
        height: _size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
        child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fg, height: 1)),
      );
}
