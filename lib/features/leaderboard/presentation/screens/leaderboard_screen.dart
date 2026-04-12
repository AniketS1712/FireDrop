import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eagle_esports/shared/models/leaderboard_entry.dart';
import 'package:eagle_esports/shared/models/leaderboard_template.dart';
import 'package:eagle_esports/shared/models/tournaments_model.dart';
import 'package:eagle_esports/features/auth/presentation/providers/auth_providers.dart';
import 'package:eagle_esports/features/leaderboard/presentation/providers/leaderboard_providers.dart';
import '../widgets/leaderboard_header.dart';
import '../widgets/leaderboard_table.dart';
import '../widgets/leaderboard_controls.dart';
import '../widgets/template_picker.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  final TournamentModel tournament;

  const LeaderboardScreen({super.key, required this.tournament});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  final List<LeaderboardEntry> _entries = [];
  bool _initialised = false;
  bool _saving = false;
  bool _showLegend = false;
  LeaderboardTemplate _selectedTemplate = LeaderboardTemplate.classic;

  Map<String, int> _savedPositions = {};
  Map<String, int> _savedKills = {};

  TournamentModel get _t => widget.tournament;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSavedData());
  }

  Future<void> _loadSavedData() async {
    final saved = await LeaderboardService.fetchLeaderboard(_t.id);
    if (saved != null && mounted) {
      final rawStandings = (saved['standings'] as List?) ?? [];
      final templateStr = saved['template'] as String?;

      setState(() {
        _savedPositions = {
          for (final s in rawStandings)
            s['teamId'] as String: (s['position'] as int?) ?? 0,
        };
        _savedKills = {
          for (final s in rawStandings)
            s['teamId'] as String: (s['kills'] as int?) ?? 0,
        };
        if (templateStr != null) {
          _selectedTemplate = LeaderboardTemplate.values.firstWhere(
            (e) => e.name == templateStr,
            orElse: () => LeaderboardTemplate.classic,
          );
        }
      });
    }
  }

  void _syncEntries(List<dynamic> teams) {
    if (_initialised) return;

    _entries.clear();
    for (final team in teams) {
      final t = team as dynamic;
      final entry = LeaderboardEntry(
        teamId: t.id as String,
        teamName: t.name as String,
        leaderId: t.organizerID as String,
        memberUids: List<String>.from(t.members as List),
        position: _savedPositions[t.id] ?? 0,
        kills: _savedKills[t.id] ?? 0,
      );
      _entries.add(entry);
    }
    _recomputeRanks();
    _initialised = true;
  }

  void _recomputeRanks() {
    final sorted = List<LeaderboardEntry>.from(_entries)
      ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    int rank = 1;
    for (int i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i].totalPoints < sorted[i - 1].totalPoints) {
        rank = i + 1;
      }
      sorted[i].rank = rank;
    }
  }

  Future<void> _saveLeaderboard({required bool publish}) async {
    final organizer = ref.read(currentUserProvider).value;
    if (organizer == null) return;

    setState(() => _saving = true);
    try {
      _recomputeRanks();
      await LeaderboardService.saveLeaderboard(
        tournamentId: _t.id,
        createdByUid: organizer.uid,
        entries: _entries,
        isPublished: publish,
        template: _selectedTemplate,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            publish
                ? '🏆 Leaderboard published!'
                : '💾 Draft saved successfully.',
          ),
          backgroundColor: publish
              ? Theme.of(context).colorScheme.primary
              : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showPublishDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => TemplatePickerBottomSheet(
        initialTemplate: _selectedTemplate,
        onTemplateSelected: (template) {
          setState(() => _selectedTemplate = template);
          _saveLeaderboard(publish: true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final teamsAsync = ref.watch(tournamentTeamsProvider(_t.id));

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: teamsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e', style: TextStyle(color: colorScheme.error)),
        ),
        data: (teams) {
          if (!_initialised) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _syncEntries(teams));
            });
          }

          final leaderNames = <String, String?>{};
          for (final t in teams) {
            leaderNames[t.organizerID] = ref
                .watch(userByIdProvider(t.organizerID))
                .value
                ?.name;
          }

          final displayEntries = List<LeaderboardEntry>.from(_entries)
            ..sort((a, b) => a.rank.compareTo(b.rank));

          return Column(
            children: [
              LeaderboardAppBar(
                tournament: _t,
                showLegend: _showLegend,
                onToggleLegend: () =>
                    setState(() => _showLegend = !_showLegend),
              ),
              LeaderboardPointsLegend(isVisible: _showLegend),
              const LeaderboardTableHeader(),
              Expanded(
                child: _entries.isEmpty
                    ? const LeaderboardEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: displayEntries.length,
                        itemBuilder: (context, index) {
                          final entry = displayEntries[index];
                          return LeaderboardRowItem(
                            entry: entry,
                            leaderName:
                                leaderNames[entry.leaderId] ?? 'Unknown',
                            rank: entry.rank,
                            onPositionChanged: (v) =>
                                setState(() => entry.position = v),
                            onKillsChanged: (v) =>
                                setState(() => entry.kills = v),
                          );
                        },
                      ),
              ),
              LeaderboardBottomBar(
                isSaving: _saving,
                onSaveDraft: () => _saveLeaderboard(publish: false),
                onPublish: _showPublishDialog,
              ),
            ],
          );
        },
      ),
    );
  }
}
