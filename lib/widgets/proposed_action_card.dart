import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/farm_provider.dart';
import '../services/vet_ai_service.dart';
import '../theme.dart';

/// Phase 1: propose → confirm → execute.
///
/// Sonya proposes a write action (vaccinate, log weight, add case, …) as data
/// instead of executing it. This card shows the summary + affected count and
/// only runs the action — via POST /confirm-action — when the farmer taps
/// Tasdiqlash. Reused for every write action, so new features need no new UI.
class ProposedActionCard extends StatefulWidget {
  final Map<String, dynamic> action;

  /// Called with the backend response after a successful confirm (so the host
  /// screen can refresh local data / update SQLite — Phase 2).
  final void Function(Map<String, dynamic> result)? onConfirmed;

  const ProposedActionCard({super.key, required this.action, this.onConfirmed});

  @override
  State<ProposedActionCard> createState() => _ProposedActionCardState();
}

class _ProposedActionCardState extends State<ProposedActionCard> {
  String _status = 'pending'; // pending | confirming | done | cancelled | error

  Future<void> _confirm() async {
    final farmId = context.read<FarmProvider>().farmId;
    if (farmId == null) return;
    setState(() => _status = 'confirming');
    final result = await VetAiService.confirmAction(
      farmId: farmId,
      action: widget.action['action'] as String? ?? '',
      params: Map<String, dynamic>.from(widget.action['params'] as Map? ?? {}),
    );
    if (!mounted) return;
    final ok = result != null && result['success'] == true;
    if (ok) {
      // Phase 2: land the change in local SQLite so screens update live.
      await VetAiService.applyConfirmedAction(
        farmId: farmId,
        action: widget.action['action'] as String? ?? '',
        params: Map<String, dynamic>.from(widget.action['params'] as Map? ?? {}),
        response: result,
      );
    }
    if (!mounted) return;
    setState(() => _status = ok ? 'done' : 'error');
    if (ok) widget.onConfirmed?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_status == 'done') {
      return _chip(Icons.check_circle, kMint, l10n.proposedActionDone);
    }
    if (_status == 'cancelled') {
      return _chip(Icons.cancel, Colors.grey, l10n.proposedActionCancelled);
    }

    final a = widget.action;
    final summary = a['summary'] as String? ?? l10n.proposedActionDefaultSummary;
    final affected = (a['affected_animals'] as List?)?.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kOrange.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kOrange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, size: 16, color: kOrange),
              const SizedBox(width: 6),
              Text(l10n.proposedActionNeedsConfirm,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kOrange)),
            ],
          ),
          const SizedBox(height: 6),
          Text(summary, style: const TextStyle(fontSize: 15, color: kDark)),
          if (affected > 0) ...[
            const SizedBox(height: 4),
            Text(l10n.proposedActionAffectedCount(affected),
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
          const SizedBox(height: 10),
          if (_status == 'confirming')
            const Center(
              child: Padding(
                padding: EdgeInsets.all(4),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _status = 'cancelled'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    child: Text(
                      l10n.proposedActionCancelBtn,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kMint,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    child: Text(
                      l10n.confirm,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          if (_status == 'error') ...[
            const SizedBox(height: 6),
            Text(l10n.proposedActionError,
                style: const TextStyle(fontSize: 12, color: kError)),
          ],
        ],
      ),
    );
  }

  Widget _chip(IconData icon, Color color, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      );
}
