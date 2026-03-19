import 'package:firedrop/core/constant/app_enums.dart';
import 'package:firedrop/core/theme/app_colors.dart';
import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:firedrop/features/auth/presentation/providers/auth_providers.dart';
import 'package:firedrop/features/organizer/tournaments/presentation/widgets/filter_chips.dart';
import 'package:firedrop/features/organizer/tournaments/presentation/widgets/tournament_manage_card.dart';
import 'package:firedrop/features/tournament/presentation/providers/tournament_providers.dart';
import 'package:firedrop/shared/models/tournaments_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrganizerTournamentsScreen extends ConsumerStatefulWidget {
  const OrganizerTournamentsScreen({super.key});

  @override
  ConsumerState<OrganizerTournamentsScreen> createState() =>
      _OrganizerTournamentsScreenState();
}

class _OrganizerTournamentsScreenState
    extends ConsumerState<OrganizerTournamentsScreen> {
  TournamentStatus? _filterStatus;

  Future<void> _changeStatus(
    TournamentModel t,
    TournamentStatus newStatus,
  ) async {
    final service = ref.read(tournamentServiceProvider);
    try {
      switch (newStatus) {
        case TournamentStatus.live:
          await service.startTournament(t);
          break;
        case TournamentStatus.completed:
          await service.completeTournament(t);
          break;
        default:
          break;
      }
      if (mounted) {
        _showSnack('Status updated to ${newStatus.name}', isError: false);
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString(), isError: true);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? AppColorTokens.error
            : AppColorTokens.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final organizer = ref.watch(currentUserProvider).value;
    final uid = organizer?.uid ?? '';
    final tournamentsAsync = ref.watch(organizerTournamentsProvider(uid));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilterChips(
            selected: _filterStatus,
            onChanged: (s) => setState(() => _filterStatus = s),
          ),
          Expanded(
            child: tournamentsAsync.when(
              loading: () => const _TournamentShimmer(),
              error: (e, _) => _ErrorView(message: e.toString()),
              data: (list) {
                final filtered = _filterStatus == null
                    ? list
                    : list.where((t) => t.status == _filterStatus).toList();

                if (filtered.isEmpty) {
                  return const _EmptyView();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.space16,
                    0,
                    AppSizes.space16,
                    100,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => TournamentManageCard(
                    tournament: filtered[i],
                    index: i,
                    onChangeStatus: _changeStatus,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TournamentShimmer extends StatefulWidget {
  const _TournamentShimmer();

  @override
  State<_TournamentShimmer> createState() => _TournamentShimmerState();
}

class _TournamentShimmerState extends State<_TournamentShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(
      begin: -1.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.space16),
      child: Column(
        children: List.generate(
          3,
          (i) => AnimatedBuilder(
            animation: _anim,
            builder: (_, _) => Container(
              height: 200,
              margin: const EdgeInsets.only(bottom: AppSizes.space16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.radius16),
                gradient: LinearGradient(
                  begin: Alignment(_anim.value - 1, 0),
                  end: Alignment(_anim.value, 0),
                  colors: [colorScheme.surface, colorScheme.surface],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.outline),
            ),
            child: Icon(
              Icons.sports_esports_outlined,
              color: colorScheme.onSurface,
              size: 36,
            ),
          ),
          const SizedBox(height: AppSizes.space16),
          const Text(
            'No tournaments found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: AppColorTokens.error,
            size: 40,
          ),
          const SizedBox(height: AppSizes.space16),
          Text(
            message,
            style: const TextStyle(
              color: AppColorTokens.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
