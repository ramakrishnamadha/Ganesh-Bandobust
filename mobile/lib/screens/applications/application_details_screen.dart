import 'package:flutter/material.dart';

import '../festivity/festivity_check_screen.dart';
import '../installation/installation_check_screen.dart';
import '../pre_installation/pre_installation_screen.dart';

class ApplicationDetailsScreen extends StatelessWidget {
  final String applicationId;
  final String organizer;
  final String location;

  const ApplicationDetailsScreen({
    super.key,
    required this.applicationId,
    required this.organizer,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Application ID',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      applicationId,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 28),
                    const Text(
                      'Organizer',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(organizer),
                    const SizedBox(height: 16),
                    const Text(
                      'Installation Location',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(location),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Verification',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF17365D),
                  child: Text(
                    '1',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                title: const Text(
                  'Pre-Installation Verification',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Ready for field verification',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PreInstallationScreen(
                        applicationId: applicationId,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF17365D),
                  child: Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                title: const Text(
                  'Installation Checking',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Stage 2 field checking',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InstallationCheckScreen(
                        applicationId: applicationId,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF17365D),
                  child: Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                title: const Text(
                  'Festivity Checking',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Stage 3 daily festivity checking',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FestivityCheckScreen(
                        applicationId: applicationId,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
