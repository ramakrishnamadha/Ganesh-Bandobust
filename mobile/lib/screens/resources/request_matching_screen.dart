import 'package:flutter/material.dart';
import '../../models/resource_enums.dart';
import '../../services/resource_mock_service.dart';

class RequestMatchingScreen extends StatefulWidget {
  final String requestId;

  const RequestMatchingScreen({Key? key, required this.requestId}) : super(key: key);

  @override
  State<RequestMatchingScreen> createState() => _RequestMatchingScreenState();
}

class _RequestMatchingScreenState extends State<RequestMatchingScreen> {
  final ResourceMockService _service = ResourceMockService();

  @override
  Widget build(BuildContext context) {
    final request = _service.getRequests().firstWhere((r) => r.id == widget.requestId);
    final available = _service.findNearestAvailableResources(request.latitude, request.longitude, request.category);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matching Resources'),
        backgroundColor: const Color(0xFF17365D),
        foregroundColor: Colors.white,
      ),
      body: available.isEmpty
          ? const Center(child: Text('No available resources found for this category.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: available.length,
              itemBuilder: (context, index) {
                final res = available[index];
                final holdingStation = _service.getPoliceStationById(res.currentHoldingPoliceStationId);
                final dist = _service.calculateDistance(
                  request.latitude,
                  request.longitude,
                  holdingStation?.latitude ?? request.latitude,
                  holdingStation?.longitude ?? request.longitude,
                );

                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(res.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('At: ${holdingStation?.name ?? 'Unknown'}\nDistance: ${dist.toStringAsFixed(1)} km'),
                    isThreeLine: true,
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF17365D),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        _assignResource(request.id, res.id);
                      },
                      child: const Text('Assign'),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _assignResource(String reqId, String resId) {
    _service.updateRequestStatus(reqId, RequestStatus.assigned, assignedResourceId: resId);
    _service.updateResourceStatus(resId, ResourceStatus.deployed);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resource assigned successfully!')),
    );
    Navigator.pop(context);
  }
}
