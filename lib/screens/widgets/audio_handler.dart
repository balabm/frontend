import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive_io.dart';

mixin AudioHandler<T extends StatefulWidget> on State<T> {
  FlutterSoundRecorder? audioRecorder;
  FlutterSoundPlayer? audioPlayer;
  bool isRecording = false;
  bool isPlaying = false;
  String? recordedFilePath;
  DateTime? recordingStartTime;
  Timer? recordingTimer;
  Duration recordingDuration = Duration.zero;

  Future<void> initializeAudio() async {
    audioRecorder = FlutterSoundRecorder();
    audioPlayer = FlutterSoundPlayer();
    await initializeRecorder();
    await initializePlayer();
  }

  Future<void> initializeRecorder() async {
    await audioRecorder!.openRecorder();
    await audioRecorder!.setSubscriptionDuration(const Duration(milliseconds: 10));
    print("Recorder initialized");
  }

  Future<void> initializePlayer() async {
    await audioPlayer!.openPlayer();
    print("Player initialized");
  }

  void disposeAudio() {
    recordingTimer?.cancel();
    audioRecorder?.closeRecorder();
    audioPlayer?.closePlayer();
    audioRecorder = null;
    audioPlayer = null;
  }

  Future<void> startRecording() async {
    try {
      Directory tempDir = await getTemporaryDirectory();
      recordedFilePath = path.join(tempDir.path, 'recorded_audio_${DateTime.now().millisecondsSinceEpoch}.wav');

      await audioRecorder!.startRecorder(
        toFile: recordedFilePath,
        codec: Codec.pcm16WAV,
      );

      setState(() {
        isRecording = true;
        recordingStartTime = DateTime.now();
        recordingDuration = Duration.zero;
      });

      recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (recordingStartTime != null && mounted) {
          setState(() {
            recordingDuration = DateTime.now().difference(recordingStartTime!);
          });
        }
      });

      print("Recording started");
    } catch (e) {
      print("Error starting recording: $e");
    }
  }

  Future<void> cancelRecording() async {
    try {
      recordingTimer?.cancel();
      await audioRecorder!.stopRecorder();
      if (recordedFilePath != null && File(recordedFilePath!).existsSync()) {
        await File(recordedFilePath!).delete();
      }
      if (mounted) {
        setState(() {
          isRecording = false;
          recordingStartTime = null;
          recordingDuration = Duration.zero;
        });
      }
      print("Recording cancelled");
    } catch (e) {
      print("Error cancelling recording: $e");
    }
  }

  Future<void> stopRecording() async {
    try {
      recordingTimer?.cancel();
      await audioRecorder!.stopRecorder();
      if (mounted) {
        setState(() {
          isRecording = false;
          recordingStartTime = null;
          recordingDuration = Duration.zero;
        });
      }
      print("Recording stopped");
    } catch (e) {
      print("Error stopping recording: $e");
    }
  }

  Future<void> playAudio(String audioPath) async {
    try {
      if (isPlaying) {
        await audioPlayer!.stopPlayer();
        setState(() {
          isPlaying = false;
        });
      } else {
        await audioPlayer!.startPlayer(
          fromURI: audioPath,
          whenFinished: () {
            setState(() {
              isPlaying = false;
            });
          },
        );
        setState(() {
          isPlaying = true;
        });
      }
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  Future<String> zipRecordedAudio() async {
    Directory tempDir = await getTemporaryDirectory();
    String zipFilePath = path.join(tempDir.path, 'audio_zip_${DateTime.now().millisecondsSinceEpoch}.zip');

    final zipEncoder = ZipFileEncoder();
    zipEncoder.create(zipFilePath);
    zipEncoder.addFile(File(recordedFilePath!));
    zipEncoder.close();

    return zipFilePath;
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes % 60);
    final seconds = twoDigits(duration.inSeconds % 60);
    return "${hours != '00' ? '$hours:' : ''}$minutes:$seconds";
  }
}
