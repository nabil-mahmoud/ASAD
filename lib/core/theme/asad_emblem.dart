import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// The Official ASAD Emblem (الشعار الرسمي المعتمد لمنظومة ASAD)
/// Combines the protective academic shield, faceted polygon lion head,
/// and emerald green QR scanner corner marks.
class AsadEmblem extends StatelessWidget {
  final double size;
  final bool showLabel;
  final bool compact;

  const AsadEmblem({
    super.key,
    this.size = 120,
    this.showLabel = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _AsadEmblemPainter(),
          ),
        ),
        if (showLabel) ...[
          SizedBox(height: compact ? 6 : 12),
          Text(
            'ASAD',
            style: TextStyle(
              fontSize: compact ? 18 : 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: AppColors.textLight,
              fontFamily: 'Roboto',
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.royalDark.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.emerald.withOpacity(0.4)),
            ),
            child: Text(
              'منظومة الحضور الأكاديمي الذكي',
              style: TextStyle(
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w600,
                color: AppColors.mintAccent,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AsadEmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // 1. Draw Outer Shield Path
    final shieldPath = Path();
    shieldPath.moveTo(w * 0.15, h * 0.12);
    shieldPath.lineTo(w * 0.85, h * 0.12);
    shieldPath.quadraticBezierTo(w * 0.90, h * 0.55, center.dx, h * 0.92);
    shieldPath.quadraticBezierTo(w * 0.10, h * 0.55, w * 0.15, h * 0.12);
    shieldPath.close();

    // Shield Background Fill (Deep Royal Green Gradient)
    final shieldPaint = Paint()
      ..shader = AppColors.shieldGradient.createShader(
        Rect.fromLTWH(0, 0, w, h),
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(shieldPath, shieldPaint);

    // Shield Inner Border
    final innerBorderPaint = Paint()
      ..color = AppColors.emerald.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, w * 0.022);
    canvas.drawPath(shieldPath, innerBorderPaint);

    // Subtle Outer Glow
    final glowPaint = Paint()
      ..color = AppColors.emerald.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(3.5, w * 0.035)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6);
    canvas.drawPath(shieldPath, glowPaint);

    // 2. Draw 4 Green QR Finder Corners (أركان الـ QR الخضراء)
    _drawQrCorners(canvas, size);

    // 3. Draw Faceted Lion Head (رأس الأسد المضلع)
    _drawFacetedLion(canvas, size, center);
  }

  void _drawQrCorners(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cornerSize = w * 0.14;
    final lineW = math.max(2.0, w * 0.024);

    final cornerPaint = Paint()
      ..color = AppColors.mintAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineW
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = AppColors.mintAccent
      ..style = PaintingStyle.fill;

    // Helper for L-shaped corner bracket
    void drawBracket(double x, double y, bool left, bool top) {
      final path = Path();
      if (left && top) {
        path.moveTo(x + cornerSize, y);
        path.lineTo(x, y);
        path.lineTo(x, y + cornerSize);
        canvas.drawCircle(Offset(x + cornerSize * 0.45, y + cornerSize * 0.45), lineW * 0.9, dotPaint);
      } else if (!left && top) {
        path.moveTo(x - cornerSize, y);
        path.lineTo(x, y);
        path.lineTo(x, y + cornerSize);
        canvas.drawCircle(Offset(x - cornerSize * 0.45, y + cornerSize * 0.45), lineW * 0.9, dotPaint);
      } else if (left && !top) {
        path.moveTo(x, y - cornerSize);
        path.lineTo(x, y);
        path.lineTo(x + cornerSize, y);
        canvas.drawCircle(Offset(x + cornerSize * 0.45, y - cornerSize * 0.45), lineW * 0.9, dotPaint);
      } else {
        path.moveTo(x, y - cornerSize);
        path.lineTo(x, y);
        path.lineTo(x - cornerSize, y);
        canvas.drawCircle(Offset(x - cornerSize * 0.45, y - cornerSize * 0.45), lineW * 0.9, dotPaint);
      }
      canvas.drawPath(path, cornerPaint);
    }

    drawBracket(w * 0.06, h * 0.06, true, true);
    drawBracket(w * 0.94, h * 0.06, false, true);
    drawBracket(w * 0.12, h * 0.82, true, false);
    drawBracket(w * 0.88, h * 0.82, false, false);
  }

  void _drawFacetedLion(Canvas canvas, Size size, Offset center) {
    final w = size.width;
    final h = size.height;

    final maneFacetPaint1 = Paint()
      ..color = AppColors.emerald.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    final maneFacetPaint2 = Paint()
      ..color = AppColors.emerald.withOpacity(0.20)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = AppColors.textLight.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, w * 0.016)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final goldLinePaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, w * 0.016)
      ..strokeCap = StrokeCap.round;

    // Facet Coordinates for Geometric Polygonal Lion Head
    // Crown / Top Mane
    final topP = Offset(center.dx, h * 0.22);
    final topL = Offset(w * 0.38, h * 0.26);
    final topR = Offset(w * 0.62, h * 0.26);
    final outerTopL = Offset(w * 0.27, h * 0.32);
    final outerTopR = Offset(w * 0.73, h * 0.32);

    // Cheek / Mid Mane
    final midL = Offset(w * 0.24, h * 0.48);
    final midR = Offset(w * 0.76, h * 0.48);
    final innerMidL = Offset(w * 0.36, h * 0.45);
    final innerMidR = Offset(w * 0.64, h * 0.45);

    // Eyes / Brow
    final browMid = Offset(center.dx, h * 0.38);
    final eyeL = Offset(w * 0.42, h * 0.44);
    final eyeR = Offset(w * 0.58, h * 0.44);

    // Muzzle / Nose
    final noseTop = Offset(center.dx, h * 0.52);
    final noseTip = Offset(center.dx, h * 0.60);
    final noseL = Offset(w * 0.44, h * 0.58);
    final noseR = Offset(w * 0.56, h * 0.58);

    // Chin / Jaw
    final jawL = Offset(w * 0.35, h * 0.68);
    final jawR = Offset(w * 0.65, h * 0.68);
    final chin = Offset(center.dx, h * 0.76);

    // Draw Shaded Facets (Polygons)
    void drawTriangle(Offset p1, Offset p2, Offset p3, Paint p) {
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..close();
      canvas.drawPath(path, p);
    }

    // Mane facets
    drawTriangle(topP, topL, browMid, maneFacetPaint1);
    drawTriangle(topP, topR, browMid, maneFacetPaint2);
    drawTriangle(topL, outerTopL, innerMidL, maneFacetPaint2);
    drawTriangle(topR, outerTopR, innerMidR, maneFacetPaint1);
    drawTriangle(outerTopL, midL, innerMidL, maneFacetPaint1);
    drawTriangle(outerTopR, midR, innerMidR, maneFacetPaint2);
    drawTriangle(innerMidL, jawL, chin, maneFacetPaint1);
    drawTriangle(innerMidR, jawR, chin, maneFacetPaint2);

    // Draw Geometric Lines
    final lionOutline = Path()
      // Outer mane perimeter
      ..moveTo(topP.dx, topP.dy)
      ..lineTo(topL.dx, topL.dy)
      ..lineTo(outerTopL.dx, outerTopL.dy)
      ..lineTo(midL.dx, midL.dy)
      ..lineTo(jawL.dx, jawL.dy)
      ..lineTo(chin.dx, chin.dy)
      ..lineTo(jawR.dx, jawR.dy)
      ..lineTo(midR.dx, midR.dy)
      ..lineTo(outerTopR.dx, outerTopR.dy)
      ..lineTo(topR.dx, topR.dy)
      ..close();
    canvas.drawPath(lionOutline, linePaint);

    // Inner facial geometry
    final innerFace = Path()
      ..moveTo(topL.dx, topL.dy)
      ..lineTo(browMid.dx, browMid.dy)
      ..lineTo(topR.dx, topR.dy)
      ..moveTo(browMid.dx, browMid.dy)
      ..lineTo(noseTop.dx, noseTop.dy)
      ..moveTo(topL.dx, topL.dy)
      ..lineTo(innerMidL.dx, innerMidL.dy)
      ..lineTo(noseTop.dx, noseTop.dy)
      ..lineTo(innerMidR.dx, innerMidR.dy)
      ..lineTo(topR.dx, topR.dy)
      // Muzzle to chin
      ..moveTo(noseTop.dx, noseTop.dy)
      ..lineTo(noseL.dx, noseL.dy)
      ..lineTo(noseTip.dx, noseTip.dy)
      ..lineTo(noseR.dx, noseR.dy)
      ..lineTo(noseTop.dx, noseTop.dy)
      ..moveTo(noseTip.dx, noseTip.dy)
      ..lineTo(chin.dx, chin.dy)
      ..moveTo(innerMidL.dx, innerMidL.dy)
      ..lineTo(jawL.dx, jawL.dy)
      ..moveTo(innerMidR.dx, innerMidR.dy)
      ..lineTo(jawR.dx, jawR.dy);
    canvas.drawPath(innerFace, linePaint);

    // Distinctive glowing geometric eyes
    final eyePath = Path()
      ..moveTo(eyeL.dx - w * 0.04, eyeL.dy)
      ..lineTo(eyeL.dx, eyeL.dy - h * 0.02)
      ..lineTo(eyeL.dx + w * 0.03, eyeL.dy)
      ..moveTo(eyeR.dx + w * 0.04, eyeR.dy)
      ..lineTo(eyeR.dx, eyeR.dy - h * 0.02)
      ..lineTo(eyeR.dx - w * 0.03, eyeR.dy);
    canvas.drawPath(eyePath, goldLinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
