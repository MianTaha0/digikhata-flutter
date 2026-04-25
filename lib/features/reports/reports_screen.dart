import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format/money.dart';
import '../../core/theme/colors.dart';
import '../../data/db/daos/reports_dao.dart';
import 'reports_providers.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapAsync = ref.watch(snapshotProvider);
    final salesAsync = ref.watch(dailySalesProvider);
    final topAsync = ref.watch(topCustomersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(snapshotProvider);
              ref.invalidate(dailySalesProvider);
              ref.invalidate(topCustomersProvider);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          snapAsync.when(
            loading: () => const Center(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator())),
            error: (e, _) => Text('Error: $e'),
            data: (s) => _Kpis(snap: s),
          ),
          const SizedBox(height: 20),
          Text('Sales — last 30 days',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: salesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (points) => _SalesChart(points: points),
            ),
          ),
          const SizedBox(height: 24),
          Text('Top customers',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          topAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (list) {
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No invoiced customers yet.'),
                );
              }
              final top = list.first.totalSales;
              return Column(
                children: list
                    .map((c) => _TopCustomerRow(
                          name: c.name,
                          amount: c.totalSales,
                          pct: top > 0 ? c.totalSales / top : 0,
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Kpis extends StatelessWidget {
  final DashboardSnapshot snap;
  const _Kpis({required this.snap});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.8,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        _KpiCard(
          label: 'Cash in hand',
          value: formatMoney(snap.cashInHand),
          color: snap.cashInHand >= 0
              ? AppColors.digiGreen
              : AppColors.digiError,
          icon: Icons.payments_outlined,
        ),
        _KpiCard(
          label: 'Invoice revenue',
          value: formatMoney(snap.invoiceRevenue),
          sub: '${snap.invoiceCount} invoices',
          color: AppColors.digiRed,
          icon: Icons.receipt_long,
        ),
        _KpiCard(
          label: "You'll get",
          value: formatMoney(snap.totalReceivable),
          color: AppColors.digiGreen,
          icon: Icons.arrow_downward,
        ),
        _KpiCard(
          label: "You'll give",
          value: formatMoney(snap.totalPayable),
          color: AppColors.digiError,
          icon: Icons.arrow_upward,
        ),
        _KpiCard(
          label: 'Expenses',
          value: formatMoney(snap.totalExpenses),
          color: AppColors.digiError,
          icon: Icons.money_off,
        ),
        _KpiCard(
          label: 'Net (rev - exp)',
          value: formatMoney(snap.invoiceRevenue - snap.totalExpenses),
          color: snap.invoiceRevenue - snap.totalExpenses >= 0
              ? AppColors.digiGreen
              : AppColors.digiError,
          icon: Icons.trending_up,
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final Color color;
  final IconData icon;
  const _KpiCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          if (sub != null)
            Text(sub!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _SalesChart extends StatelessWidget {
  final List<DailySalesPoint> points;
  const _SalesChart({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(child: Text('No sales data yet.'));
    }
    final maxY = points
        .map((p) => p.total)
        .fold<double>(0, (m, v) => v > m ? v : m);
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY == 0 ? 10 : maxY * 1.1,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY == 0 ? 2 : maxY / 4,
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, meta) => Text(
                v == 0 ? '0' : formatMoney(v),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: (points.length / 5).ceilToDouble(),
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= points.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('d/M').format(points[i].day),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), points[i].total),
            ],
            isCurved: true,
            color: AppColors.digiRed,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.digiRed.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopCustomerRow extends StatelessWidget {
  final String name;
  final double amount;
  final double pct; // 0..1 relative to top customer
  const _TopCustomerRow({
    required this.name,
    required this.amount,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Text(formatMoney(amount),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 6,
              color: AppColors.digiRed,
              backgroundColor: AppColors.digiRed.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
