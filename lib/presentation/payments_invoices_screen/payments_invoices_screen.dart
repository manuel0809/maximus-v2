import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../services/payments_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/transaction_card_widget.dart';
import './widgets/invoice_detail_widget.dart';
import './widgets/payment_method_card_widget.dart';
import './widgets/payment_statistics_widget.dart';

class PaymentsInvoicesScreen extends StatefulWidget {
  const PaymentsInvoicesScreen({super.key});

  @override
  State<PaymentsInvoicesScreen> createState() => _PaymentsInvoicesScreenState();
}

class _PaymentsInvoicesScreenState extends State<PaymentsInvoicesScreen>
    with SingleTickerProviderStateMixin {
  final PaymentsService _paymentsService = PaymentsService.instance;
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;
  List<Map<String, dynamic>> payments = [];
  List<Map<String, dynamic>> paymentMethods = [];
  Map<String, dynamic>? statistics;
  bool isLoading = true;
  bool isRefreshing = false;
  String selectedTab = 'payments';

  String statusFilter = 'all';
  String serviceTypeFilter = 'all';
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _subscribeToPayments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _paymentsService.unsubscribe();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);

      final paymentsData = await _paymentsService.getPayments(
        statusFilter: statusFilter,
        serviceTypeFilter: serviceTypeFilter,
        startDate: startDate,
        endDate: endDate,
      );
      final methodsData = await _paymentsService.getPaymentMethods();
      final statsData = await _paymentsService.getPaymentStatistics(
        startDate: startDate,
        endDate: endDate,
      );

      setState(() {
        payments = paymentsData;
        paymentMethods = methodsData;
        statistics = statsData;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => isRefreshing = true);
    await _loadData();
    setState(() => isRefreshing = false);
  }

  void _subscribeToPayments() {
    _paymentsService.subscribeToPayments((payment) {
      _loadData();
    });
  }

  Future<void> _handleSearch(String query) async {
    if (query.isEmpty) {
      _loadData();
      return;
    }

    try {
      setState(() => isLoading = true);
      final results = await _paymentsService.searchPayments(query);
      setState(() {
        payments = results;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search error: $e')));
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Transactions'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment Status',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 1.h),
              Wrap(
                spacing: 2.w,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: statusFilter == 'all',
                    onSelected: (selected) {
                      setState(() => statusFilter = 'all');
                    },
                  ),
                  FilterChip(
                    label: const Text('Completed'),
                    selected: statusFilter == 'completed',
                    onSelected: (selected) {
                      setState(() => statusFilter = 'completed');
                    },
                  ),
                  FilterChip(
                    label: const Text('Pending'),
                    selected: statusFilter == 'pending',
                    onSelected: (selected) {
                      setState(() => statusFilter = 'pending');
                    },
                  ),
                  FilterChip(
                    label: const Text('Failed'),
                    selected: statusFilter == 'failed',
                    onSelected: (selected) {
                      setState(() => statusFilter = 'failed');
                    },
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              const Text(
                'Service Type',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 1.h),
              Wrap(
                spacing: 2.w,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: serviceTypeFilter == 'all',
                    onSelected: (selected) {
                      setState(() => serviceTypeFilter = 'all');
                    },
                  ),
                  FilterChip(
                    label: const Text('BLACK'),
                    selected: serviceTypeFilter == 'BLACK',
                    onSelected: (selected) {
                      setState(() => serviceTypeFilter = 'BLACK');
                    },
                  ),
                  FilterChip(
                    label: const Text('BLACK SUV'),
                    selected: serviceTypeFilter == 'BLACK SUV',
                    onSelected: (selected) {
                      setState(() => serviceTypeFilter = 'BLACK SUV');
                    },
                  ),
                  FilterChip(
                    label: const Text('Car Rental'),
                    selected: serviceTypeFilter == 'Car Rental',
                    onSelected: (selected) {
                      setState(() => serviceTypeFilter = 'Car Rental');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                statusFilter = 'all';
                serviceTypeFilter = 'all';
                startDate = null;
                endDate = null;
              });
              Navigator.pop(context);
              _loadData();
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadData();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showInvoiceDetail(Map<String, dynamic> payment) {
    final invoice = (payment['invoices'] as List?)?.isNotEmpty == true
        ? (payment['invoices'] as List).first
        : null;

    if (invoice == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invoice not available')));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: InvoiceDetailWidget(
            invoice: invoice,
            payment: payment,
            scrollController: scrollController,
            onDownloadPdf: () => _generateInvoicePdf(invoice, payment),
          ),
        ),
      ),
    );
  }

  Future<void> _generateInvoicePdf(
    Map<String, dynamic> invoice,
    Map<String, dynamic> payment,
  ) async {
    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('MMM dd, yyyy');
      final currencyFormat = NumberFormat.currency(symbol: '\$');

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'MAXIMUS LEVEL GROUP',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('Luxury Transportation Services'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'INVOICE',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(invoice['invoice_number'] ?? 'N/A'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),

                // Invoice details
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Invoice Date:'),
                        pw.Text(
                          dateFormat.format(
                            DateTime.parse(invoice['invoice_date']),
                          ),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Payment Status:'),
                        pw.Text(
                          (payment['payment_status'] as String).toUpperCase(),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Service details
                pw.Text(
                  'Service Details',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Service Type: ${invoice['service_type'] ?? 'N/A'}'),
                if (invoice['vehicle_type'] != null)
                  pw.Text('Vehicle: ${invoice['vehicle_type']}'),
                if (invoice['pickup_location'] != null)
                  pw.Text('Pickup: ${invoice['pickup_location']}'),
                if (invoice['dropoff_location'] != null)
                  pw.Text('Dropoff: ${invoice['dropoff_location']}'),
                if (invoice['trip_date'] != null)
                  pw.Text(
                    'Date: ${dateFormat.format(DateTime.parse(invoice['trip_date']))}',
                  ),
                pw.SizedBox(height: 20),

                // Cost breakdown
                pw.Text(
                  'Cost Breakdown',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    _buildPdfTableRow(
                      'Base Fare',
                      currencyFormat.format(invoice['base_fare'] ?? 0),
                    ),
                    _buildPdfTableRow(
                      'Distance Cost',
                      currencyFormat.format(invoice['distance_cost'] ?? 0),
                    ),
                    _buildPdfTableRow(
                      'Time Cost',
                      currencyFormat.format(invoice['time_cost'] ?? 0),
                    ),
                    if ((invoice['airport_fee'] ?? 0) > 0)
                      _buildPdfTableRow(
                        'Airport Fee',
                        currencyFormat.format(invoice['airport_fee']),
                      ),
                    if ((invoice['peak_hour_charge'] ?? 0) > 0)
                      _buildPdfTableRow(
                        'Peak Hour Charge',
                        currencyFormat.format(invoice['peak_hour_charge']),
                      ),
                    if ((invoice['additional_fees'] ?? 0) > 0)
                      _buildPdfTableRow(
                        'Additional Fees',
                        currencyFormat.format(invoice['additional_fees']),
                      ),
                    _buildPdfTableRow(
                      'Subtotal',
                      currencyFormat.format(invoice['subtotal'] ?? 0),
                      bold: true,
                    ),
                    _buildPdfTableRow(
                      'Tax',
                      currencyFormat.format(invoice['tax_amount'] ?? 0),
                    ),
                    _buildPdfTableRow(
                      'Gratuity',
                      currencyFormat.format(invoice['gratuity'] ?? 0),
                    ),
                    _buildPdfTableRow(
                      'TOTAL',
                      currencyFormat.format(invoice['total_amount'] ?? 0),
                      bold: true,
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),

                // Footer
                pw.Text(
                  'Thank you for choosing MAXIMUS LEVEL GROUP',
                  style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice PDF generated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    }
  }

  pw.TableRow _buildPdfTableRow(
    String label,
    String value, {
    bool bold = false,
  }) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Mis Reservas',
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tab Bar
            Container(
              padding: EdgeInsets.all(4.w),
              color: theme.colorScheme.surface,
              child: Row(
                children: [
                  Expanded(
                    child: _buildTab('Pagos', selectedTab == 'payments', () {
                      setState(() => selectedTab = 'payments');
                    }),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: _buildTab('Facturas', selectedTab == 'invoices', () {
                      setState(() => selectedTab = 'invoices');
                    }),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: _buildTab(
                      'Estadísticas',
                      selectedTab == 'statistics',
                      () {
                        setState(() => selectedTab = 'statistics');
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: EdgeInsets.all(4.w),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by reference, location...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _handleSearch('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: _handleSearch,
              ),
            ),

            // Tab content
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Payments tab
                      _buildPaymentsTab(),

                      // Invoices tab
                      _buildInvoicesTab(),

                      // Statistics tab
                      _buildStatisticsTab(),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.2.h),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF8B1538) : Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentsTab() {
    if (payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 2.h),
            Text(
              'No transactions found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: payments.length,
        itemBuilder: (context, index) {
          final payment = payments[index];
          return TransactionCardWidget(
            payment: payment,
            onTap: () => _showInvoiceDetail(payment),
          );
        },
      ),
    );
  }

  Widget _buildInvoicesTab() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          ...paymentMethods.map(
            (method) => PaymentMethodCardWidget(
              paymentMethod: method,
              onSetDefault: () async {
                await _paymentsService.updatePaymentMethod(
                  method['id'],
                  isDefault: true,
                );
                _loadData();
              },
              onDelete: () async {
                await _paymentsService.deletePaymentMethod(method['id']);
                _loadData();
              },
            ),
          ),
          SizedBox(height: 2.h),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Add payment method feature coming soon'),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Payment Method'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    if (statistics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: PaymentStatisticsWidget(statistics: statistics!),
      ),
    );
  }
}
