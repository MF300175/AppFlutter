import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';

class SensorService {
  static final SensorService instance = SensorService._init();
  SensorService._init();

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  Function()? _onShake;
  bool _isActive = false;

  static const double _shakeThreshold = 15.0;
  static const Duration _shakeCooldown = Duration(milliseconds: 500);
  DateTime? _lastShakeTime;

  bool get isActive => _isActive;

  void startShakeDetection(Function() onShake) {
    if (_isActive) {
      print('Detecao ja ativa');
      return;
    }

    _onShake = onShake;
    _isActive = true;

    try {
      _accelerometerSubscription = accelerometerEventStream().listen(
        (AccelerometerEvent event) {
          _detectShake(event);
        },
        onError: (error) {
          print('Erro no acelerometro: $error');
          stopShakeDetection();
        },
      );

      print('Detecao de shake iniciada');
    } catch (e) {
      print('Sensores nao disponiveis: $e');
      _isActive = false;
    }
  }

  void _detectShake(AccelerometerEvent event) {
    final now = DateTime.now();

    if (_lastShakeTime != null &&
        now.difference(_lastShakeTime!) < _shakeCooldown) {
      return;
    }

    final magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    if (magnitude > _shakeThreshold) {
      _lastShakeTime = now;
      _triggerShake();
    }
  }

  Future<void> _triggerShake() async {
    if (_onShake == null) return;

    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: 100);
      }
    } catch (e) {
      print('Vibracao nao disponivel: $e');
    }

    _onShake!();
  }

  void stopShakeDetection() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _onShake = null;
    _isActive = false;
    print('Detecao de shake parada');
  }

  void dispose() {
    stopShakeDetection();
  }
}

