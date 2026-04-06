
enum LeaderboardTemplate {
  classic,
}

class LeaderboardTemplateMeta {
  final LeaderboardTemplate template;
  final String name;
  final String description;
  final String previewIcon;

  const LeaderboardTemplateMeta({
    required this.template,
    required this.name,
    required this.description,
    required this.previewIcon,
  });
}

const List<LeaderboardTemplateMeta> kLeaderboardTemplates = [
  LeaderboardTemplateMeta(
    template: LeaderboardTemplate.classic,
    name: 'Classic Esports',
    description:
        'Podium with top 3 teams, full standings table, and accent-colored rank indicators.',
    previewIcon: '🏆',
  ),
];
