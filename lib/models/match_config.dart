/// Static reference data for the Setup screen's match-type / scoring options,
/// mirroring MATCH_TYPE_LABELS and the grouped <select> options in the
/// original design.
class MatchTypeOption {
  final String value;
  final String label;

  const MatchTypeOption(this.value, this.label);
}

class MatchTypeGroup {
  final String category;
  final List<MatchTypeOption> options;

  const MatchTypeGroup(this.category, this.options);
}

const List<MatchTypeGroup> matchTypeGroups = [
  MatchTypeGroup('Americano', [
    MatchTypeOption('americano', 'Americano'),
    MatchTypeOption('team_americano', 'Team Americano'),
    MatchTypeOption('mix_americano', 'Mix Americano'),
  ]),
  MatchTypeGroup('Mexicano', [
    MatchTypeOption('mexicano', 'Mexicano'),
    MatchTypeOption('team_mexicano', 'Team Mexicano'),
    MatchTypeOption('mixicano', 'Mixicano'),
  ]),
  MatchTypeGroup('KOTH', [
    MatchTypeOption('koth', 'KOTH'),
    MatchTypeOption('team_koth', 'Team KOTH'),
  ]),
];

const Map<String, String> matchTypeLabels = {
  'americano': 'Americano',
  'team_americano': 'Team Americano',
  'mix_americano': 'Mix Americano',
  'mexicano': 'Mexicano',
  'team_mexicano': 'Team Mexicano',
  'mixicano': 'Mixicano',
  'koth': 'King of the Court',
  'team_koth': 'Team King of the Court',
};

const List<MatchTypeOption> normalTargetOptions = [
  MatchTypeOption('16', '16 points'),
  MatchTypeOption('21', '21 points'),
  MatchTypeOption('24', '24 points'),
  MatchTypeOption('32', '32 points'),
  MatchTypeOption('undefined', 'Undefined'),
];

const List<MatchTypeOption> tennisModeOptions = [
  MatchTypeOption('race3', 'First to 3'),
  MatchTypeOption('race4', 'First to 4'),
  MatchTypeOption('race5', 'First to 5'),
  MatchTypeOption('race6', 'First to 6'),
  MatchTypeOption('race7', 'First to 7'),
  MatchTypeOption('total3', 'Total of 3'),
  MatchTypeOption('total4', 'Total of 4'),
  MatchTypeOption('total5', 'Total of 5'),
  MatchTypeOption('total6', 'Total of 6'),
  MatchTypeOption('total7', 'Total of 7'),
  MatchTypeOption('undefined', 'Undefined amount'),
];
