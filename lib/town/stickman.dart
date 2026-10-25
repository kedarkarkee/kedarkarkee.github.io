import 'dart:math' as math;

import 'three.dart';

/// A hand-drawn style stickman.
///
/// The body is 3D and turns to face where it walks, but the head is a flat
/// disc kept in its own object that copies the camera's rotation every frame
/// ([updateFace]), so the face always looks at the screen and never animates
/// with the body.
class Stickman {
  Stickman() {
    _build();
  }

  /// Moves and turns with the character. Add to the scene.
  final root = Object3D.group();

  /// The billboarded head. Add to the scene (not to [root]).
  final face = Object3D.group();

  final _torso = Object3D.group();
  final _legP = Object3D.group(), _legN = Object3D.group();
  final _kneeP = Object3D.group(), _kneeN = Object3D.group();
  final _armP = Object3D.group(), _armN = Object3D.group();
  final _elbowP = Object3D.group(), _elbowN = Object3D.group();

  static const _ink = 0x111111;
  static const _hipY = 1.5;
  static const _thigh = 0.75, _shin = 0.75;
  static const _upperArm = 0.6, _foreArm = 0.6;
  static const _shoulderY = 0.95; // above the hips
  static const _headY = 1.75; // above the hips
  static const _headR = 0.62;

  double _bob = 0;
  double _phase = 0;
  double _lastT = 0;

  Object3D _ink3(String geometry, List<num> args) => mesh(geometry, args, _ink, basic: true);

  T _at<T extends Object3D>(T o, Object3D parent, double x, double y, double z) {
    o.position.set(x, y, z);
    parent.add(o);
    return o;
  }

  /// A thin stick hanging down from the pivot [joint], with a round joint cap.
  void _stick(Object3D joint, double length) {
    _at(_ink3('Cylinder', [0.08, 0.08, length, 8]), joint, 0, -length / 2, 0);
    _at(_ink3('Sphere', [0.09, 8, 6]), joint, 0, 0, 0);
  }

  void _build() {
    // Torso, pivoting at the hips.
    _at(_torso, root, 0, _hipY, 0);
    _at(_ink3('Cylinder', [0.08, 0.08, _headY - _headR + 0.05, 8]), _torso, 0, (_headY - _headR) / 2, 0);

    // Arms hang from one shoulder point like the reference drawing.
    for (final (arm, elbow, s) in [(_armP, _elbowP, 1.0), (_armN, _elbowN, -1.0)]) {
      _at(arm, _torso, s * 0.02, _shoulderY, 0);
      _stick(arm, _upperArm);
      _at(elbow, arm, 0, -_upperArm, 0);
      _stick(elbow, _foreArm);
      _at(_ink3('Sphere', [0.11, 10, 8]), elbow, 0, -_foreArm, 0);
    }

    // Legs hang from the hips with long flat shoes.
    for (final (leg, knee, s) in [(_legP, _kneeP, 1.0), (_legN, _kneeN, -1.0)]) {
      _at(leg, root, s * 0.03, _hipY, 0);
      _stick(leg, _thigh);
      _at(knee, leg, 0, -_thigh, 0);
      _stick(knee, _shin);
      _at(_ink3('Sphere', [0.14, 12, 8])..scale.set(1.1, 0.4, 2.0), knee, 0, -_shin, 0.12);
    }

    _buildFace();
  }

  /// A flat head: outlined white circle, eyes, brows, smile and a few hairs.
  /// Everything is basic (unlit) material so it reads as a drawing.
  void _buildFace() {
    Object3D disc(double r, int color, double z) {
      final d = mesh('Circle', [r, 40], color, basic: true);
      d.position.z = z;
      return d;
    }

    face.add(disc(_headR, _ink, 0));
    face.add(disc(_headR - 0.06, 0xffffff, 0.01));

    for (final s in [-1.0, 1.0]) {
      _at(_ink3('Circle', [0.065, 16])..scale.set(1, 1.6, 1), face, s * 0.2, 0.05, 0.02);
      // Eyebrows: the top half of a small ring, tilted away from the nose.
      final brow = _at(_ink3('Torus', [0.1, 0.018, 6, 12, math.pi]), face, s * 0.2, 0.26, 0.02);
      brow.rotation.z = -s * 0.2;
    }
    // Smile: the bottom half of a ring.
    final smile = _at(_ink3('Torus', [0.3, 0.026, 8, 24, math.pi]), face, 0, -0.04, 0.02);
    smile.rotation.z = math.pi;

    // Hair tufts sticking out of the top of the head.
    for (final (x, tilt) in [(-0.14, 0.45), (0.0, 0.1), (0.14, -0.35)]) {
      final hair = _at(_ink3('Cylinder', [0.02, 0.02, 0.28, 5]), face, x, _headR + 0.1, 0.0);
      hair.rotation.z = tilt;
    }
  }

  /// Keeps the face over the body and turned to the camera.
  void updateFace(Camera camera) {
    final p = root.position;
    face.position.set(p.x, p.y + _hipY + _headY + _bob, p.z);
    face.quaternion.copy(camera.quaternion);
  }

  /// [sprint] runs faster with a longer stride, more knee lift and a forward lean.
  void animate(double t, bool moving, {bool sprint = false}) {
    final dt = math.min(t - _lastT, 0.05);
    _lastT = t;
    if (moving) {
      // Advance the gait phase instead of using the clock, so switching
      // between walking and sprinting doesn't make the legs jump.
      _phase += dt * (sprint ? 16 : 10);
      final f = _phase;
      final s = math.sin(f), c = math.cos(f);
      final swing = sprint ? 0.95 : 0.6, armSwing = sprint ? 0.9 : 0.5;
      // A positive x-rotation swings a hanging limb backwards.
      _legP.rotation.x = -swing * s;
      _legN.rotation.x = swing * s;
      _kneeP.rotation.x = 0.05 + (sprint ? 1.5 : 0.9) * math.max(0.0, c);
      _kneeN.rotation.x = 0.05 + (sprint ? 1.5 : 0.9) * math.max(0.0, -c);
      _armP.rotation.x = armSwing * s;
      _armN.rotation.x = -armSwing * s;
      _armP.rotation.z = sprint ? 0.12 : 0.3;
      _armN.rotation.z = sprint ? -0.12 : -0.3;
      _elbowP.rotation.x = -((sprint ? 1.3 : 0.3) + 0.4 * math.max(0.0, -s));
      _elbowN.rotation.x = -((sprint ? 1.3 : 0.3) + 0.4 * math.max(0.0, s));
      _torso.rotation.x = sprint ? 0.3 : 0.08;
      _bob = (math.cos(f * 2).abs() - 1) * (sprint ? 0.1 : 0.06);
    } else {
      // Settle into a relaxed stance: legs in a slight V, arms out like the drawing.
      void ease(Object3D o, double x, double z) {
        o.rotation.x += (x - o.rotation.x) * 0.2;
        o.rotation.z += (z - o.rotation.z) * 0.2;
      }

      final breathe = math.sin(t * 2) * 0.03;
      ease(_legP, 0, 0.14);
      ease(_legN, 0, -0.14);
      ease(_kneeP, 0, 0);
      ease(_kneeN, 0, 0);
      ease(_armP, 0, 0.55 + breathe);
      ease(_armN, 0, -0.55 - breathe);
      ease(_elbowP, 0, 0);
      ease(_elbowN, 0, 0);
      ease(_torso, 0, 0);
      _bob = math.sin(t * 2) * 0.02;
    }
    _torso.position.y = _hipY + _bob;
  }
}
