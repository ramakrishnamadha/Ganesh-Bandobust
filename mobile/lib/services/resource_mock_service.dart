import 'dart:math';

import '../models/resource_enums.dart';
import '../models/resource_models.dart';

class ResourceMockService {
  static final ResourceMockService _instance = ResourceMockService._internal();

  factory ResourceMockService() {
    return _instance;
  }

  ResourceMockService._internal();

  // In-memory data store
  final List<PoliceStation> _policeStations = [
    const PoliceStation(id: 'PS001', name: 'Charminar PS', latitude: 17.3616, longitude: 78.4747),
    const PoliceStation(id: 'PS002', name: 'Golconda PS', latitude: 17.3833, longitude: 78.4011),
    const PoliceStation(id: 'PS003', name: 'Banjara Hills PS', latitude: 17.4156, longitude: 78.4357),
    const PoliceStation(id: 'PS004', name: 'Jubilee Hills PS', latitude: 17.4326, longitude: 78.4071),
  ];

  late final List<ResourceItem> _resources = [
    ResourceItem(
      id: 'RES001',
      name: 'Heavy Duty Crane 1',
      category: ResourceCategory.crane,
      owningPoliceStationId: 'PS001',
      currentHoldingPoliceStationId: 'PS001',
      status: ResourceStatus.available,
      condition: ResourceCondition.good,
    ),
    ResourceItem(
      id: 'RES002',
      name: 'Barricade Set A',
      category: ResourceCategory.barricade,
      owningPoliceStationId: 'PS002',
      currentHoldingPoliceStationId: 'PS003',
      status: ResourceStatus.deployed,
      condition: ResourceCondition.fair,
    ),
    ResourceItem(
      id: 'RES003',
      name: 'Generator 50kVA',
      category: ResourceCategory.generator,
      owningPoliceStationId: 'PS004',
      currentHoldingPoliceStationId: 'PS004',
      status: ResourceStatus.underMaintenance,
      condition: ResourceCondition.needsRepair,
    ),
    ResourceItem(
      id: 'RES004',
      name: 'Water Tanker 1',
      category: ResourceCategory.waterTanker,
      owningPoliceStationId: 'PS003',
      currentHoldingPoliceStationId: 'PS003',
      status: ResourceStatus.available,
      condition: ResourceCondition.good,
    ),
  ];

  final List<ResourceRequest> _requests = [
    ResourceRequest(
      id: 'REQ001',
      requestingPoliceStationId: 'PS002',
      category: ResourceCategory.crane,
      quantity: 1,
      latitude: 17.3850,
      longitude: 78.4000,
      requiredTimeframe: 'Immediate',
      priority: RequestPriority.urgent,
      status: RequestStatus.open,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  // Methods
  List<PoliceStation> getPoliceStations() {
    return _policeStations;
  }

  PoliceStation? getPoliceStationById(String id) {
    try {
      return _policeStations.firstWhere((ps) => ps.id == id);
    } catch (e) {
      return null;
    }
  }

  List<ResourceItem> getResources() {
    return _resources;
  }

  List<ResourceItem> getResourcesByStation(String stationId) {
    return _resources.where((r) => r.currentHoldingPoliceStationId == stationId).toList();
  }

  List<ResourceRequest> getRequests() {
    return _requests;
  }

  List<ResourceRequest> getRequestsByStation(String stationId) {
    return _requests.where((r) => r.requestingPoliceStationId == stationId).toList();
  }

  void addRequest(ResourceRequest request) {
    _requests.add(request);
  }

  void updateRequestStatus(String requestId, RequestStatus newStatus, {String? assignedResourceId}) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _requests[index] = _requests[index].copyWith(
        status: newStatus,
        assignedResourceId: assignedResourceId ?? _requests[index].assignedResourceId,
      );
    }
  }

  void updateResourceStatus(String resourceId, ResourceStatus newStatus, {String? holdingStationId}) {
    final index = _resources.indexWhere((r) => r.id == resourceId);
    if (index != -1) {
      _resources[index] = _resources[index].copyWith(
        status: newStatus,
        currentHoldingPoliceStationId: holdingStationId,
      );
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  List<ResourceItem> findNearestAvailableResources(double lat, double lon, ResourceCategory category) {
    final available = _resources.where((r) => r.category == category && r.status == ResourceStatus.available).toList();

    available.sort((a, b) {
      final psA = getPoliceStationById(a.currentHoldingPoliceStationId);
      final psB = getPoliceStationById(b.currentHoldingPoliceStationId);

      if (psA == null) return 1;
      if (psB == null) return -1;

      final distA = calculateDistance(lat, lon, psA.latitude, psA.longitude);
      final distB = calculateDistance(lat, lon, psB.latitude, psB.longitude);

      return distA.compareTo(distB);
    });

    return available;
  }
}
