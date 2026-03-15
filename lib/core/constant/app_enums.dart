enum UserRole { player, organizer, admin }

enum TournamentStatus {
  draft,
  registrationOpen,
  upcoming,
  live,
  completed,
  cancelled,
}

enum TournamentType { solo, duo, squad }

enum MatchStatus { pending, live, completed }

enum RegistrationStatus { pending, approved, rejected }

enum LoginLoadingState { none, email, google }
