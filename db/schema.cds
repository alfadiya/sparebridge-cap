namespace sparebridge;

entity Plants {
  key ID        : String(6);
      name      : String(100);
      city      : String(100);
      latitude  : Decimal(9,6);
      longitude : Decimal(9,6);
}
