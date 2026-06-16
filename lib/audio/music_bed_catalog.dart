enum EpisodeMusicIntensity { low, medium, high, milestone }

class EpisodeMusicBed {
  const EpisodeMusicBed({
    required this.id,
    required this.label,
    required this.description,
    required this.assetPath,
    required this.intensity,
    required this.arcSignals,
    required this.modeSignals,
    this.baseWeight = 10,
  });

  final String id;
  final String label;
  final String description;
  final String assetPath;
  final EpisodeMusicIntensity intensity;
  final List<String> arcSignals;
  final List<String> modeSignals;
  final int baseWeight;

  String get assetSourcePath {
    const prefix = 'assets/';
    if (assetPath.startsWith(prefix)) return assetPath.substring(prefix.length);
    return assetPath;
  }

  bool get isMilestone => intensity == EpisodeMusicIntensity.milestone;
}

const episodeMusicBeds = <EpisodeMusicBed>[
  EpisodeMusicBed(
    id: 'dawn_rise',
    label: 'Dawn Rise',
    description: 'Hopeful first-light lift for default morning episodes.',
    assetPath: 'assets/audio/music_beds/dawn_rise.mp3',
    intensity: EpisodeMusicIntensity.medium,
    arcSignals: ['study', 'deep work', 'morning'],
    modeSignals: ['mentor', 'light', 'normal'],
    baseWeight: 14,
  ),
  EpisodeMusicBed(
    id: 'rival_pulse',
    label: 'Rival Pulse',
    description: 'Sharper competitive pressure for high-intensity mornings.',
    assetPath: 'assets/audio/music_beds/rival_pulse.mp3',
    intensity: EpisodeMusicIntensity.high,
    arcSignals: ['gym', 'comeback', 'deep work'],
    modeSignals: ['rival', 'full', 'hard'],
    baseWeight: 11,
  ),
  EpisodeMusicBed(
    id: 'deep_work_tension',
    label: 'Deep Work Tension',
    description: 'Focused tension for study, work, and deadline arcs.',
    assetPath: 'assets/audio/music_beds/deep_work_tension.mp3',
    intensity: EpisodeMusicIntensity.medium,
    arcSignals: ['study', 'deep work'],
    modeSignals: ['captain', 'normal', 'hard'],
    baseWeight: 13,
  ),
  EpisodeMusicBed(
    id: 'gym_charge',
    label: 'Gym Charge',
    description: 'Physical lift for training, movement, and body arcs.',
    assetPath: 'assets/audio/music_beds/gym_charge.mp3',
    intensity: EpisodeMusicIntensity.high,
    arcSignals: ['gym', 'body', 'training'],
    modeSignals: ['captain', 'full', 'hard'],
    baseWeight: 12,
  ),
  EpisodeMusicBed(
    id: 'comeback_low',
    label: 'Comeback Low',
    description: 'Lower, steadier recovery-after-miss treatment.',
    assetPath: 'assets/audio/music_beds/comeback_low.mp3',
    intensity: EpisodeMusicIntensity.low,
    arcSignals: ['comeback', 'recovery'],
    modeSignals: ['light', 'gentle', 'mentor'],
    baseWeight: 10,
  ),
  EpisodeMusicBed(
    id: 'monk_mode_minimal',
    label: 'Monk Mode Minimal',
    description: 'Sparse discipline bed for quiet, locked-in mornings.',
    assetPath: 'assets/audio/music_beds/monk_mode_minimal.mp3',
    intensity: EpisodeMusicIntensity.low,
    arcSignals: ['monk', 'study', 'deep work'],
    modeSignals: ['quiet senior', 'off', 'gentle'],
    baseWeight: 12,
  ),
  EpisodeMusicBed(
    id: 'recovery_soft',
    label: 'Recovery Soft',
    description: 'Gentle reset for low-mood and recovery mornings.',
    assetPath: 'assets/audio/music_beds/recovery_soft.mp3',
    intensity: EpisodeMusicIntensity.low,
    arcSignals: ['recovery', 'comeback'],
    modeSignals: ['off', 'gentle', 'light', 'quiet senior'],
    baseWeight: 10,
  ),
  EpisodeMusicBed(
    id: 'victory_foil',
    label: 'Victory Foil',
    description: 'Milestone/share-card treatment, reserved for big clears.',
    assetPath: 'assets/audio/music_beds/victory_foil.mp3',
    intensity: EpisodeMusicIntensity.milestone,
    arcSignals: ['milestone'],
    modeSignals: ['foil'],
    baseWeight: 1,
  ),
];

EpisodeMusicBed episodeMusicBedById(String? id) {
  return episodeMusicBeds.firstWhere(
    (bed) => bed.id == id,
    orElse: () => episodeMusicBeds.first,
  );
}

EpisodeMusicBed selectEpisodeMusicBed({
  required String arc,
  required String rivalIntensity,
  required String narrator,
  required String difficulty,
  required String quest,
  required int episode,
  required DateTime localDate,
  required String userKey,
  List<String> recentBedIds = const [],
  bool comeback = false,
  bool milestone = false,
}) {
  if (milestone) return episodeMusicBedById('victory_foil');
  if (comeback) return episodeMusicBedById('comeback_low');

  final arcText = _normalize('$arc $quest');
  final modeText = _normalize('$rivalIntensity $narrator $difficulty');
  var candidates = episodeMusicBeds
      .where((bed) => !bed.isMilestone)
      .where((bed) => _selectionWeight(bed, arcText, modeText) > 0)
      .toList();
  if (candidates.isEmpty) {
    candidates = episodeMusicBeds.where((bed) => !bed.isMilestone).toList();
  }

  final recent = recentBedIds.take(3).toSet();
  final fresh = candidates.where((bed) => !recent.contains(bed.id)).toList();
  if (fresh.length >= 2) candidates = fresh;

  final seed =
      '$userKey|$episode|${localDate.year}-${localDate.month}-${localDate.day}|'
      '$arc|$rivalIntensity|$narrator|$difficulty|$quest';
  return _weightedPick(candidates, seed, (bed) {
    return _selectionWeight(bed, arcText, modeText);
  });
}

EpisodeMusicBed _weightedPick(
  List<EpisodeMusicBed> candidates,
  String seed,
  int Function(EpisodeMusicBed bed) weightFor,
) {
  final total = candidates.fold<int>(
    0,
    (sum, bed) => sum + weightFor(bed).clamp(1, 100).toInt(),
  );
  var draw = _stableHash(seed) % total;
  for (final bed in candidates) {
    draw -= weightFor(bed).clamp(1, 100).toInt();
    if (draw < 0) return bed;
  }
  return candidates.first;
}

int _selectionWeight(EpisodeMusicBed bed, String arcText, String modeText) {
  var weight = bed.baseWeight;
  if (bed.arcSignals.any(arcText.contains)) weight += 9;
  if (bed.modeSignals.any(modeText.contains)) weight += 7;
  if (modeText.contains('full') &&
      bed.intensity == EpisodeMusicIntensity.high) {
    weight += 5;
  }
  if (modeText.contains('gentle') &&
      bed.intensity == EpisodeMusicIntensity.low) {
    weight += 5;
  }
  if (arcText.contains('sky') && bed.id == 'dawn_rise') weight += 4;
  if (arcText.contains('desk') && bed.id == 'deep_work_tension') weight += 4;
  if (arcText.contains('water') && bed.id == 'recovery_soft') weight += 3;
  return weight;
}

String _normalize(String value) => value.toLowerCase().replaceAll('-', ' ');

int _stableHash(String value) {
  var hash = 0x811c9dc5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
}
