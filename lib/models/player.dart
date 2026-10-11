import 'package:flutter/material.dart';

class Player {
  final String name;
  final String initials;
  final Color bg;
  final Color color;
  final String? badge;
  final bool fromReclub;

  const Player({
    required this.name,
    required this.initials,
    required this.bg,
    required this.color,
    this.badge,
    this.fromReclub = false,
  });

  Player copyWith({bool? fromReclub}) => Player(
        name: name,
        initials: initials,
        bg: bg,
        color: color,
        badge: badge,
        fromReclub: fromReclub ?? this.fromReclub,
      );
}

class PlayerProfile {
  final Player player;
  final int sessions;
  final String level;

  const PlayerProfile({
    required this.player,
    required this.sessions,
    required this.level,
  });
}

class ClubMember {
  final String name;
  final String initials;
  final Color bg;
  final Color color;
  final bool isOwner;

  const ClubMember({
    required this.name,
    required this.initials,
    required this.bg,
    required this.color,
    this.isOwner = false,
  });
}
