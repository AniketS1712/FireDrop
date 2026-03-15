import 'package:firedrop/models/tournaments_model.dart';
import 'package:firedrop/models/video_model.dart';
import 'package:firedrop/presentation/screens/home_screen.dart';
import 'package:firedrop/presentation/screens/login_screen.dart';
import 'package:firedrop/presentation/screens/organizer_dashboard_screen.dart';
import 'package:firedrop/presentation/screens/signup_screen.dart';
import 'package:firedrop/presentation/screens/splash_screen.dart';
import 'package:firedrop/presentation/screens/tournament_screen.dart';
import 'package:firedrop/presentation/screens/video_player_screen.dart';
import 'package:firedrop/presentation/screens/forgot_password_screen.dart';
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
      path: RoutePaths.organizerDashboard,
      name: RouteNames.organizerDashboard,
      builder: (context, state) => const OrganizerDashboardScreen(),
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
      path: RoutePaths.forgotPassword,
      name: RouteNames.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
  ];
}
