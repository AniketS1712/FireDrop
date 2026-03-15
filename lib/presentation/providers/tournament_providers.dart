import 'package:firedrop/models/tournaments_model.dart';
import 'package:firedrop/repositories/tournament_repository.dart';
import 'package:firedrop/services/tournament_service.dart';
import 'package:firedrop/core/constant/app_enums.dart';
import 'package:firedrop/presentation/providers/team_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ================= FILTERS =================

enum TournamentFilter { joined, upcoming, live }

enum GameModeFilter { all, solo, duo, squad }

class TournamentFilterNotifier extends Notifier<TournamentFilter> {
  @override
  TournamentFilter build() => TournamentFilter.upcoming;
  void setFilter(TournamentFilter filter) => state = filter;
}

final tournamentFilterProvider =
    NotifierProvider<TournamentFilterNotifier, TournamentFilter>(
      () => TournamentFilterNotifier(),
    );

class GameModeFilterNotifier extends Notifier<GameModeFilter> {
  @override
  GameModeFilter build() => GameModeFilter.all;
  void setFilter(GameModeFilter filter) => state = filter;
}

final gameModeFilterProvider =
    NotifierProvider<GameModeFilterNotifier, GameModeFilter>(
      () => GameModeFilterNotifier(),
    );

// ================= REPOSITORY =================

final tournamentRepositoryProvider = Provider<TournamentRepository>((ref) {
  return TournamentRepository();
});

// ================= SERVICE =================

final tournamentServiceProvider = Provider<TournamentService>((ref) {
  final repo = ref.watch(tournamentRepositoryProvider);
  return TournamentService(repo);
});

// ================= PUBLIC TOURNAMENTS =================

final publicTournamentsProvider = StreamProvider<List<TournamentModel>>((ref) {
  final service = ref.watch(tournamentServiceProvider);
  return service.streamPublicTournaments();
});

// ================= FILTERED TOURNAMENTS =================

final filteredTournamentsProvider = Provider<AsyncValue<List<TournamentModel>>>(
  (ref) {
    final publicAsync = ref.watch(publicTournamentsProvider);
    final statusFilter = ref.watch(tournamentFilterProvider);
    final modeFilter = ref.watch(gameModeFilterProvider);
    final joinedTeamsAsync = ref.watch(userJoinedTeamsProvider);

    return publicAsync.whenData((tournaments) {
      final joinedTournamentIds = joinedTeamsAsync.value?.map((t) => t.tournamentId).toSet() ?? {};

      return tournaments.where((t) {
        // 1. Status Filter
        bool statusMatches = false;
        switch (statusFilter) {
          case TournamentFilter.joined:
            statusMatches = joinedTournamentIds.contains(t.id);
            break;
          case TournamentFilter.upcoming:
            statusMatches =
                (t.status == TournamentStatus.upcoming ||
                 t.status == TournamentStatus.registrationOpen) &&
                !joinedTournamentIds.contains(t.id);
            break;
          case TournamentFilter.live:
            statusMatches = t.status == TournamentStatus.live;
            break;
        }

        // 2. Game Mode Filter
        bool modeMatches = false;
        if (modeFilter == GameModeFilter.all) {
          modeMatches = true;
        } else {
          modeMatches = t.gameMode.name == modeFilter.name;
        }

        return statusMatches && modeMatches;
      }).toList();
    });
  },
);

// ================= ORGANIZER TOURNAMENTS =================

final organizerTournamentsProvider =
    StreamProvider.family<List<TournamentModel>, String>((ref, organizerId) {
      final service = ref.watch(tournamentServiceProvider);
      return service.streamByOrganizer(organizerId);
    });

// ================= STATUS AUTO-SYNC =================

/// Background provider that watches live public tournaments and automatically
/// transitions any tournament from [upcoming / registrationOpen] → [live]
/// once its [startTime] has elapsed.
///
/// Wire this in a long-lived widget with [ref.listen] or [ref.watch] so the
/// stream stays active while the user is in the app.
final tournamentStatusSyncProvider = StreamProvider<void>((ref) async* {
  final service = ref.watch(tournamentServiceProvider);
  final publicStream = service.streamPublicTournaments();

  // Track IDs that already have an in-flight transition to avoid duplicate writes.
  final transitioning = <String>{};

  await for (final tournaments in publicStream) {
    final now = DateTime.now();
    for (final t in tournaments) {
      final shouldTransition =
          (t.status == TournamentStatus.upcoming ||
              t.status == TournamentStatus.registrationOpen) &&
          !t.startTime.isAfter(now) &&
          !transitioning.contains(t.id);

      if (shouldTransition) {
        transitioning.add(t.id);
        service.autoTransitionToLive(t.id).then((value) {
          transitioning.remove(t.id);
        }).catchError((e) {
          transitioning.remove(t.id);
          // Silently ignore — the stream will retry on next emission.
        });
      }
    }
  }
});
