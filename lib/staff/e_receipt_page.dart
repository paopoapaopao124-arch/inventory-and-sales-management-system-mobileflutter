
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/sale_transaction.dart';
import '../shared/app_theme.dart';

class EReceiptPage extends StatelessWidget {
  final SaleTransaction transaction;

  const EReceiptPage({
    super.key,
    required this.transaction,
  });

  String money(double amount) => '₱${amount.toStringAsFixed(2)}';

  String pdfMoney(double amount) =>
      'PHP ${amount.toStringAsFixed(2)}';

  String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$month/$day/${date.year} • $hour:$minute $period';
  }

  String get receiptNumber {
    final id = transaction.id;
    return id.substring(id.length > 6 ? id.length - 6 : 0);
  }

  Future<void> exportPdf(BuildContext context) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pdfContext) => [
            pw.Center(
              child: pw.Text(
                'STOCKSMART',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Center(
              child: pw.Text(
                'INVENTORY AND SALES MANAGEMENT SYSTEM',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                'SALES RECEIPT',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 18),
            _pdfInfo('Receipt Number', '#$receiptNumber'),
            _pdfInfo('Date and Time', formatDate(transaction.date)),
            _pdfInfo('Payment Method', transaction.paymentMethod),
            pw.SizedBox(height: 15),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text(
              'PURCHASED ITEMS',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: [
                'Product',
                'Qty',
                'Unit Price',
                'Subtotal',
              ],
              data: transaction.items.map((item) {
                return [
                  item.productName,
                  item.quantity.toString(),
                  pdfMoney(item.unitPrice),
                  pdfMoney(item.subtotal),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                1: pw.Alignment.center,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
              border: pw.TableBorder.all(
                color: PdfColors.grey400,
                width: 0.5,
              ),
              cellPadding: const pw.EdgeInsets.all(7),
            ),
            pw.SizedBox(height: 20),
            _pdfInfo('Subtotal', pdfMoney(transaction.subtotal)),
            _pdfInfo(
              'Discount (${transaction.discountType})',
              '-${pdfMoney(transaction.discountAmount)}',
            ),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'FINAL TOTAL',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  pdfMoney(transaction.total),
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Center(
              child: pw.Text(
                'Thank you for shopping with StockSmart!',
                style: const pw.TextStyle(fontSize: 11),
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Center(
              child: pw.Text(
                'Please keep this receipt for your records.',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'receipt_$receiptNumber.pdf',
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to export receipt: $error'),
        ),
      );
    }
  }

  pw.Widget _pdfInfo(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Receipt'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: AppTheme.card,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.emerald,
                    size: 64,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'PAYMENT RECORDED',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Thank you for shopping with StockSmart!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.muted),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  _ReceiptInfo(
                    label: 'Receipt Number',
                    value: '#$receiptNumber',
                  ),
                  _ReceiptInfo(
                    label: 'Date and Time',
                    value: formatDate(transaction.date),
                  ),
                  _ReceiptInfo(
                    label: 'Payment Method',
                    value: transaction.paymentMethod,
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'PURCHASED ITEMS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...transaction.items.map(
                        (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.quantity} × '
                                      '${money(item.unitPrice)}',
                                  style: TextStyle(
                                    color: AppTheme.muted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            money(item.subtotal),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  _ReceiptInfo(
                    label: 'Subtotal',
                    value: money(transaction.subtotal),
                  ),
                  _ReceiptInfo(
                    label: 'Discount (${transaction.discountType})',
                    value: '-${money(transaction.discountAmount)}',
                  ),
                  const Divider(),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'FINAL TOTAL',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        money(transaction.total),
                        style: const TextStyle(
                          color: AppTheme.emerald,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Export receipt as PDF
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => exportPdf(context),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Export Receipt as PDF'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to Transactions'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You can export or print this receipt as a PDF.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptInfo extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptInfo({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppTheme.muted),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
