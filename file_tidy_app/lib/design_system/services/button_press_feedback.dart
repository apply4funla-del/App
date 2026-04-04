import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class ButtonPressFeedback {
  ButtonPressFeedback._();

  static final AudioPlayer _player = AudioPlayer();
  static bool _initialized = false;

  static Future<void> play() async {
    try {
      if (!_initialized) {
        await _player.setReleaseMode(ReleaseMode.stop);
        _initialized = true;
      }
      await _player.stop();
      await _player.play(AssetSource('audio/button_press.mp3'));
    } catch (_) {
      // Button feedback should never block normal app flow.
    }
  }

  static VoidCallback? wrap(VoidCallback? action) {
    if (action == null) {
      return null;
    }
    return () {
      play();
      action();
    };
  }
}
