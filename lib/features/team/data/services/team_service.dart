import 'dart:math';
import 'package:firedrop/shared/models/teams_model.dart';
import 'package:firedrop/features/team/data/repositories/team_repository.dart';

class TeamService {
  final TeamRepository _repository;

  TeamService(this._repository);

  String _generateTeamCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  Future<TeamModel> createTeamRoom({
    required String tournamentId,
    required String teamName,
    required String captainId,
    required int maxSlots,
    required String ign,
  }) async {
    final existingTeam = await _repository.getUserTeamForTournament(tournamentId, captainId);
    if (existingTeam != null) {
      throw Exception('You are already registered for this tournament.');
    }

    final currentTeams = await _repository.getTeamsForTournament(tournamentId);
    if (currentTeams.length >= maxSlots) {
      throw Exception('This tournament is already full. No more teams can join.');
    }

    // Generate code
    final code = _generateTeamCode();
    
    final String teamId = 'team_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';

    final team = TeamModel(
      id: teamId,
      tournamentId: tournamentId,
      name: teamName,
      members: [captainId],
      inviteCode: code,
      ign: ign,
      createdAt: DateTime.now(),
      organizerID: captainId,
      updatedAt: DateTime.now(),
    );

    await _repository.createTeam(team);
    return team;
  }

  Future<TeamModel> joinTeamRoom({
    required String tournamentId,
    required String code,
    required String userId,
    required int maxMembers, 
  }) async {
    final existingTeam = await _repository.getUserTeamForTournament(tournamentId, userId);
    if (existingTeam != null) {
      throw Exception('You are already registered for this tournament.');
    }

    final team = await _repository.getTeamByCode(code.trim().toUpperCase());
    
    if (team == null) {
      throw Exception('Team not found for the provided code.');
    }

    if (team.members.contains(userId)) {
      throw Exception('You are already a member of this team.');
    }

    if (team.members.length >= maxMembers) {
      throw Exception('This team is already full.');
    }

    await _repository.addMemberToTeam(team.id, userId);

    return team.copyWith(
      members: [...team.members, userId],
    );
  }

  Future<TeamModel?> getUserTeamForTournament(String tournamentId, String userId) async {
    return _repository.getUserTeamForTournament(tournamentId, userId);
  }

  Future<List<TeamModel>> getUserTeams(String userId) async {
    return _repository.getUserTeams(userId);
  }

  Stream<List<TeamModel>> streamUserTeams(String userId) {
    return _repository.streamUserTeams(userId);
  }
}
