import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_management/core/providers/hms_providers.dart';
import 'package:hospital_management/core/providers/hospital_name_provider.dart';
import 'package:hospital_management/core/router/app_routes.dart';
import 'package:hospital_management/data/models/hms_models.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  final String invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final invoiceAsync = ref.watch(invoiceDetailProvider(invoiceId));
    final allInvoices = ref.watch(invoicesListProvider).value ?? [];
    final hospitalInfo = ref.watch(hospitalInfoProvider).value ?? {};
    final hospitalName = hospitalInfo['name']?.isNotEmpty == true ? hospitalInfo['name']! : 'Hospital';
    final hospitalAddress = hospitalInfo['address'] ?? '';
    final hospitalPhone = hospitalInfo['phone'] ?? '';
    final hospitalRegNo = hospitalInfo['regNo'] ?? '';
    final hospitalGstNo = hospitalInfo['gstNo'] ?? '';

    InvoiceModel? invoice = invoiceAsync.value;
    if (invoice == null && allInvoices.isNotEmpty) {
      invoice = allInvoices.where((i) =>
        i.id.toString() == invoiceId ||
        i.invoiceNo == invoiceId ||
        i.invoiceNo.endsWith(invoiceId) ||
        i.invoiceNo.contains(invoiceId),
      ).firstOrNull;
    }

    if (invoiceAsync.isLoading && invoice == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Invoice #$invoiceId')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (invoice == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Invoice #$invoiceId'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(AppRoutes.billing),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
              const Gap(16),
              Text('Invoice "$invoiceId" not found.', style: Theme.of(context).textTheme.titleMedium),
              const Gap(12),
              FilledButton(
                onPressed: () => context.go(AppRoutes.billing),
                child: const Text('Return to Billing'),
              ),
            ],
          ),
        ),
      );
    }

    final items = invoice.items;
    final subtotal = invoice.subtotalPaise / 100.0;
    final discount = invoice.discountPaise / 100.0;
    final tax = invoice.taxPaise / 100.0;
    final grandTotal = invoice.totalPaise / 100.0;
    final paid = invoice.paidPaise / 100.0;
    final due = invoice.duePaise / 100.0;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text('Invoice #${invoice.invoiceNo}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.billing),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Printing 80mm thermal receipt for ${invoice!.invoiceNo}…')),
              );
            },
            icon: const Icon(Icons.receipt, size: 16),
            label: const Text('Thermal 80mm Receipt'),
          ),
          const Gap(12),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Printing full A4 itemized invoice for ${invoice!.invoiceNo}…')),
              );
            },
            icon: const Icon(Icons.print_outlined, size: 16),
            label: const Text('Print A4 Invoice'),
          ),
          const Gap(16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Invoice Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hospitalName,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (hospitalAddress.isNotEmpty || hospitalRegNo.isNotEmpty)
                              Text([
                                if (hospitalAddress.isNotEmpty) hospitalAddress,
                                if (hospitalRegNo.isNotEmpty) 'Reg. No: $hospitalRegNo',
                              ].join(' • ')),
                            if (hospitalPhone.isNotEmpty || hospitalGstNo.isNotEmpty)
                              Text([
                                if (hospitalPhone.isNotEmpty) 'Phone: $hospitalPhone',
                                if (hospitalGstNo.isNotEmpty) 'GSTIN: $hospitalGstNo',
                              ].join(' • ')),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'TAX INVOICE',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.primary),
                            ),
                            Text('Invoice #: ${invoice.invoiceNo}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Date: ${invoice.dateTime}', style: const TextStyle(color: Colors.grey)),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: invoice.status == 'Paid' ? Colors.green.shade100 : Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                invoice.status.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: invoice.status == 'Paid' ? Colors.green.shade800 : Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Gap(24),
                    const Divider(),
                    const Gap(16),

                    // Billed To
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Billed To Patient:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            const Gap(4),
                            Text(invoice.patientName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('UHID: ${invoice.uhid} • Category: ${invoice.billType}'),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Payment Summary:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            const Gap(4),
                            Text('Status: ${invoice.status.toUpperCase()}',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: invoice.status == 'Paid' ? Colors.green : Colors.orange.shade800)),
                            Text('Mode: ${invoice.paymentMode}'),
                          ],
                        ),
                      ],
                    ),
                    const Gap(24),

                    // Items Table
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(4),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(2),
                        3: FlexColumnWidth(2),
                      },
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      children: [
                        const TableRow(
                          decoration: BoxDecoration(color: Color(0x10000000)),
                          children: [
                            Padding(padding: EdgeInsets.all(12), child: Text('Service / Item Description', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(12), child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(12), child: Text('Unit Rate', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(12), child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                        if (items.isEmpty)
                          TableRow(
                            children: [
                              Padding(padding: const EdgeInsets.all(12), child: Text(invoice.billType)),
                              const Padding(padding: EdgeInsets.all(12), child: Text('1')),
                              Padding(padding: const EdgeInsets.all(12), child: Text('₹${grandTotal.toStringAsFixed(2)}')),
                              Padding(padding: const EdgeInsets.all(12), child: Text('₹${grandTotal.toStringAsFixed(2)}')),
                            ],
                          )
                        else
                          for (final item in items) ...[
                            TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    (item['desc'] ?? item['item_name'] ?? item['name'] ?? 'Medical Service').toString(),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    (item['qty'] ?? item['quantity'] ?? 1).toString(),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    '₹${((item['rate'] ?? item['unit_price'] ?? item['total'] ?? 0.0) as num).toDouble().toStringAsFixed(2)}',
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    '₹${((item['total'] ?? item['line_total'] ?? 0.0) as num).toDouble().toStringAsFixed(2)}',
                                  ),
                                ),
                              ],
                            ),
                          ],
                      ],
                    ),
                    const Gap(24),
                    const Divider(),
                    const Gap(16),

                    // Totals
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 280,
                        child: Column(
                          children: [
                            _summaryRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
                            if (discount > 0)
                              _summaryRow('Hospital Discount', '- ₹${discount.toStringAsFixed(2)}'),
                            if (tax > 0)
                              _summaryRow('GST / Taxes', '₹${tax.toStringAsFixed(2)}'),
                            const Divider(),
                            _summaryRow('Grand Total', '₹${grandTotal.toStringAsFixed(2)}', isBold: true),
                            _summaryRow('Amount Paid', '₹${paid.toStringAsFixed(2)}', isBold: true, color: Colors.green.shade800),
                            _summaryRow('Balance Due', '₹${due.toStringAsFixed(2)}', isBold: true, color: due > 0 ? Colors.red.shade800 : null),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }
}
