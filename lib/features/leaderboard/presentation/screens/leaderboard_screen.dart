import 'package:firedrop/core/theme/app_colors.dart';
import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:firedrop/shared/models/leaderboard_entry.dart';
import 'package:firedrop/shared/models/tournaments_model.dart';
import 'package:firedrop/features/auth/presentation/providers/auth_providers.dart';
import 'package:firedrop/features/leaderboard/presentation/providers/leaderboard_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Column width constants ───────────────────────────────────────────────────
const double _colTeam = 140.0;
const double _colPosition = 80.0;
const double _colKills = 80.0;
const double _colPoints = 80.0;
const double _colRank = 64.0;

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
              ? AppColorTokens.primary
              : AppColorTokens.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColorTokens.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(tournamentTeamsProvider(_t.id));

    return Scaffold(
      backgroundColor: AppColorTokens.bgPrimary,
      body: teamsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColorTokens.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppColorTokens.error),
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
              const Divider(height: 1, color: AppColorTokens.border),
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
      color: AppColorTokens.bgSecondary,
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
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: AppColorTokens.primary,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LEADERBOARD',
                  style: TextStyle(
                    color: AppColorTokens.primary,
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
                  ? AppColorTokens.primary
                  : AppColorTokens.textSecondary,
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
      color: AppColorTokens.bgTertiary,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space16,
        vertical: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: AppColorTokens.gold,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'POSITION POINTS',
                style: TextStyle(
                  color: AppColorTokens.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                'Kill = $kKillPoints pt each',
                style: const TextStyle(
                  color: AppColorTokens.primary,
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
                  color: AppColorTokens.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  border: Border.all(color: AppColorTokens.border),
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
      color: AppColorTokens.bgSecondary,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _headerCell('TEAM', _colTeam, TextAlign.left),
            _headerCell('POS', _colPosition, TextAlign.center),
            _headerCell('KILLS', _colKills, TextAlign.center),
            _headerCell('POINTS', _colPoints, TextAlign.center),
            _headerCell('RANK', _colRank, TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String label, double width, TextAlign align) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Text(
          label,
          textAlign: align,
          style: const TextStyle(
            color: AppColorTokens.primary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  // ── Table ──────────────────────────────────────────────────────────────────

  Widget _buildTable(Map<String, String?> leaderNames) {
    _recomputeRanks();

    // Sort by rank for display
    final sorted = List<LeaderboardEntry>.from(_entries)
      ..sort((a, b) => a.rank.compareTo(b.rank));

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: sorted.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, color: AppColorTokens.border),
      itemBuilder: (context, i) {
        final entry = sorted[i];
        final leaderName =
            leaderNames[entry.leaderId] ?? entry.leaderId.substring(0, 6);
        return _LeaderboardRow(
          entry: entry,
          leaderName: leaderName,
          rank: entry.rank,
          onPositionChanged: (v) {
            setState(() {
              entry.position = v;
              _recomputeRanks();
            });
          },
          onKillsChanged: (v) {
            setState(() {
              entry.kills = v;
              _recomputeRanks();
            });
          },
        );
      },
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.groups_outlined,
            color: AppColorTokens.textDisabled,
            size: 56,
          ),
          SizedBox(height: 12),
          Text(
            'No teams registered yet.',
            style: TextStyle(color: AppColorTokens.textSecondary, fontSize: 15),
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
      decoration: const BoxDecoration(
        color: AppColorTokens.bgSecondary,
        border: Border(top: BorderSide(color: AppColorTokens.border)),
      ),
      child: Row(
        children: [
          // Save draft
          Expanded(
            child: _BottomBtn(
              label: 'Save Draft',
              icon: Icons.save_outlined,
              color: AppColorTokens.textSecondary,
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
              color: AppColorTokens.primary,
              loading: _saving,
              onTap: () => _saveLeaderboard(publish: true),
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
  bool _membersExpanded = false;

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
    if (rank == 1) return AppColorTokens.gold;
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return AppColorTokens.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final isTop3 = widget.rank <= 3 && widget.rank > 0;

    return Column(
      children: [
        // ── Main row ────────────────────────────────────────────────────────
        Container(
          color: isTop3
              ? _rankColor(widget.rank).withAlpha(13)
              : Colors.transparent,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Team name + member expand ──────────────────────────────
                SizedBox(
                  width: _colTeam,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => setState(
                            () => _membersExpanded = !_membersExpanded,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.entry.teamName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                _membersExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 14,
                                color: AppColorTokens.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Position (editable) ────────────────────────────────────
                SizedBox(
                  width: _colPosition,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _NumberCell(
                      controller: _posCtrl,
                      hint: '—',
                      onChanged: (v) {
                        final parsed = int.tryParse(v);
                        widget.onPositionChanged(parsed ?? 0);
                      },
                    ),
                  ),
                ),

                // ── Kills (editable) ──────────────────────────────────────
                SizedBox(
                  width: _colKills,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _NumberCell(
                      controller: _killsCtrl,
                      hint: '0',
                      onChanged: (v) {
                        final parsed = int.tryParse(v);
                        widget.onKillsChanged(parsed ?? 0);
                      },
                    ),
                  ),
                ),

                // ── Total points (auto) ────────────────────────────────────
                SizedBox(
                  width: _colPoints,
                  child: Center(
                    child: Text(
                      '${widget.entry.totalPoints}',
                      style: const TextStyle(
                        color: AppColorTokens.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                // ── Rank badge ─────────────────────────────────────────────
                SizedBox(
                  width: _colRank,
                  child: Center(
                    child: widget.rank > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _rankColor(widget.rank).withAlpha(30),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusFull,
                              ),
                              border: Border.all(
                                color: _rankColor(widget.rank).withAlpha(128),
                              ),
                            ),
                            child: Text(
                              '#${widget.rank}',
                              style: TextStyle(
                                color: _rankColor(widget.rank),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : const Text(
                            '—',
                            style: TextStyle(
                              color: AppColorTokens.textDisabled,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Members dropdown ─────────────────────────────────────────────────
        if (_membersExpanded)
          Container(
            width: double.infinity,
            color: AppColorTokens.bgTertiary,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TEAM MEMBERS',
                  style: TextStyle(
                    color: AppColorTokens.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.entry.memberUids.map((uid) {
                    final isLeader = uid == widget.entry.leaderId;
                    return _MemberChip(uid: uid, isLeader: isLeader);
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
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
          hintStyle: const TextStyle(
            color: AppColorTokens.textDisabled,
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          filled: true,
          fillColor: AppColorTokens.bgTertiary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius8),
            borderSide: const BorderSide(color: AppColorTokens.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius8),
            borderSide: const BorderSide(color: AppColorTokens.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius8),
            borderSide: const BorderSide(
              color: AppColorTokens.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Member chip (resolves uid → name) ───────────────────────────────────────
class _MemberChip extends ConsumerWidget {
  final String uid;
  final bool isLeader;

  const _MemberChip({required this.uid, required this.isLeader});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(uid));

    final name = userAsync.maybeWhen(
      data: (u) => u?.name ?? uid.substring(0, 8),
      orElse: () => '…',
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isLeader
            ? AppColorTokens.primary.withAlpha(25)
            : AppColorTokens.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(
          color: isLeader
              ? AppColorTokens.primary.withAlpha(128)
              : AppColorTokens.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLeader) ...[
            const Icon(
              Icons.star_rounded,
              color: AppColorTokens.gold,
              size: 12,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            name,
            style: TextStyle(
              color: isLeader ? AppColorTokens.primary : Colors.white,
              fontSize: 11,
              fontWeight: isLeader ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
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
