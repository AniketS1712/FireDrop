import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firedrop/core/theme/app_sizes.dart';
import 'package:firedrop/shared/models/tournaments_model.dart';
import 'package:firedrop/features/team/presentation/providers/team_providers.dart';

/// ─── Join Room Screen ──────────────────────────────────────────────────────
/// Allows a user to join an existing team room using a 6-character invite code.
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
  void dispose() {
    _teamCodeController.dispose();
    super.dispose();
  }

  // ═══════════════════════ MAIN ACTION ═══════════════════════

  Future<void> _onJoinTeam() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _joinTeamOnServer();
    } catch (e) {
      _handleError(e.toString());
    }
  }

  // ═══════════════════════ JOIN TEAM ═══════════════════════

  Future<void> _joinTeamOnServer() async {
    final String code = _teamCodeController.text.trim();

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

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

      final team = await ref
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
                'Request timed out. Please check your internet connection.',
              );
            },
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully joined team "${team.name}"!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join team: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ═══════════════════════ ERROR HANDLING ═══════════════════════

  void _handleError(String error) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'RETRY',
          textColor: Colors.white,
          onPressed: _onJoinTeam,
        ),
      ),
    );
  }

  // ═══════════════════════ BUILD ═══════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
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
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSizes.space8),
              Text(
                'Enter the 6-character team code provided by your captain to join their room.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: AppSizes.space48),

              Text(
                'TEAM CODE',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _buildCodeTextField(),

              const SizedBox(height: AppSizes.space48),

              // ── Join Team Button ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _isLoading ? null : _onJoinTeam,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isLoading
                            ? [
                                Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer
                                    .withAlpha(150),
                                Theme.of(
                                  context,
                                ).colorScheme.secondary.withAlpha(150),
                              ]
                            : [
                                Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                                Theme.of(context).colorScheme.secondary,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      boxShadow: _isLoading
                          ? []
                          : [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondary.withAlpha(100),
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

  // ═══════════════════════ CODE TEXT FIELD ═══════════════════════

  Widget _buildCodeTextField() {
    return TextFormField(
      controller: _teamCodeController,
      enabled: !_isLoading,
      textCapitalization: TextCapitalization.characters,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: 8.0,
      ),
      decoration: InputDecoration(
        hintText: 'XXXXXX',
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary.withAlpha(50),
        ),
        prefixIcon: Icon(
          Icons.vpn_key_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
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
