enum RelayAction { drop, consumeOnly, consumeAndRelay }

class RelayDecision {
  const RelayDecision({required this.action, required this.reason});

  final RelayAction action;
  final String reason;
}
