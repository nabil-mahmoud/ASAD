import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Pure Offline Audio Feedback Synthesizer for ASAD System
/// Synthesizes exact frequencies (880Hz, 550Hz, 220Hz) in-memory without any internet or external mp3 files.
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();

  Uint8List? _beep880HzBytes;
  Uint8List? _doubleTone550HzBytes;
  Uint8List? _errorBuzz220HzBytes;
  Uint8List? _softClickBytes;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      // Pre-synthesize and cache tone bytes for instantaneous (<10ms) zero-latency playback
      _beep880HzBytes = _synthesizeTone(
        frequency: 880.0,
        durationSeconds: 0.14,
        volume: 0.7,
      );

      _doubleTone550HzBytes = _synthesizeBurstTone(
        frequency: 550.0,
        burstDuration: 0.08,
        silenceDuration: 0.05,
        burstCount: 2,
        volume: 0.75,
      );

      _errorBuzz220HzBytes = _synthesizeTone(
        frequency: 220.0,
        durationSeconds: 0.28,
        volume: 0.85,
        waveType: _WaveType.sawtooth,
      );

      _softClickBytes = _synthesizeTone(
        frequency: 1100.0,
        durationSeconds: 0.06,
        volume: 0.5,
      );

      _initialized = true;
    } catch (e) {
      debugPrint('SoundService init error: $e');
    }
  }

  /// 1. مسح ناجح ومقيد: نغمة قصيرة مريحة (Beep 880Hz)
  Future<void> playSuccessBeep() async {
    await _playBytes(_beep880HzBytes);
  }

  /// 2. تكرار المسح: نغمة تنبيه مزدوجة (550Hz)
  Future<void> playDuplicateAlert() async {
    await _playBytes(_doubleTone550HzBytes);
  }

  /// 3. طالب غير مسجل بالمكان: طنين خطأ منخفض (220Hz)
  Future<void> playWrongLocationBuzz() async {
    await _playBytes(_errorBuzz220HzBytes);
  }

  /// 4. تحضير يدوي / عذر: نقرة تأكيد ناعمة
  Future<void> playManualConfirmClick() async {
    await _playBytes(_softClickBytes);
  }

  Future<void> _playBytes(Uint8List? bytes) async {
    if (bytes == null) {
      SystemSound.play(SystemSoundType.click);
      return;
    }
    try {
      await _player.stop();
      await _player.play(BytesSource(bytes));
    } catch (e) {
      // Fallback to system click if sound hardware is busy
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Generates a standard uncompressed PCM 16-bit mono 44.1 kHz WAV file
  static Uint8List _synthesizeTone({
    required double frequency,
    required double durationSeconds,
    required double volume,
    _WaveType waveType = _WaveType.sine,
  }) {
    const int sampleRate = 44100;
    final int numSamples = (sampleRate * durationSeconds).round();
    final int dataBytes = numSamples * 2; // 16-bit = 2 bytes per sample
    final int totalFileSize = 44 + dataBytes;

    final ByteData byteData = ByteData(totalFileSize);

    // RIFF Header
    _writeString(byteData, 0, 'RIFF');
    byteData.setUint32(4, totalFileSize - 8, Endian.little);
    _writeString(byteData, 8, 'WAVE');

    // fmt Subchunk
    _writeString(byteData, 12, 'fmt ');
    byteData.setUint32(16, 16, Endian.little); // Subchunk1Size for PCM
    byteData.setUint16(20, 1, Endian.little);  // AudioFormat 1 = PCM
    byteData.setUint16(22, 1, Endian.little);  // NumChannels 1 = Mono
    byteData.setUint32(24, sampleRate, Endian.little); // SampleRate
    byteData.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
    byteData.setUint16(32, 2, Endian.little);  // BlockAlign
    byteData.setUint16(34, 16, Endian.little); // BitsPerSample

    // data Subchunk
    _writeString(byteData, 36, 'data');
    byteData.setUint32(40, dataBytes, Endian.little);

    // Generate Audio Waveform with smooth envelope
    int offset = 44;
    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;

      // Envelope to eliminate audio clicks (5ms ramp up, 10ms ramp down)
      double envelope = 1.0;
      final double rampUpSamples = 0.005 * sampleRate;
      final double rampDownSamples = 0.015 * sampleRate;
      if (i < rampUpSamples) {
        envelope = i / rampUpSamples;
      } else if (i > numSamples - rampDownSamples) {
        envelope = (numSamples - i) / rampDownSamples;
      }

      double wave;
      switch (waveType) {
        case _WaveType.sine:
          wave = math.sin(2 * math.pi * frequency * t);
          break;
        case _WaveType.sawtooth:
          // Low buzzing sawtooth
          wave = 2.0 * ((frequency * t) - ((frequency * t).floor() + 0.5));
          break;
      }

      final int sampleValue = (wave * volume * envelope * 32767).round().clamp(-32768, 32767);
      byteData.setInt16(offset, sampleValue, Endian.little);
      offset += 2;
    }

    return byteData.buffer.asUint8List();
  }

  /// Synthesizes dual or multi-burst tones (e.g. 550Hz double-beep)
  static Uint8List _synthesizeBurstTone({
    required double frequency,
    required double burstDuration,
    required double silenceDuration,
    required int burstCount,
    required double volume,
  }) {
    const int sampleRate = 44100;
    final int burstSamples = (sampleRate * burstDuration).round();
    final int silenceSamples = (sampleRate * silenceDuration).round();
    final int totalSamples = (burstSamples * burstCount) + (silenceSamples * (burstCount - 1));
    final int dataBytes = totalSamples * 2;
    final int totalFileSize = 44 + dataBytes;

    final ByteData byteData = ByteData(totalFileSize);

    // RIFF Header
    _writeString(byteData, 0, 'RIFF');
    byteData.setUint32(4, totalFileSize - 8, Endian.little);
    _writeString(byteData, 8, 'WAVE');

    // fmt
    _writeString(byteData, 12, 'fmt ');
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little);
    byteData.setUint16(22, 1, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little);
    byteData.setUint16(32, 2, Endian.little);
    byteData.setUint16(34, 16, Endian.little);

    // data
    _writeString(byteData, 36, 'data');
    byteData.setUint32(40, dataBytes, Endian.little);

    int offset = 44;
    for (int b = 0; b < burstCount; b++) {
      // Burst
      for (int i = 0; i < burstSamples; i++) {
        final double t = i / sampleRate;
        double envelope = 1.0;
        final double ramp = 0.005 * sampleRate;
        if (i < ramp) envelope = i / ramp;
        if (i > burstSamples - ramp) envelope = (burstSamples - i) / ramp;

        final double wave = math.sin(2 * math.pi * frequency * t);
        final int sampleValue = (wave * volume * envelope * 32767).round().clamp(-32768, 32767);
        byteData.setInt16(offset, sampleValue, Endian.little);
        offset += 2;
      }
      // Silence between bursts
      if (b < burstCount - 1) {
        for (int i = 0; i < silenceSamples; i++) {
          byteData.setInt16(offset, 0, Endian.little);
          offset += 2;
        }
      }
    }

    return byteData.buffer.asUint8List();
  }

  static void _writeString(ByteData data, int offset, String string) {
    for (int i = 0; i < string.length; i++) {
      data.setUint8(offset + i, string.codeUnitAt(i));
    }
  }

  void dispose() {
    _player.dispose();
  }
}

enum _WaveType {
  sine,
  sawtooth,
}
