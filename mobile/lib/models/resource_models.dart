import 'resource_enums.dart';

class PoliceStation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  const PoliceStation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

class ResourceItem {
  final String id;
  final String name;
  final ResourceCategory category;
  final String owningPoliceStationId;
  final String currentHoldingPoliceStationId;
  final ResourceStatus status;
  final ResourceCondition condition;
  final String? notes;

  const ResourceItem({
    required this.id,
    required this.name,
    required this.category,
    required this.owningPoliceStationId,
    required this.currentHoldingPoliceStationId,
    required this.status,
    required this.condition,
    this.notes,
  });

  ResourceItem copyWith({
    String? currentHoldingPoliceStationId,
    ResourceStatus? status,
    ResourceCondition? condition,
    String? notes,
  }) {
    return ResourceItem(
      id: id,
      name: name,
      category: category,
      owningPoliceStationId: owningPoliceStationId,
      currentHoldingPoliceStationId:
          currentHoldingPoliceStationId ?? this.currentHoldingPoliceStationId,
      status: status ?? this.status,
      condition: condition ?? this.condition,
      notes: notes ?? this.notes,
    );
  }
}

class ResourceRequest {
  final String id;
  final String requestingPoliceStationId;
  final ResourceCategory category;
  final int quantity;
  final double latitude;
  final double longitude;
  final String requiredTimeframe;
  final RequestPriority priority;
  final RequestStatus status;
  final String? assignedResourceId;
  final DateTime createdAt;

  // Compatibility aliases
  String get raisingPoliceStationId => requestingPoliceStationId;
  ResourceCategory get resourceCategory => category;
  int get quantityRequested => quantity;
  double get siteLatitude => latitude;
  double get siteLongitude => longitude;

  const ResourceRequest({
    required this.id,
    required this.requestingPoliceStationId,
    required this.category,
    required this.quantity,
    required this.latitude,
    required this.longitude,
    required this.requiredTimeframe,
    required this.priority,
    required this.status,
    this.assignedResourceId,
    required this.createdAt,
  });

  ResourceRequest copyWith({
    RequestStatus? status,
    String? assignedResourceId,
  }) {
    return ResourceRequest(
      id: id,
      requestingPoliceStationId: requestingPoliceStationId,
      category: category,
      quantity: quantity,
      latitude: latitude,
      longitude: longitude,
      requiredTimeframe: requiredTimeframe,
      priority: priority,
      status: status ?? this.status,
      assignedResourceId: assignedResourceId ?? this.assignedResourceId,
      createdAt: createdAt,
    );
  }
}
