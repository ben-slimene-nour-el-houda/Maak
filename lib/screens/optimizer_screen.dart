import 'package:flutter/material.dart';
import '../data/crowd_data.dart';
import '../services/optimizer_service.dart';
import '../widgets/heatmap_grid.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/feedback_bottom_sheet.dart';
import 'cv_navigation_screen.dart';

class OptimizerScreen extends StatefulWidget {
  const OptimizerScreen({super.key});

  @override
  State<OptimizerScreen> createState() => _OptimizerScreenState();
}

class _OptimizerScreenState extends State<OptimizerScreen> {
  String _selectedOffice = 'CNSS Tunis';
  String _selectedProcedure = 'Renouvellement CIN';

  List<BestSlot> _topSlots = [];
  Map<String, List<double>> _heatmap = {};
  bool _loading = true;

  final List<String> _offices = crowdData.keys.toList();
  final List<String> _procedures = procedureWeights.keys.toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final slots = await OptimizerService.getTopSlots(
      _selectedOffice, procedure: _selectedProcedure);
    final heatmap = await OptimizerService.getHeatmapScores(
      _selectedOffice, procedure: _selectedProcedure);
    setState(() {
      _topSlots = slots;
      _heatmap = heatmap;
      _loading = false;
    });
  }

  void _onCellTap(String day, int slotIndex) {
    showModalBottomSheet(
      context: context,
      builder: (_) => FeedbackBottomSheet(
        office: _selectedOffice,
        day: day,
        slotIndex: slotIndex,
      ),
    ).then((_) => _load()); // reload after feedback
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meilleur moment pour visiter')),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Office picker
                DropdownButtonFormField<String>(
                  value: _selectedOffice,
                  decoration: const InputDecoration(
                    labelText: 'Bureau',
                    border: OutlineInputBorder(),
                  ),
                  items: _offices.map((o) =>
                    DropdownMenuItem(value: o, child: Text(o))).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() { _selectedOffice = v; });
                    _load();
                  },
                ),
                const SizedBox(height: 12),

                // Procedure picker
                DropdownButtonFormField<String>(
                  value: _selectedProcedure,
                  decoration: const InputDecoration(
                    labelText: 'Démarche',
                    border: OutlineInputBorder(),
                  ),
                  items: _procedures.map((p) =>
                    DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() { _selectedProcedure = v; });
                    _load();
                  },
                ),
                const SizedBox(height: 20),

                // Best slot card
                if (_topSlots.isNotEmpty)
                  RecommendationCard(slot: _topSlots.first),
                const SizedBox(height: 20),

                const Text('Carte de fréquentation',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('Appuyez sur un créneau pour laisser un avis',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),

                // Heatmap
                HeatmapGrid(scores: _heatmap, onCellTap: _onCellTap),
                const SizedBox(height: 24),

                // Top 3 list
                const Text('Top 3 créneaux',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ..._topSlots.map((slot) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1D9E75),
                    child: Text(
                      '${_topSlots.indexOf(slot) + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text('${slot.day} à ${slot.timeLabel}'),
                  subtitle: Text(slot.feedbackCount > 0
                    ? 'Basé sur ${slot.feedbackCount} avis'
                    : 'Données historiques'),
                  trailing: Text('${slot.score.toInt()}%',
                    style: TextStyle(
                      color: slot.score < 40
                        ? const Color(0xFF4CAF50)
                        : slot.score < 70
                          ? const Color(0xFFFFC107)
                          : const Color(0xFFF44336),
                      fontWeight: FontWeight.w600,
                    )),
                )),
              ],
            ),
          ),

      // FAB to open CV navigation — passes current office as AR target
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CVNavigationScreen(
              targetGuichet: _selectedOffice,
            ),
          ),
        ),
        icon: const Icon(Icons.camera_alt),
        label: const Text('Je suis sur place'),
        backgroundColor: const Color(0xFF1D9E75),
      ),
    );
  }
}
