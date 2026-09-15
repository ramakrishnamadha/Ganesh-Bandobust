import 'package:flutter/material.dart';
import '../../models/resource_models.dart';
import '../../services/resource_mock_service.dart';

class ResourceDetailScreen extends StatelessWidget {
  final ResourceItem resource;

  const ResourceDetailScreen({Key? key, required this.resource}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = ResourceMockService();
    final owningPS = service.getPoliceStationById(resource.owningPoliceStationId);
    final currentPS = service.getPoliceStationById(resource.currentHoldingPoliceStationId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource Details'),
        backgroundColor: const Color(0xFF17365D),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              resource.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF17365D)),
            ),
            const SizedBox(height: 16),
            _buildInfoCard('Category', resource.category.displayName),
            _buildInfoCard('Status', resource.status.displayName),
            _buildInfoCard('Condition', resource.condition.displayName),
            const SizedBox(height: 16),
            const Text('Location Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildInfoCard('Owning Station', owningPS?.name ?? 'Unknown'),
            _buildInfoCard('Current Holding Station', currentPS?.name ?? 'Unknown'),
            if (resource.notes != null && resource.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(resource.notes!),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
