import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import '../screens/camera_screen.dart';

class CameraService {
  static final CameraService instance = CameraService._init();
  CameraService._init();

  List<CameraDescription>? _cameras;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _cameras = await availableCameras();
      _initialized = true;
      print('CameraService: ${_cameras?.length ?? 0} camera(s) encontrada(s)');
    } catch (e) {
      print('Erro ao inicializar camera: $e');
      _cameras = [];
      _initialized = true;
    }
  }

  bool get hasCameras => _cameras != null && _cameras!.isNotEmpty;

  Future<String?> takePicture(BuildContext context) async {
    if (!hasCameras) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhuma camera disponivel neste dispositivo'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return null;
    }

    final permissionStatus = await Permission.camera.request();
    if (!permissionStatus.isGranted) {
      if (context.mounted) {
        final shouldOpenSettings = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permissao necessaria'),
            content: const Text(
              'Precisamos da permissao da camera para anexar fotos as tarefas.\n\n'
              'Deseja abrir as configuracoes?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Configuracoes'),
              ),
            ],
          ),
        );

        if (shouldOpenSettings == true) {
          await openAppSettings();
        }
      }
      return null;
    }

    final camera = _cameras!.first;
    CameraController? controller;

    try {
      controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      if (!context.mounted) return null;

      final imagePath = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(controller: controller!),
          fullscreenDialog: true,
        ),
      );

      return imagePath;
    } catch (e) {
      print('Erro ao abrir camera: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir camera: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }

      return null;
    } finally {
      await controller?.dispose();
    }
  }

  Future<String> savePicture(XFile image) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'task_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savePath = path.join(appDir.path, 'images', fileName);

      final imageDir = Directory(path.join(appDir.path, 'images'));
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }

      final savedImage = await File(image.path).copy(savePath);
      print('Foto salva: ${savedImage.path}');
      return savedImage.path;
    } catch (e) {
      print('Erro ao salvar foto: $e');
      rethrow;
    }
  }

  Future<bool> deletePhoto(String photoPath) async {
    try {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Erro ao deletar foto: $e');
      return false;
    }
  }
}

