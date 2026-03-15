import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firedrop/models/teams_model.dart';

class TeamRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _teams => _firestore.collection('teams');

  Future<void> createTeam(TeamModel team) async {
    await _teams.doc(team.id).set(team.toMap());
  }

  Future<TeamModel?> getTeamByCode(String code) async {
    final snapshot = await _teams.where('inviteCode', isEqualTo: code).get();
    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      return TeamModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<List<TeamModel>> getTeamsForTournament(String tournamentId) async {
    final snapshot = await _teams.where('tournamentId', isEqualTo: tournamentId).get();
    return snapshot.docs.map((doc) => TeamModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<void> addMemberToTeam(String teamId, String userId) async {
    await _teams.doc(teamId).update({
      'members': FieldValue.arrayUnion([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<TeamModel?> getUserTeamForTournament(String tournamentId, String userId) async {
    final snapshot = await _teams
        .where('tournamentId', isEqualTo: tournamentId)
        .where('members', arrayContains: userId)
        .get();
        
    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      return TeamModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<List<TeamModel>> getUserTeams(String userId) async {
    final snapshot = await _teams
        .where('members', arrayContains: userId)
        .get();
        
    return snapshot.docs
        .map((doc) => TeamModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Stream<List<TeamModel>> streamUserTeams(String userId) {
    return _teams
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TeamModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
