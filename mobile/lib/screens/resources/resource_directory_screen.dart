import 'package:flutter/material.dart';
import '../../models/resource_enums.dart';
import '../../models/resource_models.dart';
import '../../services/resource_mock_service.dart';
import 'resource_detail_screen.dart';
import 'raise_resource_request_screen.dart';

class ResourceDirectoryScreen extends StatefulWidget {
  final String userPoliceStationId;
  final ResourceUserRole role;

  const ResourceDirectoryScreen({
    Key? key,
    required this.userPoliceStationId,
    this.role = ResourceUserRole.fieldOfficer,
  }) : super(key: key);

  @override
  State<ResourceDirectoryScreen> createState() => _ResourceDirectoryScreenState();
}

class _ResourceDirectoryScreenState extends State<ResourceDirectoryScreen> {
  final ResourceMockService _service = ResourceMockService();
  String _searchQuery = '';
  ResourceCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    List<ResourceItem> items = _service.getResources();

    if (_searchQuery.isNotEmpty) {
      items = items
          .where((item) =>
              item.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_selectedCategory != null) {
      items = items.where((item) => item.category == _selectedCategory).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource Directory'),
        backgroundColor: const Color(0xFF17365D),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF17365D),
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RaiseResourceRequestScreen(
                userPoliceStationId: widget.userPoliceStationId,
              ),
            ),
          ).then((_) => setState(() {}));
        },
        icon: const Icon(Icons.add),
        label: const Text('Request Resource'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search resources...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<ResourceCategory?>(
                      value: _selectedCategory,
                      hint: const Text('All Categories'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All'),
                        ),
                        ...ResourceCategory.values.map(
                          (cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat.displayName),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedCategory = val;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No resources found.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                              '${item.category.displayName} • ${item.status.displayName}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ResourceDetailScreen(
                                  resource: item,
                                ),
                              ),
                            ).then((_) => setState(() {}));
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
