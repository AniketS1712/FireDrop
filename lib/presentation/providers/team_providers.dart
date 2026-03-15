import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firedrop/repositories/team_repository.dart';
import 'package:firedrop/services/team_service.dart';
import 'package:firedrop/models/teams_model.dart';
import 'package:firedrop/presentation/providers/auth_providers.dart';

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return TeamRepository();
});

final teamServiceProvider = Provider<TeamService>((ref) {
  final repo = ref.watch(teamRepositoryProvider);
  return TeamService(repo);
});

final userTeamForTournamentProvider = 
  StreamProvider.family<TeamModel?, String>((ref, tournamentId) async* {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) {
      yield null;
      return;
    }
    
    // Instead of querying by ID, we compute it synchronously from our existing stream
    final userTeams = ref.watch(userJoinedTeamsProvider).value ?? [];
    try {
      yield userTeams.firstWhere((t) => t.tournamentId == tournamentId);
    } catch (e) {
      yield null; // not found
    }
  });

final userJoinedTeamsProvider = 
  StreamProvider<List<TeamModel>>((ref) async* {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) {
      yield [];
      return;
    }
    final service = ref.watch(teamServiceProvider);
    yield* service.streamUserTeams(user.uid);
  });
