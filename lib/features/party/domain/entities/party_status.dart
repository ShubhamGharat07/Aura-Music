// Listen together (PRD S06) lifecycle. The UI renders one block per value.

/// State of the local party session.
enum PartyStatus {
  /// Nothing is running: no advertisement, no scan, no link.
  idle,

  /// Hosting: advertising and waiting for guests.
  hosting,

  /// Looking for nearby sessions to join.
  scanning,

  /// Linking to the selected session.
  connecting,

  /// Linked: this guest follows the host's playback.
  connected,

  /// Bluetooth permission was refused.
  denied,

  /// This device cannot advertise or scan over BLE.
  unsupported,

  /// Bluetooth is off, or the radio/link failed.
  failed,
}
