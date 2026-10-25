import 'dart:math' as math;

import 'three.dart';

/// A simple blue robot-cat character built from three.js primitives.
class Dora {
  Dora() {
    _build();
  }

  final root = Object3D.group();
  final _body = Object3D.group();
  final _legL = Object3D.group();
  final _legR = Object3D.group();
  final _armL = Object3D.group();
  final _armR = Object3D.group();

  static const _blue = 0x1e88e5;
  static const _white = 0xffffff;
  static const _red = 0xe53935;
  static const _yellow = 0xffd54f;

  Object3D _part(Object3D o, Object3D parent, double x, double y, double z) {
    o.position.set(x, y, z);
    parent.add(o);
    return o;
  }

  void _build() {
    root.add(_body);

    // Torso and belly.
    _part(mesh('Sphere', [0.65, 24, 16], _blue)..scale.set(1, 1.1, 0.9), _body, 0, 1.1, 0);
    _part(mesh('Sphere', [0.45, 20, 12], _white)..scale.set(1, 1, 0.45), _body, 0, 1.05, 0.45);
    // Four-dimensional pocket.
    _part(mesh('Torus', [0.22, 0.04, 8, 20], _white)..rotation.x = 0, _body, 0, 0.85, 0.65);

    // Head: blue ball with a white face, no ears.
    final head = _part(Object3D.group(), _body, 0, 2.3, 0);
    _part(mesh('Sphere', [0.85, 28, 20], _blue), head, 0, 0, 0);
    _part(mesh('Sphere', [0.66, 24, 16], _white)..scale.set(1, 1, 0.7), head, 0, -0.12, 0.32);
    for (final s in [-1.0, 1.0]) {
      _part(mesh('Sphere', [0.18, 16, 12], _white), head, s * 0.18, 0.32, 0.68);
      _part(mesh('Sphere', [0.07, 12, 8], 0x111111), head, s * 0.18 - s * 0.02, 0.32, 0.84);
      // Whiskers.
      for (final a in [-0.25, 0.0, 0.25]) {
        final w = mesh('Cylinder', [0.012, 0.012, 0.6, 4], 0x222222);
        w.rotation.z = math.pi / 2 + a * s;
        _part(w, head, s * 0.5, -0.2 + a * 0.5, 0.74);
      }
    }
    _part(mesh('Sphere', [0.11, 16, 12], _red), head, 0, 0.12, 0.84);

    // Collar and bell.
    _part(mesh('Torus', [0.55, 0.07, 8, 24], _red)..rotation.x = math.pi / 2, _body, 0, 1.65, 0);
    _part(mesh('Sphere', [0.14, 12, 8], _yellow), _body, 0, 1.55, 0.55);

    // Arms (pivot at the shoulder) and legs (pivot at the hip).
    for (final (arm, s) in [(_armL, -1.0), (_armR, 1.0)]) {
      _part(arm, _body, s * 0.72, 1.45, 0);
      _part(mesh('Cylinder', [0.13, 0.13, 0.7, 10], _blue)..position.y = -0.3, arm, 0, 0, 0);
      _part(mesh('Sphere', [0.17, 12, 8], _white), arm, 0, -0.7, 0);
    }
    for (final (leg, s) in [(_legL, -1.0), (_legR, 1.0)]) {
      _part(leg, root, s * 0.3, 0.55, 0);
      _part(mesh('Cylinder', [0.17, 0.17, 0.5, 10], _blue)..position.y = -0.2, leg, 0, 0, 0);
      _part(mesh('Sphere', [0.24, 12, 8], _white)..scale.set(1, 0.6, 1.3), leg, 0, -0.45, 0.06);
    }

    // Round red tail.
    _part(mesh('Sphere', [0.14, 12, 8], _red), _body, 0, 0.85, -0.7);
  }

  void animate(double t, bool moving) {
    if (moving) {
      final swing = math.sin(t * 10) * 0.7;
      _legL.rotation.x = swing;
      _legR.rotation.x = -swing;
      _armL.rotation.x = -swing;
      _armR.rotation.x = swing;
      _body.position.y = (math.sin(t * 20)).abs() * 0.1;
    } else {
      for (final p in [_legL, _legR, _armL, _armR]) {
        p.rotation.x *= 0.8;
      }
      _body.position.y = math.sin(t * 2) * 0.03;
    }
  }
}
