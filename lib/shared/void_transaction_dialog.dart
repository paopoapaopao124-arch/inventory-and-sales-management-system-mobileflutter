import 'package:flutter/material.dart';

/// Shows a confirmation dialog to void (cancel) a sale.
///
/// - Admin: just enters a reason and confirms.
/// - Staff: must also enter an admin PIN (checked by [verifyAdminPin]).
///
/// [onVoid] is where YOUR backend logic goes: mark the sale as "voided",
/// save the reason, and put the sold quantities back into stock.
///
/// Returns true if the sale was voided.
Future<bool> showVoidTransactionDialog(
    BuildContext context, {
      required String saleId,
      required double total,
      required bool isAdmin,
      required Future<void> Function(String reason) onVoid,
      Future<bool> Function(String pin)? verifyAdminPin,
    }) async {
  final reasonCtrl = TextEditingController();
  final pinCtrl = TextEditingController();
  final needsPin = !isAdmin;
  bool loading = false;
  String? error;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        Future<void> submit() async {
          final reason = reasonCtrl.text.trim();
          if (reason.isEmpty) {
            setState(() => error = 'Please enter a reason.');
            return;
          }
          setState(() {
            loading = true;
            error = null;
          });
          try {
            if (needsPin) {
              final ok = verifyAdminPin != null &&
                  await verifyAdminPin(pinCtrl.text.trim());
              if (!ok) {
                setState(() {
                  loading = false;
                  error = 'Invalid admin PIN.';
                });
                return;
              }
            }
            await onVoid(reason);
            if (ctx.mounted) Navigator.pop(ctx, true);
          } catch (e) {
            setState(() {
              loading = false;
              error = 'Failed to void transaction: $e';
            });
          }
        }

        return AlertDialog(
          backgroundColor: const Color(0xFF0F2438),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Void Transaction',
              style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sale: $saleId',
                    style: const TextStyle(color: Colors.white70)),
                Text('Total: ₱${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: _input('Reason for voiding'),
                ),
                if (needsPin) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: pinCtrl,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _input('Admin approval PIN'),
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!,
                      style: const TextStyle(color: Colors.redAccent)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent),
              onPressed: loading ? null : submit,
              child: loading
                  ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Void Sale'),
            ),
          ],
        );
      },
    ),
  );

  return result ?? false;
}

InputDecoration _input(String label) => InputDecoration(
  labelText: label,
  labelStyle: const TextStyle(color: Colors.white60),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Colors.white24),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Colors.tealAccent),
  ),
);