import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/database/database_helper.dart';
import '../core/providers/language_provider.dart';
import '../models/procedure.dart';

class ProcedureDetailScreen extends StatelessWidget {
  final String procedureKey;

  const ProcedureDetailScreen({
    super.key,
    required this.procedureKey,
  });

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final isRtl = lang.currentLanguage == AppLanguage.arabic ||
        lang.currentLanguage == AppLanguage.darija;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Procedure Details',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
        ),
        body: FutureBuilder<Procedure?>(
          future: DatabaseHelper.instance.getProcedure(procedureKey),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final procedure = snapshot.data;
            if (procedure == null) {
              return const Center(
                child: Text('Procedure not found.'),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.assignment_turned_in,
                          color: Color(0xFF1E3A8A),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              procedure.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              procedure.description,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoGrid(procedure),
                  const SizedBox(height: 20),
                  _buildSection('Steps', procedure.steps),
                  const SizedBox(height: 20),
                  _buildSection(
                    'Required Documents',
                    procedure.requiredDocuments,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Important Notes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    procedure.importantNotes,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoGrid(Procedure procedure) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _infoCard(Icons.payments_outlined, 'Cost', procedure.cost),
        _infoCard(Icons.schedule_outlined, 'Time', procedure.timeRequired),
        _infoCard(Icons.place_outlined, 'Where', procedure.whereToGo),
      ],
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return SizedBox(
      width: 180,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.check_circle,
                    color: Color(0xFF1D9E75),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item, style: const TextStyle(height: 1.4)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
