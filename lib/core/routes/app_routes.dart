import 'package:firedrop/features/organizer/dashboard/presentation/screens/tournament_sheet.dart';
import 'package:firedrop/features/leaderboard/presentation/screens/leaderboard_screen.dart';
import 'package:firedrop/features/profile/presentation/screens/profile_screen.dart';
import 'package:firedrop/features/room_creation/presentation/screens/create_room_screen.dart';
import 'package:firedrop/features/room_creation/presentation/screens/join_room_screen.dart';
import 'package:firedrop/shared/models/tournaments_model.dart';
import 'package:firedrop/shared/models/users_model.dart';
import 'package:firedrop/shared/models/video_model.dart';
import 'package:firedrop/features/home/presentation/screen/home_screen.dart';
import 'package:firedrop/features/auth/presentation/screens/login_screen.dart';
import 'package:firedrop/features/organizer/main/organizer_main_shell.dart';
import 'package:firedrop/features/auth/presentation/screens/signup_screen.dart';
import 'package:firedrop/features/splash/splash_screen.dart';
import 'package:firedrop/features/tournament/presentation/screens/tournament_screen.dart';
import 'package:firedrop/features/video/presentation/screens/video_player_screen.dart';
import 'package:firedrop/features/video/presentation/screens/videos_screen.dart';
import 'package:firedrop/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:firedrop/core/routes/route_names.dart';
import 'package:firedrop/core/routes/route_paths.dart';
import 'package:go_router/go_router.dart';

class AppRoutes {
  AppRoutes._();

  static List<GoRoute> routes = [
    GoRoute(
      path: RoutePaths.splash,
      name: RouteNames.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: RoutePaths.login,
      name: RouteNames.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: RoutePaths.signup,
      name: RouteNames.signup,
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: RoutePaths.forgotPassword,
      name: RouteNames.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: RoutePaths.home,
      name: RouteNames.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: RoutePaths.tournamentDetail,
      name: RouteNames.tournamentDetail,
      builder: (context, state) {
        final tournament = state.extra as TournamentModel;
        return TournamentScreen(tournament: tournament);
      },
    ),
    GoRoute(
      path: RoutePaths.createRoom,
      name: RouteNames.createRoom,
      builder: (context, state) {
        final tournament = state.extra as TournamentModel;
        return CreateRoomScreen(tournament: tournament);
      },
    ),
    GoRoute(
      path: RoutePaths.joinRoom,
      name: RouteNames.joinRoom,
      builder: (context, state) {
        final tournament = state.extra as TournamentModel;
        return JoinRoomScreen(tournament: tournament);
      },
    ),
    GoRoute(
      path: RoutePaths.organizerDashboard,
      name: RouteNames.organizerDashboard,
      builder: (context, state) => const OrganizerMainShell(),
    ),
    GoRoute(
      path: RoutePaths.tournamentSheet,
      name: RouteNames.tournamentSheet,
      builder: (context, state) {
        final user = state.extra as UserModel;
        return TournamentSheet(organizerId: user.uid);
      },
    ),
    GoRoute(
      path: RoutePaths.profile,
      name: RouteNames.profile,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: RoutePaths.leaderboard,
      name: RouteNames.leaderboard,
      builder: (context, state) {
        final tournament = state.extra as TournamentModel;
        return LeaderboardScreen(tournament: tournament);
      },
    ),
    GoRoute(
      path: RoutePaths.videoPlayer,
      name: RouteNames.videoPlayer,
      builder: (context, state) {
        final video = state.extra as VideoModel;
        return VideoPlayerScreen(video: video);
      },
    ),
    GoRoute(
      path: RoutePaths.videos,
      name: RouteNames.videos,
      builder: (context, state) => const VideosScreen(),
    ),
  ];
}
