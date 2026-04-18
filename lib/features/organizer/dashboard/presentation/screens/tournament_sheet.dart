import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eagle_esports/features/tournament/presentation/providers/tournament_providers.dart';
import 'package:eagle_esports/shared/models/tournaments_model.dart';
import 'package:eagle_esports/features/organizer/dashboard/presentation/widgets/tournament_sheet_header.dart';
import 'package:eagle_esports/features/organizer/dashboard/presentation/widgets/tournament_step_indicator.dart';
import 'package:eagle_esports/features/organizer/dashboard/presentation/widgets/tournament_template_picker.dart';
import 'package:eagle_esports/features/organizer/dashboard/presentation/widgets/tournament_form_step.dart';
import 'package:eagle_esports/features/organizer/dashboard/presentation/widgets/tournament_preview_step.dart';

class TournamentSheet extends ConsumerStatefulWidget {
  final String organizerId;
  const TournamentSheet({super.key, required this.organizerId});

  @override
  ConsumerState<TournamentSheet> createState() => _TournamentSheetState();
}

class _TournamentSheetState extends ConsumerState<TournamentSheet>
    with SingleTickerProviderStateMixin {
  int _step = 0;
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

  late final AnimationController _stepAnim;
  late final Animation<double> _stepFade;

  @override
  void initState() {
    super.initState();
    _stepAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
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
      _startTime = DateTime.now().add(const Duration(hours: 2));
    });
    _goTo(1);
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: Theme.of(context).colorScheme.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime),
    );
    if (time == null) return;

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
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tournament created successfully! 🎉'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String get _title => switch (_step) {
    0 => 'Clone Template',
    1 => 'Tournament Details',
    _ => 'Review Tournament',
  };

  String get _subtitle => switch (_step) {
    0 => 'Choose a past tournament to copy its settings',
    1 => 'Fill in the information for your new event',
    _ => 'Verify everything before publishing to players',
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TournamentSheetHeader(
            title: _title,
            subtitle: _subtitle,
            onClose: () => Navigator.pop(context),
          ),
          TournamentStepIndicator(currentStep: _step),

          Flexible(
            child: FadeTransition(
              opacity: _stepFade,
              child: switch (_step) {
                0 => TournamentTemplatePicker(
                  organizerId: widget.organizerId,
                  onSelect: _applyTemplate,
                  onSkip: () => _goTo(1),
                ),
                1 => TournamentFormStep(
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
                  onPreview: () {
                    if (_formKey.currentState!.validate()) _goTo(2);
                  },
                ),
                _ => TournamentPreviewStep(
                  title: _titleCtrl.text,
                  description: _descCtrl.text,
                  imageUrl: _imageCtrl.text,
                  gameMode: _gameMode,
                  entryFee: int.tryParse(_entryFeeCtrl.text) ?? 0,
                  prize1: int.tryParse(_prize1Ctrl.text) ?? 0,
                  prize2: int.tryParse(_prize2Ctrl.text) ?? 0,
                  prize3: int.tryParse(_prize3Ctrl.text) ?? 0,
                  maxSlots: int.tryParse(_maxSlotsCtrl.text) ?? 0,
                  startTime: _startTime,
                  rulesText: _rulesCtrl.text,
                  submitting: _submitting,
                  onEdit: () => _goTo(1),
                  onConfirm: _submit,
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}
