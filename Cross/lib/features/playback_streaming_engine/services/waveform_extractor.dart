import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class WaveformExtractor {
  static Future<List<double>> extractFromUrl(
    String audioUrl, {
    int samples = 180,
  }) async {
    if (samples <= 0) {
      throw ArgumentError('samples must be greater than 0');
    }

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uri = Uri.parse(audioUrl);

    String ext = p.extension(uri.path);
    if (ext.isEmpty) ext = '.audio';

    final inputFile = File(
      p.join(tempDir.path, 'waveform_input_$timestamp$ext'),
    );
    final pcmFile = File(p.join(tempDir.path, 'waveform_pcm_$timestamp.pcm'));

    await _downloadFile(audioUrl, inputFile);
    await _decodeToPcm16Mono16k(inputFile.path, pcmFile.path);

    final bytes = await pcmFile.readAsBytes();
    final peaks = _buildWaveformPeaksFromPcm16(bytes, samples: samples);

    await _safeDelete(inputFile);
    await _safeDelete(pcmFile);

    return peaks;
  }

  static Future<void> _downloadFile(String url, File outFile) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to download audio. Status code: ${response.statusCode}',
      );
    }

    await outFile.writeAsBytes(response.bodyBytes, flush: true);
  }

  static Future<void> _decodeToPcm16Mono16k(
    String inputPath,
    String outputPath,
  ) async {
    if (Platform.isAndroid) {
      final command =
          '-y -i "$inputPath" -vn -ac 1 -ar 16000 -f s16le "$outputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (returnCode == null || !returnCode.isValueSuccess()) {
        final logs = await session.getAllLogsAsString();
        throw Exception('FFmpeg failed on Android.\n$logs');
      }

      return;
    }

    if (Platform.isWindows) {
      final result = await Process.run('ffmpeg', [
        '-y',
        '-i',
        inputPath,
        '-vn',
        '-ac',
        '1',
        '-ar',
        '16000',
        '-f',
        's16le',
        outputPath,
      ]);

      if (result.exitCode != 0) {
        throw Exception(
          'FFmpeg failed on Windows.\n'
          'stdout: ${result.stdout}\n'
          'stderr: ${result.stderr}',
        );
      }

      return;
    }

    throw UnsupportedError('Only Android and Windows are supported.');
  }

  static List<double> _buildWaveformPeaksFromPcm16(
    Uint8List pcmBytes, {
    required int samples,
  }) {
    if (pcmBytes.isEmpty) {
      return List<double>.filled(samples, 0.0);
    }

    final byteData = ByteData.sublistView(pcmBytes);
    final totalSamples = pcmBytes.length ~/ 2;

    if (totalSamples == 0) {
      return List<double>.filled(samples, 0.0);
    }

    final windowSize = max(1, totalSamples ~/ samples);
    final peaks = <double>[];

    for (int i = 0; i < samples; i++) {
      final start = i * windowSize;
      final end = min(totalSamples, (i + 1) * windowSize);

      if (start >= end) {
        peaks.add(0.0);
        continue;
      }

      int maxAbs = 0;

      for (int s = start; s < end; s++) {
        final sample = byteData.getInt16(s * 2, Endian.little);
        final absValue = sample.abs();
        if (absValue > maxAbs) {
          maxAbs = absValue;
        }
      }

      peaks.add((maxAbs / 32767.0).clamp(0.0, 1.0));
    }

    return _smooth(peaks);
  }

  static List<double> _smooth(List<double> values) {
    if (values.length < 3) return values;

    final out = List<double>.from(values);

    for (int i = 1; i < values.length - 1; i++) {
      out[i] =
          ((values[i - 1] * 0.25) + (values[i] * 0.5) + (values[i + 1] * 0.25))
              .clamp(0.0, 1.0);
    }

    return out;
  }

  static Future<void> _safeDelete(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
