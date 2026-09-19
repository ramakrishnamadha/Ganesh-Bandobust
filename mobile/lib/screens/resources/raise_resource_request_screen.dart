import 'package:flutter/material.dart';
import 'package:ganesh_bandobust_mobile/models/resource_enums.dart';
import 'package:ganesh_bandobust_mobile/models/resource_models.dart';
import 'package:ganesh_bandobust_mobile/services/resource_mock_service.dart';

class RaiseResourceRequestScreen extends StatefulWidget {
  final String userPoliceStationId;

  const RaiseResourceRequestScreen({Key? key, required this.userPoliceStationId}) : super(key: key);

  @override
  State<RaiseResourceRequestScreen> createState() => _RaiseResourceRequestScreenState();
}

class _RaiseResourceRequestScreenState extends State<RaiseResourceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  
  ResourceCategory? _selectedCategory;
  RequestPriority? _selectedPriority;
  int _quantity = 1;
  String _timeframe = 'Immediate';
  double _lat = 17.3850;
  double _lng = 78.4000; // Mock coordinates for now

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Resource'),
        backgroundColor: const Color(0xFF17365D),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Resource Category', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<ResourceCategory>(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                hint: const Text('Select Category'),
                items: ResourceCategory.values
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat.displayName)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                validator: (val) => val == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),
              const Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: '1',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onChanged: (val) => _quantity = int.tryParse(val) ?? 1,
                validator: (val) {
                  if (val == null || int.tryParse(val) == null || int.parse(val) <= 0) {
                    return 'Enter a valid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<RequestPriority>(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                hint: const Text('Select Priority'),
                items: RequestPriority.values
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.displayName)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedPriority = val),
                validator: (val) => val == null ? 'Please select priority' : null,
              ),
              const SizedBox(height: 16),
              const Text('Required Timeframe', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _timeframe,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'e.g., Today 5 PM, Immediate'),
                onChanged: (val) => _timeframe = val,
                validator: (val) => (val == null || val.isEmpty) ? 'Please enter a timeframe' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF17365D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _submitRequest,
                child: const Text('Submit Request', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitRequest() {
    if (_formKey.currentState!.validate()) {
      final req = ResourceRequest(
        id: 'REQ${DateTime.now().millisecondsSinceEpoch}',
              requestingPoliceStationId: widget.userPoliceStationId,
        category: _selectedCategory!,
        quantity: _quantity,
        latitude: _lat,
        longitude: _lng,
        requiredTimeframe: _timeframe,
        priority: _selectedPriority!,
        status: RequestStatus.open,
        createdAt: DateTime.now(),
      );

      ResourceMockService().addRequest(req);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted successfully!')),
      );
      Navigator.pop(context);
    }
  }
}
