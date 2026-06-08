namespace sparebridge;

using { managed } from '@sap/cds/common';

type RequestStatus : String(20) enum {
  NEW      = 'NEW';
  PARTIAL  = 'PARTIAL';
  APPROVED = 'APPROVED';
}

entity RequestStatusCode {
  key code        : RequestStatus;
      description : String(50);
}

entity Material {
  key code        : String(20);
      description : String(100);
}

entity Plants {
  key ID        : String(6);
      name      : String(100);
      city      : String(100);
      latitude  : Decimal(9,6);
      longitude : Decimal(9,6);
}
entity Inventory {
  key plant : Association to Plants;
  key material : String(20);
  stock : Integer;
  safetyStock : Integer;
}

entity BreakdownRequest : managed {
  key ID : UUID;
  plant : Association to Plants;
  material : String(20);
  quantity : Integer;
  urgency : Integer; // 1=low, 5=high
  status            : RequestStatus default 'NEW';
  fulfilledQty      : Integer default 0;
  matchedAt         : Timestamp;
  statusCriticality : Integer default 2;
  matchResults   : Association to many MatchResult on matchResults.request = $self;
  transferOrders : Association to many TransferOrder on transferOrders.request_ID = ID;
}

entity MatchResult {
  key ID : UUID;
  request : Association to BreakdownRequest;
  sourcePlant : Association to Plants;
  transferableQty : Integer;
  distanceKm : Decimal(9,3);
  estimatedCost : Decimal(12,2);
  canFullyFulfil : Boolean;
  rank              : Integer;
  status            : String(20) default 'PENDING';
  canApprove        : Boolean default true;
  statusCriticality : Integer default 2;
}

entity TransferOrder {
  key ID            : UUID;
  match             : Association to MatchResult;
  request_ID        : UUID;
  toPlant           : Association to Plants;
  quantity          : Integer;
  createdAt         : Timestamp;
  status            : String(20) default 'PENDING';
  statusCriticality : Integer default 2;
  canMarkShipped    : Boolean default true;
  canMarkDelivered  : Boolean default false;
}
