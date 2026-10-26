import 'package:audio_session/audio_session.dart';

// Configures the OS audio session once at startup (PRD S06). just_audio uses
// the active session automatically, so this is what makes playback take audio
// focus, duck/pause for interruptions (calls) and stop on becoming-noisy
// (headphones unplugged).

/// Wraps [AudioSession] configuration behind a tiny, injectable seam.
final class AudioSessionService {
  /// Creates the service.
  const AudioSessionService();

  /// Applies the music session configuration. Safe to call once at startup.
  Future<void> configure() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }
}
