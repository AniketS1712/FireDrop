import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eagle_esports/core/theme/app_sizes.dart';
import 'package:eagle_esports/shared/models/tournaments_model.dart';
import 'package:eagle_esports/shared/models/teams_model.dart';
import 'package:eagle_esports/shared/models/users_model.dart';
import 'package:eagle_esports/features/auth/presentation/providers/auth_providers.dart';
import 'package:eagle_esports/features/video/data/repositories/upload_repository.dart';

class MyTeamScreen extends ConsumerStatefulWidget {
  final TournamentModel tournament;
  final TeamModel team;

  const MyTeamScreen({super.key, required this.tournament, required this.team});

  @override
  ConsumerState<MyTeamScreen> createState() => _MyTeamScreenState();
}

class _MyTeamScreenState extends ConsumerState<MyTeamScreen> {
  final Map<String, UserModel> _membersDetails = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMembersDetails();
  }

  Future<void> _fetchMembersDetails() async {
    final authService = ref.read(authServiceProvider);

    for (String memberId in widget.team.members) {
      final user = await authService.getUserById(memberId);
      if (user != null) {
        _membersDetails[memberId] = user;
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'My Team',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEventHeader(context),
                  const SizedBox(height: AppSizes.space32),
                  _buildTeamDetails(context),
                  const SizedBox(height: AppSizes.space32),
                  Text(
                    'TEAM MEMBERS',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: AppSizes.space16),
                  ...widget.team.members.map((memberId) {
                    return _buildMemberCard(context, memberId);
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildEventHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.space24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: Text(
              'REGISTERED EVENT',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.space16),
          Text(
            widget.tournament.title,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSizes.space8),
          Text(
            widget.tournament.gameMode.name.toUpperCase(),
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamDetails(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TEAM NAME',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.team.name,
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        if (widget.team.inviteCode != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.space16,
              vertical: AppSizes.space8,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppSizes.radius16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                Text(
                  'JOIN CODE',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.team.inviteCode!,
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Monospace',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMemberCard(BuildContext context, String memberId) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final member = _membersDetails[memberId];
    final isCaptain = memberId == widget.team.organizerID;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.space12),
      padding: const EdgeInsets.all(AppSizes.space16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        border: Border.all(
          color: isCaptain ? colorScheme.primary : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.surface,
            backgroundImage: member != null && member.avatarUrl.isNotEmpty
                ? (UploadRepository.isBase64Avatar(member.avatarUrl)
                      ? MemoryImage(
                          UploadRepository.decodeBase64Avatar(member.avatarUrl),
                        )
                      : NetworkImage(member.avatarUrl) as ImageProvider)
                : null,
            child: member == null || member.avatarUrl.isEmpty
                ? Icon(Icons.person, color: colorScheme.primary)
                : null,
          ),
          const SizedBox(width: AppSizes.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member?.name ?? 'Loading...',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isCaptain)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'CAPTAIN',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        fontSize: 10,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'PLAYER',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
