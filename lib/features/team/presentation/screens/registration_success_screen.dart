import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:firedrop/core/theme/app_colors.dart';
import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:firedrop/shared/models/tournaments_model.dart';

class RegistrationSuccessScreen extends StatelessWidget {
  final TournamentModel tournament;
  final String teamName;
  final String teamCode;

  const RegistrationSuccessScreen({
    super.key,
    required this.tournament,
    required this.teamName,
    required this.teamCode,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: teamCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Team Code copied to clipboard!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.space24,
            vertical: AppSizes.space32,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.space24),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 80,
                ),
              ),
              const SizedBox(height: AppSizes.space32),
              
              const Text(
                'Registration Successful!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.space16),
              
              Text(
                'You have successfully created the team "$teamName" for ${tournament.title}.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.space48),
              
              Container(
                padding: const EdgeInsets.all(AppSizes.space24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radius16),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withAlpha(30),
                      blurRadius: 20,
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'YOUR TEAM CODE',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSizes.space16),
                    Text(
                      teamCode,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8.0,
                      ),
                    ),
                    const SizedBox(height: AppSizes.space24),
                    TextButton.icon(
                      onPressed: () => _copyToClipboard(context),
                      icon: Icon(Icons.copy, color: Theme.of(context).colorScheme.primary),
                      label: Text(
                        'COPY TEAM CODE',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.space24,
                          vertical: AppSizes.space16,
                        ),
                        backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSizes.space32),
              Text(
                'Share this code with your friends so they can join your team.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // Navigate back to home or dashboard
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                  ),
                  child: Text(
                    'GO TO DASHBOARD',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
