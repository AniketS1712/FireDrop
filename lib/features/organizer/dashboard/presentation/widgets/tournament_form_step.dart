import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eagle_esports/shared/models/tournaments_model.dart';

class TournamentFormStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final ScrollController scrollCtrl;
  final TextEditingController titleCtrl, descCtrl, imageCtrl, rulesCtrl, entryFeeCtrl, maxSlotsCtrl, prize1Ctrl, prize2Ctrl, prize3Ctrl;
  final GameMode gameMode;
  final DateTime startTime;
  final void Function(GameMode) onGameModeChanged;
  final VoidCallback onPickDateTime;
  final VoidCallback onPreview;

  const TournamentFormStep({
    super.key,
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
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      controller: scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BuildField(label: 'TOURNAMENT TITLE', hint: 'e.g. Pro League Season 1', controller: titleCtrl, validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
            _BuildField(label: 'BANNER IMAGE URL', hint: 'https://...', controller: imageCtrl, keyboardType: TextInputType.url),
            _BuildField(label: 'DESCRIPTION', hint: 'Provide details about the tournament...', controller: descCtrl, maxLines: 3),
            
            const SizedBox(height: 12),
            _HeaderLabel('GAME MODE'),
            const SizedBox(height: 12),
            Row(
              children: GameMode.values.map((m) {
                final isSelected = gameMode == m;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => onGameModeChanged(m),
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.1)),
                        ),
                        child: Text(
                          m.name.toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? Colors.black : colorScheme.onSurface,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            _HeaderLabel('DATE & TIME'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onPickDateTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 16),
                    Text(
                      DateFormat('EEEE, d MMMM yyyy • HH:mm').format(startTime),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Icon(Icons.edit_calendar_rounded, color: colorScheme.onSurfaceVariant, size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _BuildField(label: 'ENTRY FEE (₹)', hint: '0', controller: entryFeeCtrl, keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(child: _BuildField(label: 'SLOTS', hint: '100', controller: maxSlotsCtrl, keyboardType: TextInputType.number)),
              ],
            ),
            
            _HeaderLabel('PRIZE DISTRIBUTION (₹)'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _BuildField(label: '🥇 1st', hint: '0', controller: prize1Ctrl, keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: _BuildField(label: '🥈 2nd', hint: '0', controller: prize2Ctrl, keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: _BuildField(label: '🥉 3rd', hint: '0', controller: prize3Ctrl, keyboardType: TextInputType.number)),
              ],
            ),
            
            _BuildField(label: 'RULES & GUIDELINES', hint: 'Enter rules each on new line...', controller: rulesCtrl, maxLines: 5),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onPreview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('PREVIEW TOURNAMENT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _BuildField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _BuildField({
    required this.label,
    required this.hint,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderLabel(label),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4), fontSize: 14),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary, width: 1.5)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.error)),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.error, width: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  final String text;
  const _HeaderLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
    );
  }
}
