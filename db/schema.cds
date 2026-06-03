namespace sparebridge;

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

entity BreakdownRequest {
  key ID : UUID;
  plant : Association to Plants;
  material : String(20);
  quantity : Integer;
  urgency : Integer; // 1=low, 5=high
  status : String(20);
  fulfilledQty : Integer default 0;
}

entity MatchResult {
  key ID : UUID;
  request : Association to BreakdownRequest;
  sourcePlant : Association to Plants;
  transferableQty : Integer;
  distanceKm : Decimal(9,3);
  estimatedCost : Decimal(12,2);
  canFullyFulfil : Boolean;
  rank : Integer;
}

entity TransferOrder {
  key ID : UUID;
  match : Association to MatchResult;
  createdAt : Timestamp;
  status : String(20);
}
