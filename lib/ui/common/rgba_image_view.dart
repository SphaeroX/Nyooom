import 'dart:async';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../../core/inspection/heatmap.dart';

/// Converts an [RgbaImage] into a `dart:ui` image.
Future<ui.Image> toUiImage(RgbaImage image) {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    image.rgba,
    image.width,
    image.height,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  return completer.future;
}

/// Shows an [RgbaImage] stretched to the available size, with an optional
/// [overlay] painter (e.g. a model curve) on top.
class RgbaImageView extends StatefulWidget {
  const RgbaImageView({
    super.key,
    required this.image,
    this.height = 180,
    this.overlay,
  });

  final RgbaImage image;
  final double height;
  final CustomPainter? overlay;

  @override
  State<RgbaImageView> createState() => _RgbaImageViewState();
}

class _RgbaImageViewState extends State<RgbaImageView> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _convert();
  }

  @override
  void didUpdateWidget(RgbaImageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.image, widget.image)) _convert();
  }

  Future<void> _convert() async {
    final image = await toUiImage(widget.image);
    if (!mounted) {
      image.dispose();
      return;
    }
    setState(() {
      _image?.dispose();
      _image = image;
    });
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: image == null
          ? const Center(child: CircularProgressIndicator())
          : CustomPaint(
              foregroundPainter: widget.overlay,
              child: RawImage(
                image: image,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
    );
  }
}
