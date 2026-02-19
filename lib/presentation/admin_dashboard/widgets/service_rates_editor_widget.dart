import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:convert';

class ServiceRatesEditorWidget extends StatefulWidget {
  final Map<String, dynamic> initialRates;
  final Function(Map<String, dynamic>) onSave;

  const ServiceRatesEditorWidget({
    super.key,
    required this.initialRates,
    required this.onSave,
  });

  @override
  State<ServiceRatesEditorWidget> createState() => _ServiceRatesEditorWidgetState();
}

class _ServiceRatesEditorWidgetState extends State<ServiceRatesEditorWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, dynamic> _rates;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _rates = Map<String, dynamic>.from(json.decode(json.encode(widget.initialRates)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Tarifas'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Por Milla (Regional)'),
            Tab(text: 'Por Hora (Paquetes)'),
            Tab(text: 'Aeropuertos'),
            Tab(text: 'Inter-City'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMileageTab(),
          _buildHourlyTab(),
          _buildAirportTab(),
          _buildInterCityTab(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(4.w),
        child: ElevatedButton(
          onPressed: () => widget.onSave(_rates),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 6.h),
            backgroundColor: const Color(0xFF8B1538),
            foregroundColor: Colors.white,
          ),
          child: const Text('Aplicar Cambios'),
        ),
      ),
    );
  }

  Widget _buildMileageTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        _buildSectionHeader('Miami / Broward (BLACK SUV)'),
        _buildRateRow('Base', 'black_suv_regional', 'miami_broward', 'base'),
        _buildRateRow('Milla', 'black_suv_regional', 'miami_broward', 'per_mile'),
        _buildRateRow('Mínimo', 'black_suv_regional', 'miami_broward', 'min_tariff'),
        
        SizedBox(height: 3.h),
        _buildSectionHeader('Orlando (BLACK SUV)'),
        _buildRateRow('Base', 'black_suv_regional', 'orlando', 'base'),
        _buildRateRow('Milla', 'black_suv_regional', 'orlando', 'per_mile'),
        _buildRateRow('Mínimo', 'black_suv_regional', 'orlando', 'min_tariff'),

        SizedBox(height: 3.h),
        _buildSectionHeader('Miami / Broward (BLACK)'),
        _buildRateRow('Base', 'black', 'miami_broward', 'base'),
        _buildRateRow('Milla', 'black', 'miami_broward', 'per_mile'),
        _buildRateRow('Mínimo', 'black', 'miami_broward', 'min_tariff'),
      ],
    );
  }

  Widget _buildHourlyTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        _buildSectionHeader('Miami / Broward'),
        _buildRateRow('Precio Hora', 'black_hourly', 'miami_broward', 'unit'),
        _buildRateRow('Mín. Horas', 'black_hourly', 'miami_broward', 'min_hours', isInt: true),
        _buildTiersEditor('black_hourly', 'miami_broward'),

        SizedBox(height: 3.h),
        _buildSectionHeader('Orlando'),
        _buildRateRow('Precio Hora', 'black_hourly', 'orlando', 'unit'),
        _buildRateRow('Mín. Horas', 'black_hourly', 'orlando', 'min_hours', isInt: true),
        _buildTiersEditor('black_hourly', 'orlando'),
      ],
    );
  }

  Widget _buildAirportTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        for (var airport in ['mia', 'fll', 'mco']) ...[
          _buildSectionHeader(airport.toUpperCase()),
          _buildAirportRatesEditor(airport),
          SizedBox(height: 3.h),
        ],
      ],
    );
  }

  Widget _buildInterCityTab() {
    final routes = _rates['black_inter_city'] as Map<String, dynamic>? ?? {};
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        _buildSectionHeader('Tarifas Entre Ciudades'),
        ...routes.entries.map((e) => _buildSimpleRateRow(e.key, 'black_inter_city', e.key)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildRateRow(String label, String service, String region, String field, {bool isInt = false}) {
    final val = _rates[service]?[region]?[field] ?? 0;
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label)),
          Expanded(
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              controller: TextEditingController(text: val.toString()),
              onChanged: (v) {
                final numVal = isInt ? int.tryParse(v) : double.tryParse(v);
                if (numVal != null) {
                  setState(() {
                    _rates[service] ??= {};
                    _rates[service][region] ??= {};
                    _rates[service][region][field] = numVal;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleRateRow(String label, String service, String field) {
    final val = _rates[service]?[field] ?? 0;
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: const TextStyle(fontSize: 12))),
          Expanded(
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              controller: TextEditingController(text: val.toString()),
              onChanged: (v) {
                final numVal = double.tryParse(v);
                if (numVal != null) {
                  setState(() {
                    _rates[service] ??= {};
                    _rates[service][field] = numVal;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTiersEditor(String service, String region) {
    final tiers = _rates[service]?[region]?['tiers'] as Map<String, dynamic>? ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Paquetes Horas:', style: TextStyle(fontWeight: FontWeight.w600)),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          children: tiers.entries.map((e) => SizedBox(
            width: 25.w,
            child: TextField(
              decoration: InputDecoration(labelText: e.key, border: const OutlineInputBorder(), isDense: true),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: e.value.toString()),
              onChanged: (v) {
                final numVal = double.tryParse(v);
                if (numVal != null) {
                  setState(() => _rates[service][region]['tiers'][e.key] = numVal);
                }
              },
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildAirportRatesEditor(String airport) {
    final airportData = _rates['black_airport_fixed']?[airport] as Map<String, dynamic>? ?? {};
    return Column(
      children: airportData.entries.map((e) => Padding(
        padding: EdgeInsets.only(bottom: 1.h),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text(e.key, style: const TextStyle(fontSize: 11))),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                controller: TextEditingController(text: e.value.toString()),
                onChanged: (v) {
                  final numVal = double.tryParse(v);
                  if (numVal != null) {
                    setState(() => _rates['black_airport_fixed'][airport][e.key] = numVal);
                  }
                },
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}
