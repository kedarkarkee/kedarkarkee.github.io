import 'dart:math' as math;

import 'three.dart';

/// A simple bicycle built from primitives. It lies along the z axis and
/// rolls towards +z, so it shares the stickman's heading convention.
///
/// The coordinates the rider's pose depends on are exposed as constants so
/// the stickman can place his feet on the pedals and hands on the handlebar.
class Bicycle {
  Bicycle() {
    _build();
  }

  static const wheelRadius = 0.8;
  static const crankY = 0.8;
  static const crankLength = 0.35;
  static const seatY = 1.8, seatZ = -0.4;
  static const handleY = 2.3, handleZ = 0.95;

  final root = Object3D.group();

  /// Crank angle in radians; the stickman's feet follow this.
  double crank = 0;

  final _crank = Object3D.group();
  final _wheelF = Object3D.group();
  final _wheelR = Object3D.group();

  static const _frame = 0xd32f2f;
  static const _ink = 0x222222;

  T _at<T extends Object3D>(T o, Object3D parent, double y, double z, [double x = 0]) {
    o.position.set(x, y, z);
    parent.add(o);
    return o;
  }

  /// A tube between two points in the bike's (y, z) plane.
  void _bar(double y0, double z0, double y1, double z1, {double r = 0.055, int color = _frame}) {
    final dy = y1 - y0, dz = z1 - z0;
    final bar = _at(mesh('Cylinder', [r, r, math.sqrt(dy * dy + dz * dz), 8], color), root, (y0 + y1) / 2, (z0 + z1) / 2);
    bar.rotation.x = math.atan2(dz, dy);
  }

  void _wheel(Object3D wheel, double z) {
    _at(wheel, root, wheelRadius, z);
    final tyre = mesh('Torus', [wheelRadius - 0.06, 0.07, 8, 28], _ink);
    tyre.rotation.y = math.pi / 2;
    wheel.add(tyre);
    // Spokes turn with the wheel so rolling is visible.
    for (final a in [0.0, math.pi / 3, 2 * math.pi / 3]) {
      final spoke = mesh('Cylinder', [0.015, 0.015, (wheelRadius - 0.06) * 2, 4], 0xbbbbbb);
      spoke.rotation.x = a;
      wheel.add(spoke);
    }
    wheel.add(mesh('Sphere', [0.08, 8, 6], 0xbbbbbb));
  }

  void _build() {
    _wheel(_wheelR, -1.2);
    _wheel(_wheelF, 1.25);

    _bar(crankY, 0, 1.75, seatZ + 0.05); // seat tube
    _bar(crankY, 0, 1.75, handleZ); // down tube
    _bar(1.7, seatZ + 0.05, 1.8, handleZ); // top tube
    _bar(crankY, 0, crankY, -1.2); // chain stay
    _bar(1.7, seatZ + 0.05, crankY, -1.2); // seat stay
    _bar(1.8, handleZ, crankY, 1.25); // fork
    _bar(1.8, handleZ, handleY, handleZ); // stem

    final bars = _at(mesh('Cylinder', [0.04, 0.04, 0.8, 8], _ink), root, handleY, handleZ);
    bars.rotation.z = math.pi / 2;
    _at(mesh('Box', [0.3, 0.1, 0.55], _ink), root, seatY, seatZ);

    // Cranks and pedals spin around the bottom bracket.
    _at(_crank, root, crankY, 0);
    for (final s in [1.0, -1.0]) {
      _at(mesh('Cylinder', [0.03, 0.03, crankLength, 6], 0x888888), _crank, -s * crankLength / 2, 0, s * 0.2);
      _at(mesh('Box', [0.16, 0.04, 0.22], _ink), _crank, -s * crankLength, 0, s * 0.2);
    }
  }

  /// Rolls the bike forward by [distance] world units.
  void roll(double distance) {
    final angle = distance / wheelRadius;
    _wheelF.rotation.x += angle;
    _wheelR.rotation.x += angle;
    crank += angle * 0.6;
    _crank.rotation.x = crank;
  }
}
