import 'package:firedrop/features/team/presentation/screens/registration_success_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firedrop/core/theme/app_colors.dart';
import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:firedrop/shared/models/tournaments_model.dart';
import 'package:firedrop/features/team/presentation/providers/team_providers.dart';

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class CreateRoomScreen extends ConsumerStatefulWidget {
  final TournamentModel tournament;

  const CreateRoomScreen({super.key, required this.tournament});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final _ignController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _ignController.dispose();
    super.dispose();
  }

  bool _isLoading = false;

  Future<void> _onCreateTeam() async {
    if (_isLoading) return;

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        if (widget.tournament.entryFee > 0) {
          if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
            // Bypass Razorpay for unsupported test platforms
            await _createTeamOnServer();
          } else {
            // _startPayment(widget.tournament.entryFee);
            await _createTeamOnServer();
          }
        } else {
          await _createTeamOnServer();
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createTeamOnServer() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception("User not logged in");

      final team = await ref
          .read(teamServiceProvider)
          .createTeamRoom(
            tournamentId: widget.tournament.id,
            teamName: _teamNameController.text.trim(),
            captainId: userId,
            maxSlots: widget.tournament.maxSlots,
            ign: _ignController.text.trim(),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception(
                "Request timed out. Please check your internet connection.",
              );
            },
          );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RegistrationSuccessScreen(
            tournament: widget.tournament,
            teamName: team.name,
            teamCode: team.inviteCode ?? '',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create team: \${e.toString()}'),
            backgroundColor: AppColorTokens.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColorTokens.bgPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Room',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.space24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Register Your Team for',
                style: const TextStyle(
                  color: AppColorTokens.textSecondary,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.tournament.title,
                style: const TextStyle(
                  color: AppColorTokens.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSizes.space32),

              const Text(
                'Team Name',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _teamNameController,
                hintText: 'e.g., Toxic Avengers',
                prefixIcon: Icons.group_outlined,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Team Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.space24),

              const Text(
                'Captain In-Game Name (IGN)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _ignController,
                hintText: 'e.g., NinjaPro99',
                prefixIcon: Icons.sports_esports_outlined,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'IGN is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.space48),

              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _onCreateTeam,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColorTokens.primaryLight,
                          AppColorTokens.primary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      boxShadow: [
                        BoxShadow(
                          color: AppColorTokens.primary.withAlpha(100),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'CREATE TEAM',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColorTokens.textDisabled),
        prefixIcon: Icon(
          prefixIcon,
          color: AppColorTokens.textSecondary,
          size: 22,
        ),
        filled: true,
        fillColor: AppColorTokens.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          borderSide: const BorderSide(color: AppColorTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          borderSide: const BorderSide(color: AppColorTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          borderSide: const BorderSide(
            color: AppColorTokens.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          borderSide: const BorderSide(color: AppColorTokens.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
      ),
      validator: validator,
    );
  }
}
