import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firedrop/core/theme/app_colors.dart';
import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:firedrop/shared/models/tournaments_model.dart';
import 'package:firedrop/features/team/presentation/providers/team_providers.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class JoinRoomScreen extends ConsumerStatefulWidget {
  final TournamentModel tournament;

  const JoinRoomScreen({super.key, required this.tournament});

  @override
  ConsumerState<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends ConsumerState<JoinRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _teamCodeController.dispose();
    super.dispose();
  }

  Future<void> _onJoinTeam() async {
    if (_isLoading) return;

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        if (widget.tournament.entryFee > 0) {
          if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
            // Bypass Razorpay for unsupported test platforms
            await _joinTeamOnServer();
          } else {
            // _startPayment(widget.tournament.entryFee);
            await _joinTeamOnServer();
          }
        } else {
          await _joinTeamOnServer();
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _joinTeamOnServer() async {
    final String code = _teamCodeController.text.trim();

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception("User not logged in");

      int maxMembers = 4;
      switch (widget.tournament.gameMode) {
        case GameMode.solo:
          maxMembers = 1;
          break;
        case GameMode.duo:
          maxMembers = 2;
          break;
        case GameMode.squad:
          maxMembers = 4;
          break;
      }

      await ref
          .read(teamServiceProvider)
          .joinTeamRoom(
            tournamentId: widget.tournament.id,
            code: code,
            userId: userId,
            maxMembers: maxMembers,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully joined via code: $code!'),
          backgroundColor: AppColorTokens.success,
        ),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join team: \${e.toString()}'),
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
          'Join Room',
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
                'Join ${widget.tournament.title}',
                style: const TextStyle(
                  color: AppColorTokens.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSizes.space8),
              const Text(
                'Enter the 6-character team code provided by your captain to join their room.',
                style: TextStyle(
                  color: AppColorTokens.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSizes.space48),

              const Text(
                'TEAM CODE',
                style: TextStyle(
                  color: AppColorTokens.textSecondary,
                  fontSize: 11,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _buildCodeTextField(),

              const SizedBox(height: AppSizes.space48),

              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _onJoinTeam,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColorTokens.secondaryLight,
                          AppColorTokens.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      boxShadow: [
                        BoxShadow(
                          color: AppColorTokens.secondary.withAlpha(100),
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
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'JOIN TEAM',
                            style: TextStyle(
                              color: Colors.white,
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

  Widget _buildCodeTextField() {
    return TextFormField(
      controller: _teamCodeController,
      textCapitalization: TextCapitalization.characters,
      style: const TextStyle(
        color: AppColorTokens.primary,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: 8.0,
      ),
      decoration: InputDecoration(
        hintText: 'XXXXXX',
        hintStyle: TextStyle(color: AppColorTokens.primary.withAlpha(50)),
        prefixIcon: const Icon(
          Icons.vpn_key_outlined,
          color: AppColorTokens.primary,
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
          borderSide: const BorderSide(color: AppColorTokens.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          borderSide: const BorderSide(color: AppColorTokens.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 24,
          horizontal: 20,
        ),
      ),
      maxLength: 6,
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Team Code is required';
        }
        if (val.trim().length != 6) {
          return 'Code must be exactly 6 characters';
        }
        return null;
      },
    );
  }
}
