import 'package:eagle_esports/core/constant/app_enums.dart';
import 'package:eagle_esports/shared/models/tournaments_model.dart';
import 'package:eagle_esports/features/tournament/data/repositories/tournament_repository.dart';
import 'package:uuid/uuid.dart';

class TournamentService {
  TournamentService(this._repository);

  final TournamentRepository _repository;

  final _uuid = const Uuid();

  // ================= CREATE TOURNAMENT =================

  Future<void> createTournament({
    required String title,
    required String description,
    required String imageUrl,
    required GameMode gameMode,
    required int entryFee,
    required PrizeDistribution prizeDistribution,
    required int maxSlots,
    required String organizerId,
    required DateTime startTime,
    required String rulesText,
  }) async {
    _validateTournamentInput(
      title: title,
      entryFee: entryFee,
      maxSlots: maxSlots,
      prizeDistribution: prizeDistribution,
    );

    final prizePool =
        prizeDistribution.first +
        prizeDistribution.second +
        prizeDistribution.third;

    final tournament = TournamentModel(
      id: _uuid.v4(),
      title: title,
      description: description,
      imageUrl: imageUrl,
      gameMode: gameMode,
      entryFee: entryFee,
      prizePool: prizePool,
      prizeDistribution: prizeDistribution,
      maxSlots: maxSlots,
      organizerId: organizerId,
      status: TournamentStatus.upcoming,
      startTime: startTime,
      rulesText: rulesText,
      roomDetails: null,
      createdAt: DateTime.now(),
    );

    await _repository.createTournament(tournament);
  }

  // ================= GET UPCOMING =================

  Future<List<TournamentModel>> getUpcomingTournaments() {
    return _repository.getUpcomingTournaments();
  }

  // ================= STREAM LIVE =================

  Stream<List<TournamentModel>> streamLiveTournaments() {
    return _repository.streamLiveTournaments();
  }

  // ================= STREAM PUBLIC =================

  Stream<List<TournamentModel>> streamPublicTournaments() {
    return _repository.streamPublicTournaments();
  }

  // ================= STREAM BY ORGANIZER =================

  Stream<List<TournamentModel>> streamByOrganizer(String organizerId) {
    return _repository.streamByOrganizer(organizerId);
  }

  // ================= START TOURNAMENT =================

  Future<void> startTournament(TournamentModel tournament) async {
    if (tournament.status != TournamentStatus.upcoming) {
      throw Exception('Only upcoming tournaments can be started.');
    }

    await _repository.updateTournament(
      tournament.copyWith(status: TournamentStatus.live),
    );
  }

  // ================= COMPLETE TOURNAMENT =================

  Future<void> completeTournament(TournamentModel tournament) async {
    if (tournament.status != TournamentStatus.live) {
      throw Exception('Only live tournaments can be completed.');
    }

    await _repository.updateTournament(
      tournament.copyWith(status: TournamentStatus.completed),
    );
  }

  // ================= AUTO-TRANSITION TO LIVE =================

  /// Called by the background sync provider.
  /// Transitions a tournament to live when its startTime has elapsed.
  Future<void> autoTransitionToLive(String tournamentId) {
    return _repository.autoTransitionToLive(tournamentId);
  }

  // ================= UPDATE ROOM DETAILS =================

  Future<void> updateRoomDetails(
    String tournamentId,
    RoomDetails? details,
  ) async {
    final tournament = await _repository.getTournamentById(tournamentId);
    if (tournament == null) throw Exception('Tournament not found.');

    await _repository.updateTournament(
      tournament.copyWith(roomDetails: details),
    );
  }

  // ================= VALIDATION =================

  void _validateTournamentInput({
    required String title,
    required int entryFee,
    required int maxSlots,
    required PrizeDistribution prizeDistribution,
  }) {
    if (title.trim().isEmpty) {
      throw Exception('Tournament title cannot be empty.');
    }

    if (entryFee < 0) {
      throw Exception('Entry fee cannot be negative.');
    }

    if (maxSlots <= 0) {
      throw Exception('Max slots must be greater than zero.');
    }

    final totalPrize =
        prizeDistribution.first +
        prizeDistribution.second +
        prizeDistribution.third;

    if (totalPrize <= 0) {
      throw Exception('Prize pool must be greater than zero.');
    }
  }
}
