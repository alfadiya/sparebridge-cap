using sparebridge as db from '../db/schema';

service SpareBridgeService {
  entity Plants as projection on db.Plants;
  entity Inventory as projection on db.Inventory;
  entity BreakdownRequests as projection on db.BreakdownRequest;
  entity MatchResults as projection on db.MatchResult;
  entity TransferOrders as projection on db.TransferOrder;

  action findMatches(requestID: UUID) returns array of MatchResults;
  action approveMatch(matchID: UUID) returns TransferOrders;
}
