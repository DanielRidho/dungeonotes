import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../widgets/app_dialog.dart';

class LocalImageStorage {
  const LocalImageStorage._();

  static final _picker = ImagePicker();

  static Future<String?> pickCropAndSave({
    required BuildContext context,
    required String filePrefix,
    required String folderName,
    required double aspectRatio,
    required String dialogTitle,
    required String instruction,
    required int outputWidth,
    int imageQuality = 90,
  }) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: imageQuality,
    );
    if (picked == null) {
      return null;
    }

    final bytes = await picked.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('This image format could not be read.');
    }
    if (!context.mounted) {
      return null;
    }

    var output = await showDialog<img.Image>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AspectCropDialog(
        bytes: bytes,
        image: decoded,
        aspectRatio: aspectRatio,
        title: dialogTitle,
        instruction: instruction,
      ),
    );
    if (output == null) {
      return null;
    }

    final outputHeight = math.max(1, (outputWidth / aspectRatio).round());
    output = img.copyResize(output, width: outputWidth, height: outputHeight);

    final encoded = img.encodeJpg(output, quality: 84);
    final directory = await getApplicationDocumentsDirectory();
    final folder = Directory(
      '${directory.path}${Platform.pathSeparator}$folderName',
    );
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final safePrefix = filePrefix.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File(
      '${folder.path}${Platform.pathSeparator}${safePrefix}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(encoded, flush: true);
    return file.path;
  }
}

class _AspectCropDialog extends StatefulWidget {
  const _AspectCropDialog({
    required this.bytes,
    required this.image,
    required this.aspectRatio,
    required this.title,
    required this.instruction,
  });

  final Uint8List bytes;
  final img.Image image;
  final double aspectRatio;
  final String title;
  final String instruction;

  @override
  State<_AspectCropDialog> createState() => _AspectCropDialogState();
}

class _AspectCropDialogState extends State<_AspectCropDialog> {
  static const _maxScale = 4.0;

  Size _frameSize = Size.zero;
  double _baseScale = 1;
  double _scale = 1;
  double _gestureStartScale = 1;
  Offset _offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final frameWidth = math.max(220.0, math.min(360.0, screenWidth - 64));
    final frameSize = Size(frameWidth, frameWidth / widget.aspectRatio);
    _ensureLayout(frameSize);

    return KeyboardSafeAlertDialog(
      title: Text(widget.title),
      maxContentHeight: 560,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_cropImage()),
          child: const Text('Save Image'),
        ),
      ],
      children: [
        Text(widget.instruction),
        const SizedBox(height: 12),
        GestureDetector(
          onScaleStart: (_) => _gestureStartScale = _scale,
          onScaleUpdate: _updateCrop,
          onDoubleTap: _resetCrop,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: frameSize.width,
              height: frameSize.height,
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      left: _offset.dx,
                      top: _offset.dy,
                      child: Image.memory(
                        widget.bytes,
                        width: widget.image.width * _baseScale * _scale,
                        height: widget.image.height * _baseScale * _scale,
                        fit: BoxFit.fill,
                      ),
                    ),
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Drag or pinch to frame the image. Double tap to reset.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _ensureLayout(Size frameSize) {
    if (_frameSize == frameSize) {
      return;
    }
    _frameSize = frameSize;
    _baseScale = math.max(
      frameSize.width / widget.image.width,
      frameSize.height / widget.image.height,
    );
    _scale = 1;
    _offset = _centerOffset(_scale);
  }

  void _updateCrop(ScaleUpdateDetails details) {
    setState(() {
      _scale =
          (_gestureStartScale * details.scale).clamp(1.0, _maxScale).toDouble();
      _offset = _clampOffset(_offset + details.focalPointDelta, _scale);
    });
  }

  void _resetCrop() {
    setState(() {
      _scale = 1;
      _offset = _centerOffset(_scale);
    });
  }

  Offset _centerOffset(double scale) {
    final width = widget.image.width * _baseScale * scale;
    final height = widget.image.height * _baseScale * scale;
    return _clampOffset(
      Offset((_frameSize.width - width) / 2, (_frameSize.height - height) / 2),
      scale,
    );
  }

  Offset _clampOffset(Offset offset, double scale) {
    final width = widget.image.width * _baseScale * scale;
    final height = widget.image.height * _baseScale * scale;
    return Offset(
      _clampAxis(offset.dx, width, _frameSize.width),
      _clampAxis(offset.dy, height, _frameSize.height),
    );
  }

  double _clampAxis(double value, double imageSize, double frameAxis) {
    if (imageSize <= frameAxis) {
      return (frameAxis - imageSize) / 2;
    }
    return value.clamp(frameAxis - imageSize, 0.0).toDouble();
  }

  img.Image _cropImage() {
    final totalScale = _baseScale * _scale;
    final cropWidth = math.max(1, (_frameSize.width / totalScale).round());
    final cropHeight = math.max(1, (_frameSize.height / totalScale).round());
    final x = _clampInt(
      (-_offset.dx / totalScale).round(),
      0,
      math.max(0, widget.image.width - cropWidth),
    );
    final y = _clampInt(
      (-_offset.dy / totalScale).round(),
      0,
      math.max(0, widget.image.height - cropHeight),
    );
    final safeWidth = math.min(cropWidth, widget.image.width - x);
    final safeHeight = math.min(cropHeight, widget.image.height - y);
    return img.copyCrop(
      widget.image,
      x: x,
      y: y,
      width: safeWidth,
      height: safeHeight,
    );
  }

  int _clampInt(int value, int min, int max) {
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }
}
