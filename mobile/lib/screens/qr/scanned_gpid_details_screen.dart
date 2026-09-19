import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../festivity/festivity_check_screen.dart';
import '../immersion/immersion_workflow_screen.dart';

class ScannedGpidDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> record;
  final AuthenticatedUser authenticatedUser;
  final bool allowStageSelection;
  final int defaultStage;
  final void Function(int selectedStage)? onStartChecking;

  const ScannedGpidDetailsScreen({
    super.key,
    required this.record,
    required this.authenticatedUser,
    this.allowStageSelection = false,
    this.defaultStage = 3,
    this.onStartChecking,
  });

  @override
  State<ScannedGpidDetailsScreen> createState() => _ScannedGpidDetailsScreenState();
}

class _ScannedGpidDetailsScreenState extends State<ScannedGpidDetailsScreen> {
  late int _selectedStage;

  @override
  void initState() {
    super.initState();
    _selectedStage = widget.defaultStage;
  }

  String _display(dynamic value) {
    if (value == null) return 'N/A';
    final str = value.toString().trim();
    return str.isEmpty ? 'N/A' : str;
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startChecking() {
    if (widget.onStartChecking != null) {
      widget.onStartChecking!(_selectedStage);
    } else {
      // Default fallback routing
      final actualGpid = widget.record['unique_id']?.toString() ?? '';
      if (_selectedStage == 4) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ImmersionWorkflowScreen(
              applicationId: actualGpid,
              ganeshRecord: widget.record,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (_) => FestivityCheckScreen(
              applicationId: actualGpid,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF17365D),
        foregroundColor: Colors.white,
        title: const Text(
          'Scanned GPID Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFCBD5E1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Ganesh Mandap',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _display(widget.record['unique_id']),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF17365D),
                  ),
                ),
                const SizedBox(height: 9),
                _detailRow('Organizer', _display(widget.record['name'])),
                _detailRow('Association', _display(widget.record['association'])),
                _detailRow('Police Station', _display(widget.record['ps_name'])),
                _detailRow('Division', _display(widget.record['division_name'])),
                _detailRow('Zone', _display(widget.record['zone_name'])),
              ],
            ),
          ),
          
          if (widget.allowStageSelection) ...[
            const SizedBox(height: 24),
            const Text(
              'Select Festival Stage',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: _selectedStage,
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF17365D)),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Stage 1: Pre-Installation')),
                    DropdownMenuItem(value: 2, child: Text('Stage 2: Installation')),
                    DropdownMenuItem(value: 3, child: Text('Stage 3: During Festivity')),
                    DropdownMenuItem(value: 4, child: Text('Stage 4: Immersion')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedStage = val;
                      });
                    }
                  },
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _startChecking,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF17365D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.fact_check_outlined),
              label: Text(
                widget.allowStageSelection 
                    ? 'START STAGE-$_selectedStage CHECKING' 
                    : 'START STAGE-${widget.defaultStage} CHECKING',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
