import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:eagle_esports/shared/models/tournaments_model.dart';
import 'package:eagle_esports/features/video/data/repositories/upload_repository.dart';

class TournamentFormStep extends StatefulWidget {
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
  State<TournamentFormStep> createState() => _TournamentFormStepState();
}

class _TournamentFormStepState extends State<TournamentFormStep> {
  File? _pickedFile;
  bool _uploading = false;
  final _uploadRepo = UploadRepository();
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Listen so template-apply (which sets imageCtrl.text) refreshes the preview
    widget.imageCtrl.addListener(_onImageUrlChanged);
  }

  @override
  void dispose() {
    widget.imageCtrl.removeListener(_onImageUrlChanged);
    super.dispose();
  }

  void _onImageUrlChanged() {
    if (mounted) setState(() {});
  }

  // ═══════════════════════ IMAGE PICKER ═══════════════════════

  Future<void> _pickBanner() async {
    final xFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (xFile == null || !mounted) return;

    final file = File(xFile.path);
    setState(() {
      _pickedFile = file;
      _uploading = true;
    });

    try {
      final bytes = await xFile.readAsBytes();
      final bannerId = DateTime.now().millisecondsSinceEpoch.toString();
      final url = await _uploadRepo.uploadBannerBytes(bannerId, bytes);
      if (mounted) {
        widget.imageCtrl.text = url;
        setState(() => _uploading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Banner upload failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _pickedFile = null;
          _uploading = false;
        });
      }
    }
  }

  // ═══════════════════════ BUILD ═══════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      controller: widget.scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BuildField(
              label: 'TOURNAMENT TITLE',
              hint: 'e.g. Pro League Season 1',
              controller: widget.titleCtrl,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),

            // ── Banner Image Picker ──────────────────────────────────
            _buildBannerPicker(colorScheme),

            _BuildField(
              label: 'DESCRIPTION',
              hint: 'Provide details about the tournament...',
              controller: widget.descCtrl,
              maxLines: 3,
            ),

            const SizedBox(height: 12),
            const _HeaderLabel('GAME MODE'),
            const SizedBox(height: 12),
            Row(
              children: GameMode.values.map((m) {
                final isSelected = widget.gameMode == m;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => widget.onGameModeChanged(m),
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest.withValues(
                                  alpha: 0.1,
                                ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outline.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          m.name.toUpperCase(),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.black
                                : colorScheme.onSurface,
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
            const _HeaderLabel('DATE & TIME'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: widget.onPickDateTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      DateFormat(
                        'EEEE, d MMMM yyyy • HH:mm',
                      ).format(widget.startTime),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.edit_calendar_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _BuildField(
                    label: 'ENTRY FEE (₹)',
                    hint: '0',
                    controller: widget.entryFeeCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _BuildField(
                    label: 'SLOTS',
                    hint: '100',
                    controller: widget.maxSlotsCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const _HeaderLabel('PRIZE DISTRIBUTION (₹)'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _BuildField(
                    label: '🥇 1st',
                    hint: '0',
                    controller: widget.prize1Ctrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BuildField(
                    label: '🥈 2nd',
                    hint: '0',
                    controller: widget.prize2Ctrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BuildField(
                    label: '🥉 3rd',
                    hint: '0',
                    controller: widget.prize3Ctrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            _BuildField(
              label: 'RULES & GUIDELINES',
              hint: 'Enter rules each on new line...',
              controller: widget.rulesCtrl,
              maxLines: 5,
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: widget.onPreview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'PREVIEW TOURNAMENT',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════ BANNER PICKER WIDGET ═══════════════════════

  Widget _buildBannerPicker(ColorScheme colorScheme) {
    final hasUrl = widget.imageCtrl.text.isNotEmpty;
    final hasLocal = _pickedFile != null;
    final showImage = hasLocal || hasUrl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeaderLabel('BANNER IMAGE'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _uploading ? null : _pickBanner,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: showImage
                      ? colorScheme.primary.withValues(alpha: 0.3)
                      : colorScheme.outline.withValues(alpha: 0.2),
                  width: showImage ? 1.5 : 1,
                ),
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ── Image layer ───────────────────────────────────
                  if (hasLocal)
                    Image.file(_pickedFile!, fit: BoxFit.cover)
                  else if (hasUrl)
                    Image.network(
                      widget.imageCtrl.text,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildEmptyState(colorScheme),
                    )
                  else
                    _buildEmptyState(colorScheme),

                  // ── Gradient overlay on image ─────────────────────
                  if (showImage && !_uploading)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),

                  // ── Upload progress overlay ───────────────────────
                  if (_uploading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'UPLOADING...',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Bottom bar (uploaded state) ───────────────────
                  if (showImage && !_uploading)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: colorScheme.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'BANNER READY',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'CHANGE',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_rounded,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          size: 40,
        ),
        const SizedBox(height: 12),
        Text(
          'TAP TO SELECT BANNER',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Recommended: 16:9 ratio',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════ REUSABLE WIDGETS ═══════════════════════

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
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                fontSize: 14,
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.1,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.error, width: 1.5),
              ),
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
