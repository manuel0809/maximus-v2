import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SignaturePad extends StatefulWidget {
  const SignaturePad({super.key});

  @override
  State<SignaturePad> createState() => SignaturePadState();
}

class SignaturePadState extends State<SignaturePad> {
  final List<Offset?> _points = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 20.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                RenderBox renderBox = context.findRenderObject() as RenderBox;
                _points.add(renderBox.globalToLocal(details.globalPosition));
              });
            },
            onPanEnd: (details) => _points.add(null),
            child: CustomPaint(
              painter: _SignaturePainter(_points),
              size: Size.infinite,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => setState(() => _points.clear()),
              child: const Text('Limpiar', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ],
    );
  }

  Future<ui.Image?> getSignatureImage() async {
    if (_points.isEmpty) return null;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromPoints(const Offset(0, 0), Offset(100.w, 20.h)));
    final painter = _SignaturePainter(_points);
    painter.paint(canvas, Size(100.w, 20.h));
    final picture = recorder.endRecording();
    return await picture.toImage((100.w).toInt(), (20.h).toInt());
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) => oldDelegate.points != points;
}
