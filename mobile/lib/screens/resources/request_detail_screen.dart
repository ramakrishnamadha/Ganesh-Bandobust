import 'package:flutter/material.dart';
import '../../models/resource_enums.dart';
import '../../models/resource_models.dart';
import '../../services/resource_mock_service.dart';
import 'request_matching_screen.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;

  const RequestDetailScreen({Key? key, required this.requestId}) : super(key: key);

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  final ResourceMockService _service = ResourceMockService();

  @override
  Widget build(BuildContext context) {
    final requestList = _service.getRequests();
    final index = requestList.indexWhere((r) => r.id == widget.requestId);
    if (index == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Request Details')),
        body: const Center(child: Text('Request not found.')),
      );
    }
    
    final request = requestList[index];
    final ps = _service.getPoliceStationById(request.requestingPoliceStationId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
        backgroundColor: const Color(0xFF17365D),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${request.quantity}x ${request.category.displayName}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF17365D)),
            ),
            const SizedBox(height: 16),
            _buildInfoCard('Status', request.status.displayName),
            _buildInfoCard('Priority', request.priority.displayName),
            _buildInfoCard('Timeframe', request.requiredTimeframe),
            _buildInfoCard('Requesting PS', ps?.name ?? 'Unknown'),
            if (request.assignedResourceId != null)
              _buildInfoCard('Assigned Resource ID', request.assignedResourceId!),
            const SizedBox(height: 32),
            if (request.status == RequestStatus.open)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RequestMatchingScreen(requestId: request.id),
                    ),
                  ).then((_) => setState(() {}));
                },
                child: const Text('Find Matching Resource'),
              ),
            if (request.status == RequestStatus.assigned)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  _service.updateRequestStatus(request.id, RequestStatus.enRoute);
                  setState(() {});
                },
                child: const Text('Mark En Route'),
              ),
            if (request.status == RequestStatus.enRoute)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  _service.updateRequestStatus(request.id, RequestStatus.onSite);
                  setState(() {});
                },
                child: const Text('Mark On Site'),
              ),
            if (request.status == RequestStatus.onSite)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  _service.updateRequestStatus(request.id, RequestStatus.inUse);
                  setState(() {});
                },
                child: const Text('Mark In Use'),
              ),
            if (request.status == RequestStatus.inUse)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  _service.updateRequestStatus(request.id, RequestStatus.released);
                  setState(() {});
                },
                child: const Text('Release Resource'),
              ),
            if (request.status == RequestStatus.released)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  _service.updateRequestStatus(request.id, RequestStatus.returned);
                  if (request.assignedResourceId != null) {
                    final res = _service.getResources().firstWhere((r) => r.id == request.assignedResourceId);
                    _service.updateResourceStatus(res.id, ResourceStatus.available, holdingStationId: res.owningPoliceStationId);
                  }
                  setState(() {});
                },
                child: const Text('Mark Returned'),
              ),
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
