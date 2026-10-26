// Listen together (PRD S06): a party session is hosted by one device and
// followed by the others.

/// Which side of a party session this device is on.
enum PartyRole {
  /// This device advertises the session and is the single source of truth for
  /// what plays.
  host,

  /// This device discovered a session and follows its host.
  guest,
}
