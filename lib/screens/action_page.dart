import 'dart:io' show File;

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ActionButtons extends StatefulWidget {
  const ActionButtons({super.key});

  @override
  State<ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<ActionButtons> {
  Uint8List? _imageBytes;
  Uint8List? _audioBytes;
  Uint8List? _encryptedData;

  final picker = ImagePicker();
  final recorder = FlutterSoundRecorder();
  final player = FlutterSoundPlayer();
  final key = encrypt.Key.fromSecureRandom(32);
  late final encrypt.Encrypter encrypter;
  late final encrypt.IV iv;

  String? _audioPath;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    encrypter = encrypt.Encrypter(encrypt.AES(key));
    iv = encrypt.IV.fromLength(16);
    if (!kIsWeb) {
      recorder.openRecorder();
      player.openPlayer();
      Permission.microphone.request();
      Permission.storage.request();
    }
  }

  Future<void> pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Galerie'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
    );

    if (source != null) {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _audioBytes = null;
        });
      }
    }
  }

  Future<void> recordAudio() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Înregistrarea audio nu e suportată pe web"),
        ),
      );
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/audio.aac';
    await recorder.startRecorder(toFile: path);
    setState(() => _audioPath = path);
  }

  Future<void> stopRecording() async {
    if (kIsWeb) return;
    await recorder.stopRecorder();

    if (_audioPath != null) {
      final file = File(_audioPath!);
      final bytes = await file.readAsBytes();
      setState(() {
        _audioBytes = bytes;
        _imageBytes = null;
      });
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Înregistrare oprită")));
  }

  Future<void> playAudio() async {
    if (_audioPath == null || isPlaying) return;

    setState(() => isPlaying = true);

    await player.startPlayer(
      fromURI: _audioPath,
      codec: Codec.aacADTS,
      whenFinished: () => setState(() => isPlaying = false),
    );
  }

  void encryptSelected() {
    Uint8List? dataToEncrypt = _imageBytes ?? _audioBytes;
    if (dataToEncrypt != null) {
      final encrypted = encrypter.encryptBytes(dataToEncrypt, iv: iv);
      setState(() => _encryptedData = encrypted.bytes);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fișier criptat")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Incarcă un fișier înainte")),
      );
    }
  }

  Future<void> saveEncryptedFile() async {
    if (_encryptedData == null) return;

    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Salvarea locală nu e suportată pe web")),
      );
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/encrypted_file.dat');
    await file.writeAsBytes(_encryptedData!);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Fișier salvat la: ${file.path}")));
  }

  Future<void> decryptFile() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Decriptarea locală nu e suportată pe web"),
        ),
      );
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/encrypted_file.dat');
    if (!file.existsSync()) return;

    final encryptedBytes = await file.readAsBytes();
    final decrypted = encrypter.decryptBytes(
      encrypt.Encrypted(encryptedBytes),
      iv: iv,
    );

    final outputPath = '${dir.path}/decrypted_output';
    final outFile = File(outputPath);
    await outFile.writeAsBytes(decrypted);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Fișier decriptat la: $outputPath")));
  }

  String get encryptedDisplayText {
    if (_encryptedData == null) return '';
    return _encryptedData!
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('L4 - achiziții multimedia și criptarea datelor'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child:
                          _imageBytes != null
                              ? Image.memory(_imageBytes!)
                              : _audioBytes != null
                              ? const Icon(Icons.audiotrack, size: 100)
                              : const Text('Niciun fișier selectat'),
                    ),
                  ),
                  if (_encryptedData != null) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Date Criptate:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: SelectableText(
                          encryptedDisplayText,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: kIsWeb ? 3 : 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 5,
                children: [
                  ElevatedButton.icon(
                    onPressed: pickImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Imagine'),
                  ),
                  ElevatedButton.icon(
                    onPressed: recordAudio,
                    icon: const Icon(Icons.mic),
                    label: const Text('Înregistrează'),
                  ),
                  ElevatedButton.icon(
                    onPressed: stopRecording,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  ),
                  if (_audioBytes != null)
                    ElevatedButton.icon(
                      onPressed: playAudio,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Redă audio'),
                    ),
                  if (_imageBytes != null || _audioBytes != null) ...[
                    ElevatedButton.icon(
                      onPressed: encryptSelected,
                      icon: const Icon(Icons.lock),
                      label: const Text('Criptează'),
                    ),
                    ElevatedButton.icon(
                      onPressed: saveEncryptedFile,
                      icon: const Icon(Icons.save),
                      label: const Text('Salvează'),
                    ),
                    ElevatedButton.icon(
                      onPressed: decryptFile,
                      icon: const Icon(Icons.lock_open),
                      label: const Text('Decriptează'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
