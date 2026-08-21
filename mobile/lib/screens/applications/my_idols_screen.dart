import 'package:flutter/material.dart';
import 'application_details_screen.dart';

class MyIdolsScreen extends StatelessWidget {
  const MyIdolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final applications = [
      {
        'id': 'GH2026-0001',
        'organizer': 'Sri Ganesh Youth Association',
        'location': 'Main Road, Hyderabad',
        'status': 'Pending Verification',
      },
      {
        'id': 'GH2026-0002',
        'organizer': 'Sri Balaji Youth Association',
        'location': 'Temple Road, Hyderabad',
        'status': 'Pending Verification',
      },
      {
        'id': 'GH2026-0003',
        'organizer': 'Friends Ganesh Association',
        'location': 'Market Road, Hyderabad',
        'status': 'Pending Verification',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Idols'),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: applications.length,

        itemBuilder: (context, index) {
          final application = applications[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),

            child: ListTile(
              contentPadding: const EdgeInsets.all(16),

              leading: const CircleAvatar(
                backgroundColor: Color(0xFF17365D),

                child: Icon(
                  Icons.temple_hindu,
                  color: Colors.white,
                ),
              ),

              title: Text(
                application['id']!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              subtitle: Padding(
                padding: const EdgeInsets.only(top: 7),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(application['organizer']!),
                    Text(application['location']!),

                    const SizedBox(height: 5),

                    Text(
                      application['status']!,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              trailing:
                  const Icon(Icons.chevron_right),

              onTap: () {
                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (_) =>
                        ApplicationDetailsScreen(
                      applicationId:
                          application['id']!,
                      organizer:
                          application['organizer']!,
                      location:
                          application['location']!,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}