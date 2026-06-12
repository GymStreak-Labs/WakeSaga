import 'package:flutter/material.dart';

/// Wake Quest mission catalog. Missions are stored as plain strings on
/// [AlarmPlan]/AppState (`quest`, `fallbackQuest`); this catalog is the single
/// source of setup-surface copy: what the user physically does, how WakeSaga
/// verifies it, and who it suits. Verifiers are simulated in this prototype —
/// setup copy must never promise more than the Dawn Rail delivers.
class WakeMission {
  const WakeMission({
    required this.name,
    required this.action,
    required this.proof,
    required this.bestFor,
    required this.icon,
  });

  /// Stable string id, matches WakeQuest's `_mode` switch.
  final String name;

  /// What the user physically does when the alarm rings.
  final String action;

  /// How WakeSaga verifies the mission.
  final String proof;

  /// Who the mission suits.
  final String bestFor;

  final IconData icon;

  static const List<WakeMission> all = [
    WakeMission(
      name: 'Get Up',
      action: 'Stand up and move away from the bed.',
      proof: 'Motion proof',
      bestFor: 'Light sleepers',
      icon: Icons.directions_walk,
    ),
    WakeMission(
      name: 'Object Hunt',
      action: 'Find and photograph the object WakeSaga names.',
      proof: 'Camera + object check',
      bestFor: 'Heavy snoozers',
      icon: Icons.center_focus_strong,
    ),
    WakeMission(
      name: 'Sky Photo',
      action: 'Get to a window and photograph the sky.',
      proof: 'Camera + daylight check',
      bestFor: 'Stay-in-bed scrollers',
      icon: Icons.wb_twilight,
    ),
    WakeMission(
      name: 'Desk Ready',
      action: 'Photograph your desk, book, or laptop set up.',
      proof: 'Camera proof',
      bestFor: 'Students & deep workers',
      icon: Icons.desktop_windows_outlined,
    ),
    WakeMission(
      name: 'Shake',
      action: 'Shake the phone until the meter fills.',
      proof: 'Motion sensor',
      bestFor: 'Fast clears · the fallback',
      icon: Icons.vibration,
    ),
  ];

  static WakeMission byName(String name) => all.firstWhere(
    (mission) => mission.name == name,
    orElse: () => all.first,
  );
}
