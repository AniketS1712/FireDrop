import 'package:eagle_esports/core/constant/app_enums.dart';
import 'package:eagle_esports/features/auth/presentation/providers/auth_providers.dart';
import 'package:eagle_esports/features/tournament/presentation/widgets/filter_chips.dart';
import 'package:eagle_esports/features/tournament/presentation/widgets/tournament_manage_card.dart';
import 'package:eagle_esports/features/tournament/presentation/widgets/tournament_shimmer.dart';
import 'package:eagle_esports/features/tournament/presentation/widgets/tournament_empty_view.dart';
import 'package:eagle_esports/features/tournament/presentation/widgets/tournament_error_view.dart';
import 'package:eagle_esports/features/tournament/presentation/providers/tournament_providers.dart';
import 'package:eagle_esports/shared/models/tournaments_model.dart';
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
  TournamentStatus? _filterStatus = TournamentStatus.live;

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
        _showSnack(
          'Status updated to ${newStatus.name.toUpperCase()}',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString(), isError: true);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUserProvider).value?.uid ?? '';
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
              loading: () => const TournamentShimmer(),
              error: (e, _) => TournamentErrorView(
                message: e.toString(),
                onRetry: () =>
                    ref.invalidate(organizerTournamentsProvider(uid)),
              ),
              data: (list) {
                final filtered = _filterStatus == null
                    ? list
                    : list.where((t) => t.status == _filterStatus).toList();

                if (filtered.isEmpty) {
                  return const TournamentEmptyView();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  physics: const BouncingScrollPhysics(),
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
