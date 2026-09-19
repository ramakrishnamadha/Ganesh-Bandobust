import 'package:flutter/material.dart';
import 'package:ganesh_bandobust_mobile/models/resource_enums.dart';
import 'package:ganesh_bandobust_mobile/models/resource_models.dart';
import 'package:ganesh_bandobust_mobile/services/resource_mock_service.dart';
import 'request_detail_screen.dart';

class MyStationRequestsScreen extends StatefulWidget {
  final String userPoliceStationId;

  const MyStationRequestsScreen({Key? key, required this.userPoliceStationId}) : super(key: key);

  @override
  State<MyStationRequestsScreen> createState() => _MyStationRequestsScreenState();
}

class _MyStationRequestsScreenState extends State<MyStationRequestsScreen> {
  final ResourceMockService _service = ResourceMockService();

  @override
  Widget build(BuildContext context) {
    final List<ResourceRequest> requests = _service.getRequestsByStation(widget.userPoliceStationId);
    // sort by latest
    requests.sort((ResourceRequest a, ResourceRequest b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Station Requests'),
        backgroundColor: const Color(0xFF17365D),
        foregroundColor: Colors.white,
      ),
      body: requests.isEmpty
          ? const Center(child: Text('No requests found for your station.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final req = requests[index];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      '${req.quantityRequested}x ${req.resourceCategory.displayName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Status: ${req.status.displayName} | Priority: ${req.priority.displayName}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RequestDetailScreen(
                            requestId: req.id,
                          ),
                        ),
                      ).then((_) => setState(() {}));
                    },
                  ),
                );
              },
            ),
    );
  }
}
