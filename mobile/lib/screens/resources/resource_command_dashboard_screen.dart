import 'package:flutter/material.dart';
import '../../models/resource_enums.dart';
import '../../services/resource_mock_service.dart';
import 'resource_directory_screen.dart';

class ResourceCommandDashboardScreen extends StatefulWidget {
  final String userPoliceStationId;

  const ResourceCommandDashboardScreen({Key? key, required this.userPoliceStationId}) : super(key: key);

  @override
  State<ResourceCommandDashboardScreen> createState() => _ResourceCommandDashboardScreenState();
}

class _ResourceCommandDashboardScreenState extends State<ResourceCommandDashboardScreen> {
  final ResourceMockService _service = ResourceMockService();

  @override
  Widget build(BuildContext context) {
    final resources = _service.getResources();
    final requests = _service.getRequests();

    final availableCount = resources.where((r) => r.status == ResourceStatus.available).length;
    final deployedCount = resources.where((r) => r.status == ResourceStatus.deployed || r.status == ResourceStatus.enRoute).length;
    final openRequests = requests.where((r) => r.status == RequestStatus.open || r.status == RequestStatus.assigned).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource Command Center'),
        backgroundColor: const Color(0xFF17365D),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Status',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard('Available', availableCount.toString(), Colors.green),
                const SizedBox(width: 8),
                _buildStatCard('Deployed', deployedCount.toString(), Colors.blue),
                const SizedBox(width: 8),
                _buildStatCard('Open Reqs', openRequests.toString(), Colors.orange),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Management',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF17365D),
                  child: Icon(Icons.folder_shared, color: Colors.white),
                ),
                title: const Text('Resource Directory', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Browse all assets across all stations'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ResourceDirectoryScreen(
                        userPoliceStationId: widget.userPoliceStationId,
                        role: ResourceUserRole.commander,
                      ),
                    ),
                  ).then((_) => setState(() {}));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, MaterialColor color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.shade200),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color.shade700)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color.shade700)),
          ],
        ),
      ),
    );
  }
}
