using sparebridge as db from '../db/schema';

service SpareBridgeService {
  entity Plants as projection on db.Plants;
  entity Inventory as projection on db.Inventory;
  entity BreakdownRequests as projection on db.BreakdownRequest
    actions {
      action findMatches() returns array of MatchResults;
    };
  entity MatchResults as projection on db.MatchResult
    actions {
      action approveMatch() returns TransferOrders;
    };
  entity TransferOrders as projection on db.TransferOrder;
}
