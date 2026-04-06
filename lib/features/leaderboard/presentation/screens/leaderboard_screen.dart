// import 'package:firedrop/core/theme/app_colors.dart';
import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:firedrop/shared/models/leaderboard_entry.dart';
import 'package:firedrop/shared/models/leaderboard_template.dart';
import 'package:firedrop/shared/models/tournaments_model.dart';
import 'package:firedrop/features/auth/presentation/providers/auth_providers.dart';
import 'package:firedrop/features/leaderboard/presentation/providers/leaderboard_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Column width constants ───────────────────────────────────────────────────
const double _colPosition = 72.0;
const double _colKills = 72.0;
const double _colPoints = 72.0;

// ─── Screen ───────────────────────────────────────────────────────────────────
class LeaderboardScreen extends ConsumerStatefulWidget {
  final TournamentModel tournament;

  const LeaderboardScreen({super.key, required this.tournament});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  /// Local mutable list populated from Firestore teams + any saved data.
  final List<LeaderboardEntry> _entries = [];
  bool _initialised = false;
  bool _saving = false;
  LeaderboardTemplate _selectedTemplate = LeaderboardTemplate.classic;

  TournamentModel get _t => widget.tournament;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Load any previously saved leaderboard after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSavedData());
  }

  Future<void> _loadSavedData() async {
    final saved = await LeaderboardService.fetchLeaderboard(_t.id);
    if (saved != null && mounted) {
      final rawStandings = (saved['standings'] as List?) ?? [];
      _savedPositions = {
        for (final s in rawStandings)
          s['teamId'] as String: (s['position'] as int?) ?? 0,
      };
      _savedKills = {
        for (final s in rawStandings)
          s['teamId'] as String: (s['kills'] as int?) ?? 0,
      };
    }
  }

  Map<String, int> _savedPositions = {};
  Map<String, int> _savedKills = {};

  // ─── Build entries from teams stream ───────────────────────────────────────

  void _syncEntries(List<dynamic> teams, Map<String, String?> leaderNames) {
    if (_initialised) return; // Only seed once

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
    // Copy ranks back to _entries (same objects by reference)
  }

  // ─── Save logic ────────────────────────────────────────────────────────────

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

  // ─── Build ─────────────────────────────────────────────────────────────────

  // ── Template Picker (shown before publish) ────────────────────────────────

  Future<void> _showTemplatePickerThenPublish() async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    LeaderboardTemplate? picked = _selectedTemplate;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(AppSizes.space24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorScheme.outline.withAlpha(60)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Icon(
                      Icons.palette_rounded,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Choose Leaderboard Template',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Select a visual style for the published leaderboard',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSizes.space24),

                // Template options
                ...kLeaderboardTemplates.map((meta) {
                  final isSelected = picked == meta.template;
                  return GestureDetector(
                    onTap: () {
                      setSheetState(() => picked = meta.template);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: AppSizes.space12),
                      padding: const EdgeInsets.all(AppSizes.space16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withAlpha(15)
                            : colorScheme.onSurface.withAlpha(8),
                        borderRadius: BorderRadius.circular(AppSizes.radius16),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant.withAlpha(30),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: colorScheme.primary.withAlpha(20),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Text(
                            meta.previewIcon,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: AppSizes.space16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meta.name,
                                  style: textTheme.titleSmall?.copyWith(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  meta.description,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle_rounded,
                              color: colorScheme.primary,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: AppSizes.space16),

                // Publish button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(ctx, true),
                    icon: const Icon(Icons.publish_rounded),
                    label: const Text(
                      'PUBLISH WITH THIS TEMPLATE',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radius16),
                      ),
                    ),
                  ),
                ),

                // cancel
                const SizedBox(height: AppSizes.space8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (confirmed == true && picked != null) {
      setState(() => _selectedTemplate = picked!);
      await _saveLeaderboard(publish: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(tournamentTeamsProvider(_t.id));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: teamsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        data: (teams) {
          // Build leader-name lookup using Riverpod family providers
          final leaderNames = <String, String?>{};
          for (final t in teams) {
            final userAsync = ref.watch(userByIdProvider(t.organizerID));
            leaderNames[t.organizerID] = userAsync.value?.name;
          }

          // Seed local entries (only once)
          if (!_initialised) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_initialised && mounted) {
                setState(() => _syncEntries(teams, leaderNames));
              }
            });
          }

          return Column(
            children: [
              _buildAppBar(context),
              _buildPointsLegend(),
              const SizedBox(height: 8),
              _buildHeaderRow(),
              Divider(height: 2, color: Theme.of(context).colorScheme.outline),
              Expanded(
                child: _entries.isEmpty
                    ? _buildEmptyState()
                    : _buildTable(leaderNames),
              ),
              _buildBottomBar(),
            ],
          );
        },
      ),
    );
  }

  // ── App Bar ────────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 16,
        bottom: 12,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LEADERBOARD',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  _t.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Points legend toggle
          IconButton(
            onPressed: () => setState(() => _showLegend = !_showLegend),
            tooltip: 'Points table',
            icon: Icon(
              Icons.info_outline_rounded,
              color: _showLegend
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  bool _showLegend = false;

  // ── Points legend ──────────────────────────────────────────────────────────

  Widget _buildPointsLegend() {
    if (!_showLegend) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space16,
        vertical: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'POSITION POINTS',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                'Kill = $kKillPoints pt each',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: kPositionPoints.entries.map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: Text(
                  '#${e.key} → ${e.value} pts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Header Row ─────────────────────────────────────────────────────────────

  Widget _buildHeaderRow() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Expanded(child: _headerCell('TEAM', TextAlign.left)),
          _headerCell('POS', TextAlign.center, width: _colPosition),
          _headerCell('KILLS', TextAlign.center, width: _colKills),
          _headerCell('POINTS', TextAlign.center, width: _colPoints),
        ],
      ),
    );
  }

  Widget _headerCell(String label, TextAlign align, {double? width}) {
    final cell = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        label,
        textAlign: align,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
    if (width != null) return SizedBox(width: width, child: cell);
    return cell;
  }

  // ── Table ──────────────────────────────────────────────────────────────────

  Widget _buildTable(Map<String, String?> leaderNames) {
    _recomputeRanks();

    // Sort by rank for display
    final sorted = List<LeaderboardEntry>.from(_entries)
      ..sort((a, b) => a.rank.compareTo(b.rank));

    return Column(
      children: [
        for (int i = 0; i < sorted.length; i++) ...[
          _LeaderboardRow(
            entry: sorted[i],
            leaderName:
                leaderNames[sorted[i].leaderId] ??
                sorted[i].leaderId.substring(0, 6),
            rank: sorted[i].rank,
            onPositionChanged: (v) {
              setState(() {
                sorted[i].position = v;
                _recomputeRanks();
              });
            },
            onKillsChanged: (v) {
              setState(() {
                sorted[i].kills = v;
                _recomputeRanks();
              });
            },
          ),
          if (i < sorted.length - 1)
            Divider(height: 1, color: Theme.of(context).colorScheme.outline),
        ],
      ],
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.groups_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            size: 56,
          ),
          SizedBox(height: 12),
          Text(
            'No teams registered yet.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ─────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(
        left: AppSizes.space16,
        right: AppSizes.space16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline)),
      ),
      child: Row(
        children: [
          // Save draft
          Expanded(
            child: _BottomBtn(
              label: 'Save Draft',
              icon: Icons.save_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              loading: _saving,
              onTap: () => _saveLeaderboard(publish: false),
            ),
          ),
          const SizedBox(width: AppSizes.space12),
          // Publish
          Expanded(
            flex: 2,
            child: _BottomBtn(
              label: 'Publish Results',
              icon: Icons.emoji_events_rounded,
              color: Theme.of(context).colorScheme.primary,
              loading: _saving,
              onTap: () => _showTemplatePickerThenPublish(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Individual Row ───────────────────────────────────────────────────────────
class _LeaderboardRow extends StatefulWidget {
  final LeaderboardEntry entry;
  final String leaderName;
  final int rank;
  final ValueChanged<int> onPositionChanged;
  final ValueChanged<int> onKillsChanged;

  const _LeaderboardRow({
    required this.entry,
    required this.leaderName,
    required this.rank,
    required this.onPositionChanged,
    required this.onKillsChanged,
  });

  @override
  State<_LeaderboardRow> createState() => _LeaderboardRowState();
}

class _LeaderboardRowState extends State<_LeaderboardRow> {
  late final TextEditingController _posCtrl;
  late final TextEditingController _killsCtrl;

  @override
  void initState() {
    super.initState();
    _posCtrl = TextEditingController(
      text: widget.entry.position > 0 ? '${widget.entry.position}' : '',
    );
    _killsCtrl = TextEditingController(text: '${widget.entry.kills}');
  }

  @override
  void dispose() {
    _posCtrl.dispose();
    _killsCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_LeaderboardRow old) {
    super.didUpdateWidget(old);
    // Keep controller text in sync when external state changes
    final newPos = widget.entry.position > 0 ? '${widget.entry.position}' : '';
    if (_posCtrl.text != newPos) {
      _posCtrl.value = TextEditingValue(
        text: newPos,
        selection: TextSelection.collapsed(offset: newPos.length),
      );
    }
    final newKills = '${widget.entry.kills}';
    if (_killsCtrl.text != newKills) {
      _killsCtrl.value = TextEditingValue(
        text: newKills,
        selection: TextSelection.collapsed(offset: newKills.length),
      );
    }
  }

  // ── Rank accent colour ─────────────────────────────────────────────────────
  Color _rankColor(int rank) {
    if (rank == 1) return Theme.of(context).colorScheme.primary;
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final isTop3 = widget.rank <= 3 && widget.rank > 0;

    // ── Main row ──────────────────────────────────────────────────────────────
    return Container(
      color: isTop3
          ? _rankColor(widget.rank).withAlpha(13)
          : Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Rank indicator (left accent) ──────────────────────────────────
          Container(
            width: 4,
            height: 56,
            color: isTop3 ? _rankColor(widget.rank) : Colors.transparent,
          ),

          // ── Team name ─────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.entry.teamName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isTop3)
                    Text(
                      widget.rank == 1
                          ? '🥇 1st Place'
                          : widget.rank == 2
                          ? '🥈 2nd Place'
                          : '🥉 3rd Place',
                      style: TextStyle(
                        color: _rankColor(widget.rank),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Position (editable) ───────────────────────────────────────────
          SizedBox(
            width: _colPosition,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _NumberCell(
                controller: _posCtrl,
                hint: '—',
                onChanged: (v) {
                  widget.onPositionChanged(int.tryParse(v) ?? 0);
                },
              ),
            ),
          ),

          // ── Kills (editable) ──────────────────────────────────────────────
          SizedBox(
            width: _colKills,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _NumberCell(
                controller: _killsCtrl,
                hint: '0',
                onChanged: (v) {
                  widget.onKillsChanged(int.tryParse(v) ?? 0);
                },
              ),
            ),
          ),

          // ── Total points (auto) ───────────────────────────────────────────
          SizedBox(
            width: _colPoints,
            child: Center(
              child: Text(
                '${widget.entry.totalPoints}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Editable number cell ─────────────────────────────────────────────────────
class _NumberCell extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _NumberCell({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius8),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius8),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius8),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Bottom action button ─────────────────────────────────────────────────────
class _BottomBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onTap;

  const _BottomBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          border: Border.all(color: color.withAlpha(128)),
        ),
        child: loading
            ? Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
