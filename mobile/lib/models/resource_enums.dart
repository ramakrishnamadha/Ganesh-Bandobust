enum ResourceCategory {
  crane('Crane'),
  gasCutter('Gas Cutter'),
  jcb('JCB'),
  waterTanker('Water Tanker'),
  fireTender('Fire Tender'),
  ambulance('Ambulance'),
  diver('Diver'),
  boat('Boat'),
  barricade('Barricade'),
  floodlight('Floodlight'),
  generator('Generator'),
  towTruck('Tow Truck'),
  operator('Operator');

  final String displayName;
  const ResourceCategory(this.displayName);
}

enum ResourceStatus {
  available('Available'),
  deployed('Deployed'),
  enRoute('En Route'),
  underMaintenance('Under Maintenance'),
  outOfService('Out of Service');

  final String displayName;
  const ResourceStatus(this.displayName);
}

enum ResourceCondition {
  good('Good'),
  fair('Fair'),
  needsRepair('Needs Repair');

  final String displayName;
  const ResourceCondition(this.displayName);
}

enum RequestPriority {
  normal('Normal'),
  urgent('Urgent'),
  emergency('Emergency');

  final String displayName;
  const RequestPriority(this.displayName);
}

enum RequestStatus {
  draft('Draft'),
  open('Open'),
  matching('Matching'),
  assigned('Assigned'),
  enRoute('En Route'),
  onSite('On Site'),
  inUse('In Use'),
  released('Released'),
  returned('Returned'),
  closed('Closed');

  final String displayName;
  const RequestStatus(this.displayName);
}

enum ResourceUserRole {
  fieldOfficer,
  commander;
}
