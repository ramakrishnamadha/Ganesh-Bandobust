import 'package:flutter/material.dart';

class CheckingSelectionScreen extends StatelessWidget {
  final String officerName;
  final String role;
  final String scopeLabel;
  final VoidCallback onGpidBasedChecking;
  final VoidCallback onMapBasedChecking;
  final VoidCallback? onQrBasedChecking;

  const CheckingSelectionScreen({
    super.key,
    required this.officerName,
    required this.role,
    required this.scopeLabel,
    required this.onGpidBasedChecking,
    required this.onMapBasedChecking,
    this.onQrBasedChecking,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF17365D),
        foregroundColor: Colors.white,
        title: const Text(
          'Checking',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
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
                color: const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Logged-in Officer',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  officerName,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF17365D),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _chip(role),
                    if (scopeLabel.trim().isNotEmpty)
                      _chip(scopeLabel),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          const Text(
            'Select Checking Method',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Select a GPID through jurisdiction hierarchy or locate a geo-tagged Ganesh Mandap on the map.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 18),

          _checkingCard(
            icon: Icons.account_tree_outlined,
            title: 'GPID Based Checking',
            subtitle:
                'Select through role-based hierarchy and choose the GPID to start Stage-3 checking.',
            buttonText: 'SELECT GPID',
            onTap: onGpidBasedChecking,
          ),

          const SizedBox(height: 14),

          _checkingCard(
            icon: Icons.map_outlined,
            title: 'Map / Geo-Tagged Mandap Checking',
            subtitle:
                'View your location and accessible geo-tagged Mandaps. Tap an Idol marker to start checking.',
            buttonText: 'OPEN MAP',
            onTap: onMapBasedChecking,
          ),

          if (onQrBasedChecking != null) ...[
            const SizedBox(height: 14),
            _checkingCard(
              icon: Icons.qr_code_scanner,
              title: 'QR Code Mandap Checking',
              subtitle:
                  'Scan the Mandap GPID QR code to verify jurisdiction and immediately start checking.',
              buttonText: 'SCAN QR CODE',
              onTap: onQrBasedChecking!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _checkingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 29,
                  color: const Color(0xFF17365D),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF17365D),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: Color(0xFF17365D),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}