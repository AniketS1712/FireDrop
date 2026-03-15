import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firedrop/core/constant/app_enums.dart';
import 'package:firedrop/models/tournaments_model.dart';

class TournamentRepository {
  TournamentRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collection = 'tournaments';

  CollectionReference<Map<String, dynamic>> get _tournaments =>
      _firestore.collection(_collection);

  // ================= CREATE =================

  Future<void> createTournament(TournamentModel tournament) async {
    await _tournaments.doc(tournament.id).set(tournament.toMap());
  }

  // ================= GET SINGLE =================

  Future<TournamentModel?> getTournamentById(String id) async {
    final doc = await _tournaments.doc(id).get();

    if (!doc.exists) return null;

    return TournamentModel.fromMap(doc.data()!, doc.id);
  }

  // ================= GET ALL UPCOMING =================

  Future<List<TournamentModel>> getUpcomingTournaments() async {
    final query = await _tournaments
        .where('status', isEqualTo: TournamentStatus.upcoming.name)
        .get();

    return query.docs
        .map((doc) => TournamentModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ================= STREAM LIVE TOURNAMENTS =================

  Stream<List<TournamentModel>> streamLiveTournaments() {
    return _tournaments
        .where('status', isEqualTo: TournamentStatus.live.name)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TournamentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // ================= STREAM PUBLIC TOURNAMENTS =================

  Stream<List<TournamentModel>> streamPublicTournaments() {
    return _tournaments
        .where(
          'status',
          whereIn: [
            TournamentStatus.registrationOpen.name,
            TournamentStatus.upcoming.name,
            TournamentStatus.live.name,
          ],
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TournamentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // ================= UPDATE =================

  Future<void> updateTournament(TournamentModel tournament) async {
    await _tournaments.doc(tournament.id).update(tournament.toMap());
  }

  // ================= STREAM BY ORGANIZER =================

  Stream<List<TournamentModel>> streamByOrganizer(String organizerId) {
    return _tournaments
        .where('organizerId', isEqualTo: organizerId)
        .snapshots()
        .map(
          (snapshot) {
            final list = snapshot.docs
                .map((doc) => TournamentModel.fromMap(doc.data(), doc.id))
                .toList();
            list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return list;
          },
        );
  }

  // ================= AUTO-TRANSITION TO LIVE =================

  /// Transitions a tournament whose startTime has passed to [TournamentStatus.live].
  /// Only updates the `status` field — no full document overwrite.
  Future<void> autoTransitionToLive(String tournamentId) async {
    await _tournaments.doc(tournamentId).update({
      'status': TournamentStatus.live.name,
    });
  }

  // ================= DELETE =================

  Future<void> deleteTournament(String id) async {
    await _tournaments.doc(id).delete();
  }
}
