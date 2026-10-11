import 'package:flutter/material.dart';

class Club {
  final String id;
  String name;
  String emoji;
  Color bg;
  int members;
  bool isMember;
  String description;

  Club({
    required this.id,
    required this.name,
    required this.emoji,
    required this.bg,
    required this.members,
    required this.isMember,
    required this.description,
  });
}
