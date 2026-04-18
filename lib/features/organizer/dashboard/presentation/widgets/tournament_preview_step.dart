import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eagle_esports/shared/models/tournaments_model.dart';

class TournamentPreviewStep extends StatelessWidget {
  final String title, description, imageUrl, rulesText;
  final GameMode gameMode;
  final int entryFee, prize1, prize2, prize3, maxSlots;
  final DateTime startTime;
  final bool submitting;
  final VoidCallback onEdit;
  final VoidCallback onConfirm;

  const TournamentPreviewStep({
    super.key,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalPrize = prize1 + prize2 + prize3;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                   imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, _, _) => _FallbackBanner())
                      : _FallbackBanner(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(8)),
                      child: Text(gameMode.name.toUpperCase(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          Text(title.toUpperCase(), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(description, style: TextStyle(color: colorScheme.onSurfaceVariant, height: 1.5)),
          
          const SizedBox(height: 24),
          _InfoRow(icon: Icons.calendar_today_rounded, label: 'START TIME', value: DateFormat('EEEE, d MMM • HH:mm').format(startTime)),
          _InfoRow(icon: Icons.monetization_on_rounded, label: 'ENTRY FEE', value: '₹$entryFee', valueColor: colorScheme.primary),
          _InfoRow(icon: Icons.group_rounded, label: 'MAX SLOTS', value: '$maxSlots TEAMS'),
          
          const SizedBox(height: 24),
          _Label('PRIZE POOL'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL PRIZE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                    Text('₹$totalPrize', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 20)),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _PrizeBox(rank: '1ST', amount: prize1, color: Colors.amber),
                    _PrizeBox(rank: '2ND', amount: prize2, color: Colors.blueGrey),
                    _PrizeBox(rank: '3RD', amount: prize3, color: Colors.brown),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          _Label('RULES'),
          const SizedBox(height: 12),
          Text(rulesText, style: TextStyle(color: colorScheme.onSurfaceVariant, height: 1.6)),
          
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: colorScheme.outline),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('EDIT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: submitting ? null : onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('CONFIRM & PUBLISH', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _FallbackBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Center(child: Icon(Icons.sports_esports_rounded, size: 48, color: Theme.of(context).colorScheme.outline)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: valueColor)),
        ],
      ),
    );
  }
}

class _PrizeBox extends StatelessWidget {
  final String rank;
  final int amount;
  final Color color;

  const _PrizeBox({required this.rank, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(rank, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text('₹$amount', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w900,
        fontSize: 11,
        letterSpacing: 2,
      ),
    );
  }
}
