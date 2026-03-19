import 'package:firedrop/features/tournament/presentation/providers/tournament_providers.dart';
import 'package:firedrop/shared/models/tournaments_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firedrop/core/theme/app_colors.dart';
import 'package:firedrop/core/theme/app_sizes.dart';

// ─── Public Entry Point ───────────────────────────────────────────────────────
class TournamentSheet extends ConsumerStatefulWidget {
  final String organizerId;
  const TournamentSheet({super.key, required this.organizerId});

  @override
  ConsumerState<TournamentSheet> createState() => _TournamentSheetState();
}

class _TournamentSheetState extends ConsumerState<TournamentSheet>
    with SingleTickerProviderStateMixin {
  // ── Step tracking ─────────────────────────────────────────────────────────
  // 0 = template picker, 1 = form, 2 = preview
  int _step = 0;

  // ── Form state ────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _scrollCtrl = ScrollController();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _rulesCtrl = TextEditingController();
  final _entryFeeCtrl = TextEditingController(text: '0');
  final _maxSlotsCtrl = TextEditingController(text: '100');
  final _prize1Ctrl = TextEditingController();
  final _prize2Ctrl = TextEditingController();
  final _prize3Ctrl = TextEditingController();

  GameMode _gameMode = GameMode.squad;
  DateTime _startTime = DateTime.now().add(const Duration(hours: 2));
  bool _submitting = false;

  // ── Step animation ────────────────────────────────────────────────────────
  late final AnimationController _stepAnim;
  late final Animation<double> _stepFade;

  @override
  void initState() {
    super.initState();
    _stepAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
    _stepFade = CurvedAnimation(parent: _stepAnim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _stepAnim.dispose();
    _scrollCtrl.dispose();
    for (final c in [
      _titleCtrl,
      _descCtrl,
      _imageCtrl,
      _rulesCtrl,
      _entryFeeCtrl,
      _maxSlotsCtrl,
      _prize1Ctrl,
      _prize2Ctrl,
      _prize3Ctrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Navigation ────────────────────────────────────────────────────────────
  void _goTo(int step) {
    _stepAnim.reset();
    setState(() => _step = step);
    _stepAnim.forward();
  }

  void _applyTemplate(TournamentModel t) {
    _titleCtrl.text = t.title;
    _descCtrl.text = t.description;
    _imageCtrl.text = t.imageUrl;
    _rulesCtrl.text = t.rulesText;
    _entryFeeCtrl.text = t.entryFee.toString();
    _maxSlotsCtrl.text = t.maxSlots.toString();
    _prize1Ctrl.text = t.prizeDistribution.first.toString();
    _prize2Ctrl.text = t.prizeDistribution.second.toString();
    _prize3Ctrl.text = t.prizeDistribution.third.toString();
    setState(() {
      _gameMode = t.gameMode;
      // Keep a fresh start time (don't copy old one)
      _startTime = DateTime.now().add(const Duration(hours: 2));
    });
    _goTo(1);
  }

  void _onPreview() {
    if (_formKey.currentState!.validate()) {
      _goTo(2);
    }
  }

  // ── Submission ────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final service = ref.read(tournamentServiceProvider);
      await service.createTournament(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        imageUrl: _imageCtrl.text.trim(),
        gameMode: _gameMode,
        entryFee: int.tryParse(_entryFeeCtrl.text) ?? 0,
        prizeDistribution: PrizeDistribution(
          first: int.tryParse(_prize1Ctrl.text) ?? 0,
          second: int.tryParse(_prize2Ctrl.text) ?? 0,
          third: int.tryParse(_prize3Ctrl.text) ?? 0,
        ),
        maxSlots: int.tryParse(_maxSlotsCtrl.text) ?? 100,
        organizerId: widget.organizerId,
        startTime: _startTime,
        rulesText: _rulesCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tournament created successfully! 🎉'),
            backgroundColor: AppColorTokens.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColorTokens.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── UI helpers ────────────────────────────────────────────────────────────
  Widget themeData(BuildContext ctx, Widget? child) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: AppColorTokens.primary,
          onPrimary: Colors.black,
          surface: AppColorTokens.surfaceElevated,
          onSurface: Colors.white,
        ),
      ),
      child: child!,
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: themeData,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime),
      builder: themeData,
    );
    if (time == null || !mounted) return;
    setState(() {
      _startTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String get _stepTitle => switch (_step) {
    0 => 'Start From Template',
    1 => 'New Tournament',
    _ => 'Review Details',
  };

  String get _stepSubtitle => switch (_step) {
    0 => 'Pick any past tournament as a starting point, or start fresh',
    1 => 'Fill in the details for your tournament',
    _ => 'Confirm everything before going live',
  };

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColorTokens.bgSecondary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(bottom: bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ──
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColorTokens.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // ── Title bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.space16,
                AppSizes.space8,
                AppSizes.space16,
                0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    height: 22,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: AppColorTokens.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _stepTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _stepSubtitle,
                          style: const TextStyle(
                            color: AppColorTokens.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.close,
                      color: AppColorTokens.textSecondary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ── Step indicator ──
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.space16,
                vertical: AppSizes.space12,
              ),
              child: Row(
                children: [
                  _StepDot(active: _step >= 0, index: 1, label: 'Template'),
                  _StepLine(active: _step >= 1),
                  _StepDot(active: _step >= 1, index: 2, label: 'Details'),
                  _StepLine(active: _step >= 2),
                  _StepDot(active: _step >= 2, index: 3, label: 'Preview'),
                ],
              ),
            ),

            // ── Body (animated) ──
            Flexible(
              child: FadeTransition(
                opacity: _stepFade,
                child: switch (_step) {
                  0 => _TemplatePicker(
                    organizerId: widget.organizerId,
                    onSelect: _applyTemplate,
                    onSkip: () => _goTo(1),
                  ),
                  1 => _TournamentForm(
                    formKey: _formKey,
                    scrollCtrl: _scrollCtrl,
                    titleCtrl: _titleCtrl,
                    descCtrl: _descCtrl,
                    imageCtrl: _imageCtrl,
                    rulesCtrl: _rulesCtrl,
                    entryFeeCtrl: _entryFeeCtrl,
                    maxSlotsCtrl: _maxSlotsCtrl,
                    prize1Ctrl: _prize1Ctrl,
                    prize2Ctrl: _prize2Ctrl,
                    prize3Ctrl: _prize3Ctrl,
                    gameMode: _gameMode,
                    startTime: _startTime,
                    onGameModeChanged: (m) => setState(() => _gameMode = m),
                    onPickDateTime: _pickDateTime,
                    onPreview: _onPreview,
                    themeData: themeData,
                  ),
                  _ => _TournamentPreview(
                    title: _titleCtrl.text.trim(),
                    description: _descCtrl.text.trim(),
                    imageUrl: _imageCtrl.text.trim(),
                    gameMode: _gameMode,
                    entryFee: int.tryParse(_entryFeeCtrl.text) ?? 0,
                    prize1: int.tryParse(_prize1Ctrl.text) ?? 0,
                    prize2: int.tryParse(_prize2Ctrl.text) ?? 0,
                    prize3: int.tryParse(_prize3Ctrl.text) ?? 0,
                    maxSlots: int.tryParse(_maxSlotsCtrl.text) ?? 100,
                    startTime: _startTime,
                    rulesText: _rulesCtrl.text.trim(),
                    submitting: _submitting,
                    onEdit: () => _goTo(1),
                    onConfirm: _submit,
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step indicator widgets ───────────────────────────────────────────────────
class _StepDot extends StatelessWidget {
  final bool active;
  final int index;
  final String label;
  const _StepDot({
    required this.active,
    required this.index,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColorTokens.primary : AppColorTokens.surface,
            border: Border.all(
              color: active ? AppColorTokens.primary : AppColorTokens.border,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              '$index',
              style: TextStyle(
                color: active ? Colors.black : AppColorTokens.textDisabled,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: active
                ? AppColorTokens.primary
                : AppColorTokens.textDisabled,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool active;
  const _StepLine({required this.active});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 1.5,
          color: active ? AppColorTokens.primary : AppColorTokens.border,
        ),
      ),
    );
  }
}

// ─── Step 1 — Template Picker ─────────────────────────────────────────────────
class _TemplatePicker extends ConsumerWidget {
  final String organizerId;
  final void Function(TournamentModel) onSelect;
  final VoidCallback onSkip;

  const _TemplatePicker({
    required this.organizerId,
    required this.onSelect,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentsAsync = ref.watch(
      organizerTournamentsProvider(organizerId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Skip option
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.space16,
            0,
            AppSizes.space16,
            0,
          ),
          child: GestureDetector(
            onTap: onSkip,
            child: Container(
              padding: const EdgeInsets.all(AppSizes.space12),
              decoration: BoxDecoration(
                color: AppColorTokens.surface,
                borderRadius: BorderRadius.circular(AppSizes.radius16),
                border: Border.all(
                  color: AppColorTokens.primary.withAlpha(70),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColorTokens.primary.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppColorTokens.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSizes.space12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Fresh',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Create a new tournament from scratch',
                          style: TextStyle(
                            color: AppColorTokens.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColorTokens.primary,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.space16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.space16),
          child: Text(
            'Or copy from a past tournament',
            style: TextStyle(
              color: AppColorTokens.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.space8),
        Flexible(
          child: tournamentsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSizes.space32),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColorTokens.primary,
                  strokeWidth: 2,
                ),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(AppSizes.space32),
              child: Center(
                child: Text(
                  'Could not load past tournaments',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
            ),
            data: (list) {
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(AppSizes.space32),
                  child: Center(
                    child: Text(
                      'No past tournaments to copy from',
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.space16,
                  0,
                  AppSizes.space16,
                  AppSizes.space24,
                ),
                itemCount: list.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSizes.space8),
                itemBuilder: (context, i) =>
                    _TemplateItem(tournament: list[i], onTap: onSelect),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TemplateItem extends StatelessWidget {
  final TournamentModel tournament;
  final void Function(TournamentModel) onTap;

  const _TemplateItem({required this.tournament, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    return GestureDetector(
      onTap: () => onTap(t),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.space12),
        decoration: BoxDecoration(
          color: AppColorTokens.surface,
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          border: Border.all(color: AppColorTokens.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radius8),
              child: Image.network(
                t.imageUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 56,
                  height: 56,
                  color: AppColorTokens.bgTertiary,
                  child: const Icon(
                    Icons.sports_esports,
                    color: AppColorTokens.textDisabled,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _Tag(
                        t.gameMode.name.toUpperCase(),
                        AppColorTokens.primary,
                      ),
                      const SizedBox(width: 6),
                      _Tag('₹${t.entryFee} Entry', AppColorTokens.secondary),
                      const SizedBox(width: 6),
                      _Tag('${t.maxSlots} slots', Colors.white30),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.space8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColorTokens.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                border: Border.all(color: AppColorTokens.primary.withAlpha(80)),
              ),
              child: const Text(
                'Use',
                style: TextStyle(
                  color: AppColorTokens.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Step 2 — Tournament Form ─────────────────────────────────────────────────
class _TournamentForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final ScrollController scrollCtrl;
  final TextEditingController titleCtrl,
      descCtrl,
      imageCtrl,
      rulesCtrl,
      entryFeeCtrl,
      maxSlotsCtrl,
      prize1Ctrl,
      prize2Ctrl,
      prize3Ctrl;
  final GameMode gameMode;
  final DateTime startTime;
  final void Function(GameMode) onGameModeChanged;
  final VoidCallback onPickDateTime;
  final VoidCallback onPreview;
  final Widget Function(BuildContext, Widget?) themeData;

  const _TournamentForm({
    required this.formKey,
    required this.scrollCtrl,
    required this.titleCtrl,
    required this.descCtrl,
    required this.imageCtrl,
    required this.rulesCtrl,
    required this.entryFeeCtrl,
    required this.maxSlotsCtrl,
    required this.prize1Ctrl,
    required this.prize2Ctrl,
    required this.prize3Ctrl,
    required this.gameMode,
    required this.startTime,
    required this.onGameModeChanged,
    required this.onPickDateTime,
    required this.onPreview,
    required this.themeData,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollCtrl,
      padding: const EdgeInsets.all(AppSizes.space16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field(
              ctrl: titleCtrl,
              label: 'Tournament Title',
              hint: 'e.g. Firedrop Pro League S6',
              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
            ),
            _field(
              ctrl: descCtrl,
              label: 'Description',
              hint: 'Tell players what this is about...',
              maxLines: 3,
            ),
            _field(
              ctrl: imageCtrl,
              label: 'Banner Image URL',
              hint: 'https://...',
              keyboard: TextInputType.url,
              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
            ),
            const _FieldLabel('Game Mode'),
            const SizedBox(height: 8),
            Row(
              children: GameMode.values.map((m) {
                final sel = gameMode == m;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => onGameModeChanged(m),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColorTokens.primary
                              : AppColorTokens.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: sel
                                ? AppColorTokens.primary
                                : AppColorTokens.border,
                          ),
                        ),
                        child: Text(
                          m.name.toUpperCase(),
                          style: TextStyle(
                            color: sel
                                ? Colors.black
                                : AppColorTokens.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const _FieldLabel('Start Date & Time'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onPickDateTime,
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColorTokens.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColorTokens.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: AppColorTokens.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('d MMM yyyy • HH:mm').format(startTime),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: AppColorTokens.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _field(
                    ctrl: entryFeeCtrl,
                    label: 'Entry Fee (₹)',
                    hint: '0',
                    keyboard: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _field(
                    ctrl: maxSlotsCtrl,
                    label: 'Max Slots',
                    hint: '100',
                    keyboard: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            const _FieldLabel('Prize Distribution (₹)'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _field(
                    ctrl: prize1Ctrl,
                    label: '🥇 1st',
                    hint: '0',
                    keyboard: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _field(
                    ctrl: prize2Ctrl,
                    label: '🥈 2nd',
                    hint: '0',
                    keyboard: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _field(
                    ctrl: prize3Ctrl,
                    label: '🥉 3rd',
                    hint: '0',
                    keyboard: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            _field(
              ctrl: rulesCtrl,
              label: 'Rules & Guidelines',
              hint: 'Enter tournament rules...',
              maxLines: 4,
            ),
            const SizedBox(height: 8),
            // ── Preview CTA ──
            SizedBox(
              width: double.infinity,
              height: 54,
              child: GestureDetector(
                onTap: onPreview,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColorTokens.primaryLight,
                        AppColorTokens.primary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'PREVIEW TOURNAMENT',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.visibility_outlined,
                        color: Colors.black,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.space24),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: keyboard,
            inputFormatters: inputFormatters,
            validator: validator,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: AppColorTokens.textDisabled,
                fontSize: 13,
              ),
              filled: true,
              fillColor: AppColorTokens.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColorTokens.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColorTokens.primary,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColorTokens.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColorTokens.error,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 3 — Preview ─────────────────────────────────────────────────────────
class _TournamentPreview extends StatelessWidget {
  final String title, description, imageUrl, rulesText;
  final GameMode gameMode;
  final int entryFee, prize1, prize2, prize3, maxSlots;
  final DateTime startTime;
  final bool submitting;
  final VoidCallback onEdit;
  final VoidCallback onConfirm;

  const _TournamentPreview({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.gameMode,
    required this.entryFee,
    required this.prize1,
    required this.prize2,
    required this.prize3,
    required this.maxSlots,
    required this.startTime,
    required this.rulesText,
    required this.submitting,
    required this.onEdit,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final totalPrize = prize1 + prize2 + prize3;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.space16,
        0,
        AppSizes.space16,
        AppSizes.space24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner image preview ──
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radius16),
            child: AspectRatio(
              aspectRatio: 16 / 7,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _NoImage(),
                    )
                  : _NoImage(),
            ),
          ),
          const SizedBox(height: AppSizes.space16),

          // ── Title + mode ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title.isEmpty ? '(No title)' : title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColorTokens.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  border: Border.all(color: AppColorTokens.primary),
                ),
                child: Text(
                  gameMode.name.toUpperCase(),
                  style: const TextStyle(
                    color: AppColorTokens.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.space8),
          if (description.isNotEmpty)
            Text(
              description,
              style: const TextStyle(
                color: AppColorTokens.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          const SizedBox(height: AppSizes.space16),

          // ── Key stats grid ──
          Row(
            children: [
              _PreviewStat(
                icon: Icons.calendar_today_outlined,
                label: 'Start Time',
                value: DateFormat('d MMM • HH:mm').format(startTime),
                color: AppColorTokens.primary,
              ),
              const SizedBox(width: AppSizes.space8),
              _PreviewStat(
                icon: Icons.group_outlined,
                label: 'Max Slots',
                value: '$maxSlots players',
                color: AppColorTokens.secondary,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.space8),
          Row(
            children: [
              _PreviewStat(
                icon: Icons.monetization_on_outlined,
                label: 'Entry Fee',
                value: entryFee == 0 ? 'Free' : '₹$entryFee',
                color: AppColorTokens.gold,
              ),
              const SizedBox(width: AppSizes.space8),
              _PreviewStat(
                icon: Icons.emoji_events_outlined,
                label: 'Prize Pool',
                value: '₹$totalPrize',
                color: AppColorTokens.success,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.space16),

          // ── Prize breakdown ──
          _SectionHeader('🏆 Prize Breakdown'),
          const SizedBox(height: AppSizes.space8),
          Container(
            padding: const EdgeInsets.all(AppSizes.space16),
            decoration: BoxDecoration(
              color: AppColorTokens.surface,
              borderRadius: BorderRadius.circular(AppSizes.radius16),
              border: Border.all(color: AppColorTokens.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _PrizeTile(rank: '🥇 1st', amount: prize1),
                _PrizeDivider(),
                _PrizeTile(rank: '🥈 2nd', amount: prize2),
                _PrizeDivider(),
                _PrizeTile(rank: '🥉 3rd', amount: prize3),
              ],
            ),
          ),

          // ── Rules ──
          if (rulesText.isNotEmpty) ...[
            const SizedBox(height: AppSizes.space16),
            _SectionHeader('📋 Rules & Guidelines'),
            const SizedBox(height: AppSizes.space8),
            Container(
              padding: const EdgeInsets.all(AppSizes.space16),
              decoration: BoxDecoration(
                color: AppColorTokens.surface,
                borderRadius: BorderRadius.circular(AppSizes.radius16),
                border: Border.all(color: AppColorTokens.border),
              ),
              child: Text(
                rulesText,
                style: const TextStyle(
                  color: AppColorTokens.textSecondary,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSizes.space16),

          // ── Action buttons ──
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColorTokens.surface,
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      border: Border.all(color: AppColorTokens.border),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          color: AppColorTokens.textSecondary,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'EDIT',
                          style: TextStyle(
                            color: AppColorTokens.textSecondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.space12),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: submitting ? null : onConfirm,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: submitting
                          ? null
                          : const LinearGradient(
                              colors: [
                                AppColorTokens.primaryLight,
                                AppColorTokens.primary,
                              ],
                            ),
                      color: submitting ? AppColorTokens.border : null,
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Center(
                      child: submitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.rocket_launch_rounded,
                                  color: Colors.black,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'CREATE',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Preview helper widgets ───────────────────────────────────────────────────
class _NoImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColorTokens.bgTertiary,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppColorTokens.textDisabled,
          size: 36,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _PreviewStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _PreviewStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSizes.space12),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColorTokens.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrizeTile extends StatelessWidget {
  final String rank;
  final int amount;
  const _PrizeTile({required this.rank, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(rank, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(
          amount == 0 ? '-' : '₹$amount',
          style: const TextStyle(
            color: AppColorTokens.gold,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PrizeDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 36, width: 1, color: AppColorTokens.border);
  }
}

// ─── Shared label ─────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColorTokens.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}
