import 'package:flutter/material.dart';

import '../models/club.dart';
import '../models/player.dart';
import '../models/session_summary.dart';
import '../theme/app_colors.dart';

/// Seed data mirroring the constants baked into the Claude Design prototype
/// (ALL_PLAYERS, ALL_CLUBS, ACTIVE_SESSIONS, ... in Padelicious App.dc.html).
/// Kept in one place so a future networked repository implementation has a
/// single source to replace.
class MockData {
  MockData._();

  static const currentPlayerName = 'Iqbal';

  static const List<Player> allPlayers = [
    Player(name: 'Iqbal', initials: 'IQ', bg: AppColors.chipPairsBg0, color: AppColors.chipPairsFg0, badge: 'Admin'),
    Player(name: 'Rafi', initials: 'RF', bg: AppColors.chipPairsBg1, color: AppColors.chipPairsFg1),
    Player(name: 'Budi', initials: 'BD', bg: AppColors.chipPairsBg2, color: AppColors.chipPairsFg2),
    Player(name: 'Hendra', initials: 'HN', bg: AppColors.chipPairsBg3, color: AppColors.chipPairsFg3),
    Player(name: 'Andi', initials: 'AN', bg: AppColors.chipPairsBg4, color: AppColors.chipPairsFg4),
    Player(name: 'Dito', initials: 'DT', bg: AppColors.chipPairsBg5, color: AppColors.chipPairsFg5),
    Player(name: 'Yoga', initials: 'YG', bg: AppColors.chipPairsBg6, color: AppColors.chipPairsFg6),
    Player(name: 'Febri', initials: 'FB', bg: AppColors.chipPairsBg7, color: AppColors.chipPairsFg7),
    Player(name: 'Rizal', initials: 'RZ', bg: AppColors.chipPairsBg0, color: AppColors.chipPairsFg0),
    Player(name: 'Fajar', initials: 'FJ', bg: AppColors.chipPairsBg1, color: AppColors.chipPairsFg1),
    Player(name: 'Tommy', initials: 'TM', bg: AppColors.chipPairsBg2, color: AppColors.chipPairsFg2),
    Player(name: 'Irwan', initials: 'IW', bg: AppColors.chipPairsBg3, color: AppColors.chipPairsFg3),
    Player(name: 'Bagas', initials: 'BG', bg: AppColors.chipPairsBg4, color: AppColors.chipPairsFg4),
    Player(name: 'Kurnia', initials: 'KR', bg: AppColors.chipPairsBg5, color: AppColors.chipPairsFg5),
    Player(name: 'Sandi', initials: 'SD', bg: AppColors.chipPairsBg6, color: AppColors.chipPairsFg6),
    Player(name: 'Wira', initials: 'WR', bg: AppColors.chipPairsBg7, color: AppColors.chipPairsFg7),
  ];

  static const List<String> reclubLevelValues = ['1.0', '1.5', '2.0', '2.5', '3.0', '3.5', '4.0', '4.5', '5.0'];
  static const List<String> reclubLevelLabels = [
    'Beginner',
    'Beginner+',
    'Lower intermediate',
    'Intermediate',
    'Intermediate+',
    'Upper intermediate',
    'Advanced',
    'Advanced+',
    'Competition',
  ];

  static const List<Player> defaultSetupPlayers = [
    Player(name: 'Iqbal', initials: 'IQ', bg: AppColors.chipPairsBg0, color: AppColors.chipPairsFg0, badge: 'Admin'),
    Player(name: 'Rafi', initials: 'RF', bg: AppColors.chipPairsBg1, color: AppColors.chipPairsFg1),
    Player(name: 'Budi', initials: 'BD', bg: AppColors.chipPairsBg2, color: AppColors.chipPairsFg2),
    Player(name: 'Hendra', initials: 'HN', bg: AppColors.chipPairsBg3, color: AppColors.chipPairsFg3),
  ];

  static const List<Player> reclubImportPlayers = [
    Player(name: 'Iqbal', initials: 'IQ', bg: AppColors.chipPairsBg0, color: AppColors.chipPairsFg0, badge: 'Admin'),
    Player(name: 'Rafi', initials: 'RF', bg: AppColors.chipPairsBg1, color: AppColors.chipPairsFg1, fromReclub: true),
    Player(name: 'Budi', initials: 'BD', bg: AppColors.chipPairsBg2, color: AppColors.chipPairsFg2, fromReclub: true),
    Player(name: 'Hendra', initials: 'HN', bg: AppColors.chipPairsBg3, color: AppColors.chipPairsFg3, fromReclub: true),
    Player(name: 'Andi', initials: 'AN', bg: AppColors.chipPairsBg4, color: AppColors.chipPairsFg4, fromReclub: true),
    Player(name: 'Dito', initials: 'DT', bg: AppColors.chipPairsBg5, color: AppColors.chipPairsFg5, fromReclub: true),
    Player(name: 'Yoga', initials: 'YG', bg: AppColors.chipPairsBg6, color: AppColors.chipPairsFg6, fromReclub: true),
    Player(name: 'Febri', initials: 'FB', bg: AppColors.chipPairsBg7, color: AppColors.chipPairsFg7, fromReclub: true),
  ];

  static const List<String> queueNames = ['Rizal', 'Fajar', 'Tommy', 'Irwan', 'Bagas', 'Kurnia', 'Sandi', 'Wira'];

  static List<Club> seedClubs() => [
        Club(id: 'padel-prime', name: 'Padel Prime', emoji: '🏆', bg: const Color(0xFFFFF0DC), members: 45, isMember: true, description: 'A premium club for competitive padel players who love a good rally.'),
        Club(id: 'court-kings', name: 'Court Kings', emoji: '👑', bg: const Color(0xFFDCEEFF), members: 32, isMember: true, description: 'Weekly King of the Court nights for all skill levels.'),
        Club(id: 'smash-club', name: 'Smash Club', emoji: '💥', bg: const Color(0xFFEDE0FF), members: 28, isMember: false, description: 'Casual smashes and social matches every weekend.'),
        Club(id: 'racket-masters', name: 'Racket Masters', emoji: '⚡', bg: const Color(0xFFE8FFD4), members: 56, isMember: false, description: 'Focused on technique, drills, and friendly competition.'),
        Club(id: 'urban-padel', name: 'Urban Padel', emoji: '🏙️', bg: const Color(0xFFFFDCDC), members: 38, isMember: false, description: 'City courts, evening sessions, easygoing crowd.'),
        Club(id: 'elite-courts', name: 'Elite Courts', emoji: '🌟', bg: const Color(0xFFDCF5FF), members: 62, isMember: true, description: 'The biggest club in town — tournaments monthly.'),
        Club(id: 'mega-padel-league', name: 'Mega Padel League', emoji: '🚀', bg: const Color(0xFFE4F7F7), members: 1000, isMember: true, description: 'The largest padel community in the country — 1,000 members across 12 cities.'),
      ];

  static const List<SessionSummary> activeSessions = [
    SessionSummary(icon: '👑', name: 'Sunday King of the Court', detail: 'Court 1 · Game 5 · In progress'),
  ];

  static const List<SessionSummary> pastSessions = [
    SessionSummary(icon: '🎾', name: 'Saturday Americano', detail: 'Jul 20 · 8 players'),
    SessionSummary(icon: '📊', name: 'Weekday Mexicano', detail: 'Jul 15 · 8 players'),
    SessionSummary(icon: '⚙️', name: 'Custom club night', detail: 'Jul 8 · 6 players'),
  ];

  static const List<String> memberFirstNames = [
    'Iqbal', 'Rafi', 'Budi', 'Hendra', 'Andi', 'Dito', 'Yoga', 'Febri', 'Rizal', 'Fajar',
    'Tommy', 'Irwan', 'Bagas', 'Kurnia', 'Sandi', 'Wira', 'Doni', 'Eka', 'Galih', 'Hafiz',
    'Ilham', 'Joko', 'Krisna', 'Lutfi', 'Made', 'Nanda', 'Oscar', 'Putra', 'Qori', 'Reza',
    'Satrio', 'Taufik', 'Umar', 'Vino', 'Wisnu', 'Yusuf', 'Zaki', 'Agus', 'Bayu', 'Candra',
  ];
}
