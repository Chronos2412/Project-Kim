import 'package:flutter/material.dart';
import 'package:project_kim/features/inventory/domain/erp_core.dart';
import 'package:project_kim/features/inventory/presentation/screens/erp_risk_list_screen.dart';

class ErpControlCenterScreen extends StatefulWidget {
  const ErpControlCenterScreen({super.key});

  @override
  State<ErpControlCenterScreen> createState() =>
      _ErpControlCenterScreenState();
}

class _ErpControlCenterScreenState extends State<ErpControlCenterScreen> {
  final ErpCore core = ErpCore();

  @override
  void initState() {
    super.initState();
    core.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: core,
      builder: (context, _) {
        final ai = core.ai;

        final health = ai.healthScore();
        final riskCount = ai.riskProducts().length;
        final criticalCount = ai.criticalStock().length;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Centro de Control ERP"),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: core.refresh,
              ),
            ],
          ),
          body: core.loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    const SizedBox(height: 12),

                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            _kpi(
                              title: "Salud",
                              value: "${health.toStringAsFixed(0)}%",
                              color: Colors.green,
                            ),

                            GestureDetector(
                              onTap: riskCount == 0
                                  ? null
                                  : () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ErpRiskListScreen(
                                            mode: "risk",
                                            core: core,
                                          ),
                                        ),
                                      );
                                      await core.refresh();
                                    },
                              child: Opacity(
                                opacity: riskCount == 0 ? 0.4 : 1,
                                child: _kpi(
                                  title: "En riesgo",
                                  value: riskCount.toString(),
                                  color: Colors.orange,
                                ),
                              ),
                            ),

                            GestureDetector(
                              onTap: criticalCount == 0
                                  ? null
                                  : () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ErpRiskListScreen(
                                            mode: "critical",
                                            core: core,
                                          ),
                                        ),
                                      );
                                      await core.refresh();
                                    },
                              child: Opacity(
                                opacity:
                                    criticalCount == 0 ? 0.4 : 1,
                                child: _kpi(
                                  title: "Críticos",
                                  value: criticalCount.toString(),
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          ai.insight(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Expanded(
                      child: ListView.builder(
                        itemCount: ai.topRiskProducts().length,
                        itemBuilder: (context, index) {
                          final p = ai.topRiskProducts()[index];
                          final risk = ai.riskLevel(p);

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: risk >= 70
                                  ? Colors.red
                                  : Colors.orange,
                              child: const Icon(
                                Icons.warning,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(p.name),
                            subtitle: Text(
                              "Stock: ${p.stockQuantity} / Min: ${p.minStockQuantity}",
                            ),
                            trailing: Text(
                              "${risk.toStringAsFixed(0)}%",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _kpi({
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(title),
      ],
    );
  }
}