using sparebridge as db from '../db/schema';

service SpareBridgeService {
  entity Materials as projection on db.Material;
  entity Plants as projection on db.Plants;
  entity Inventory as projection on db.Inventory;
  @odata.draft.enabled
  entity BreakdownRequests as projection on db.BreakdownRequest
    actions {
      action findMatches() returns BreakdownRequests;
    };
  entity MatchResults as projection on db.MatchResult
    actions {
      action approveMatch() returns BreakdownRequests;
    };
  entity TransferOrders as projection on db.TransferOrder
    actions {
      action markInTransit() returns TransferOrders;
      action markDelivered() returns TransferOrders;
    };
}
