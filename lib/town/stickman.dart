import 'dart:math' as math;

import 'bicycle.dart';
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
    root.scale.set(scale, scale, scale);
    face.scale.set(scale, scale, scale);
  }

  /// Size relative to the modelled units, so he fits through the village doors.
  static const scale = 0.65;

  /// Moves and turns with the character. Add to the scene.
  final root = Object3D.group();

  /// The billboarded head. Add to the scene (not to [root]).
  final face = Object3D.group();

  /// Holds the whole body so it can be lifted onto a bicycle seat.
  final _rig = Object3D.group();
  final _torso = Object3D.group();
  final _legP = Object3D.group(), _legN = Object3D.group();
  final _kneeP = Object3D.group(), _kneeN = Object3D.group();
  final _armP = Object3D.group(), _armN = Object3D.group();
  final _cape = Object3D.group();
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

  /// Every black line of the body (not the face), so night mode can lighten them.
  final _inkParts = <Object3D>[];
  List<Object3D> _limbs = const [];

  Object3D _ink3(String geometry, List<num> args) {
    final m = mesh(geometry, args, _ink, basic: true);
    _inkParts.add(m);
    return m;
  }

  /// At night the black body would vanish into the dark, so draw it light.
  void setNight(bool night) {
    for (final m in _limbs) {
      setMeshColor(m, night ? 0xf2f2f2 : _ink);
    }
  }

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
    root.add(_rig);

    // Torso, pivoting at the hips.
    _at(_torso, _rig, 0, _hipY, 0);
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
      _at(leg, _rig, s * 0.03, _hipY, 0);
      _stick(leg, _thigh);
      _at(knee, leg, 0, -_thigh, 0);
      _stick(knee, _shin);
      _at(_ink3('Sphere', [0.14, 12, 8])..scale.set(1.1, 0.4, 2.0), knee, 0, -_shin, 0.12);
    }

    // A red cape, only shown in flight.
    _at(_cape, _torso, 0, _shoulderY, -0.1);
    _at(mesh('Box', [0.9, 1.7, 0.03], 0xe53935, basic: true), _cape, 0, -0.85, 0);
    _cape.visible = false;

    _limbs = List.of(_inkParts);
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

  /// Keeps the face over the head (following the lean, the flight pitch and
  /// any lift onto a bike) and turned to the camera.
  void updateFace(Camera camera) {
    final p = root.position;
    final pitch = _rig.rotation.x;
    final total = pitch + _torso.rotation.x;
    final hip = _torso.position.y;
    final up = _rig.position.y + hip * math.cos(pitch) + _headY * math.cos(total);
    final fwd = (_rig.position.z + hip * math.sin(pitch) + _headY * math.sin(total)) * scale;
    final h = root.rotation.y;
    face.position.set(p.x + fwd * math.sin(h), p.y + up * scale, p.z + fwd * math.cos(h));
    face.quaternion.copy(camera.quaternion);
  }

  /// Two-link IK in the (z, y) plane. Returns the forward angle of the first
  /// link from straight down, and the bend of the second relative to it.
  /// [kneeForward] puts the joint in front of the line (legs) or below it (arms).
  (double, double) _ik(double a, double b, double dz, double dy, {required bool kneeForward}) {
    final d = math.min(math.sqrt(dz * dz + dy * dy), a + b - 0.01);
    final toTarget = math.atan2(dz, dy);
    final alpha = math.acos(((a * a + d * d - b * b) / (2 * a * d)).clamp(-1.0, 1.0));
    final interior = math.acos(((a * a + b * b - d * d) / (2 * a * b)).clamp(-1.0, 1.0));
    return (kneeForward ? toTarget + alpha : toTarget - alpha, math.pi - interior);
  }

  /// Seated on the bicycle: feet follow the pedals ([crank]) and hands grip
  /// the handlebar.
  void _ride(double crank) {
    const lean = 0.35;
    const hipZ = -0.35, hipY = 1.9;
    _rig.position.set(0, hipY - _hipY, hipZ);
    _torso.rotation.x = lean;
    _bob = 0;

    for (final (leg, knee, s) in [(_legP, _kneeP, 1.0), (_legN, _kneeN, -1.0)]) {
      // Pedal position on the crank circle; the ankle sits just above it.
      final z = -s * Bicycle.crankLength * math.sin(crank);
      final y = Bicycle.crankY - s * Bicycle.crankLength * math.cos(crank) + 0.12;
      final (thigh, bend) = _ik(_thigh, _shin, z - hipZ, hipY - y, kneeForward: true);
      leg.rotation.x = -thigh;
      leg.rotation.z = s * 0.1;
      knee.rotation.x = bend;
    }

    final shoulderZ = hipZ + _shoulderY * math.sin(lean);
    final shoulderY = hipY + _shoulderY * math.cos(lean);
    for (final (arm, elbow, s) in [(_armP, _elbowP, 1.0), (_armN, _elbowN, -1.0)]) {
      final (upper, bend) = _ik(_upperArm, _foreArm, Bicycle.handleZ - shoulderZ, shoulderY - Bicycle.handleY, kneeForward: false);
      // Arm angles are relative to the leaning torso.
      arm.rotation.x = -upper - lean;
      arm.rotation.z = s * 0.3;
      elbow.rotation.x = -bend;
    }
  }

  /// [sprint] runs faster with a longer stride, more knee lift and a forward lean.
  ///
  /// [riding] seats him on a bicycle whose crank is at angle [crank].
  ///
  /// [airborne] is a jump (limbs spread), [flying] is the Superman pose.
  void animate(
    double t,
    bool moving, {
    bool sprint = false,
    bool riding = false,
    double crank = 0,
    bool airborne = false,
    bool flying = false,
  }) {
    final dt = math.min(t - _lastT, 0.05);
    _lastT = t;
    _cape.visible = flying;
    if (riding) {
      _rig.rotation.x = 0;
      _ride(crank);
      return;
    }

    // Pitch the whole body forward for flight (hip stays at the same height).
    final pitchTarget = flying ? math.pi / 2 : 0.0;
    _rig.rotation.x += (pitchTarget - _rig.rotation.x) * math.min(1, dt * 8);
    final f = _rig.rotation.x / (math.pi / 2);
    _rig.position.set(0, _hipY * f, -_hipY * f);

    if (flying) {
      // Arms stretched out ahead of the head, legs straight back, cape streaming.
      void ease(Object3D o, double x, double z) {
        o.rotation.x += (x - o.rotation.x) * 0.2;
        o.rotation.z += (z - o.rotation.z) * 0.2;
      }

      ease(_armP, math.pi, 0.08);
      ease(_armN, math.pi, -0.08);
      ease(_elbowP, 0, 0);
      ease(_elbowN, 0, 0);
      ease(_torso, 0, 0);
      final flutter = math.sin(t * 14) * 0.04;
      _legP.rotation.x += (flutter - _legP.rotation.x) * 0.2;
      _legN.rotation.x += (-flutter - _legN.rotation.x) * 0.2;
      _legP.rotation.z += (0.05 - _legP.rotation.z) * 0.2;
      _legN.rotation.z += (-0.05 - _legN.rotation.z) * 0.2;
      _kneeP.rotation.x *= 0.8;
      _kneeN.rotation.x *= 0.8;
      _cape.rotation.x = 0.3 + math.sin(t * 12) * 0.12;
      _bob = 0;
      _torso.position.y = _hipY;
      return;
    }

    if (airborne) {
      // Jump: arms thrown up and out, knees tucked.
      _armP.rotation.x = 0;
      _armN.rotation.x = 0;
      _armP.rotation.z = 2.4;
      _armN.rotation.z = -2.4;
      _elbowP.rotation.x = 0;
      _elbowN.rotation.x = 0;
      _legP.rotation.x = -0.7;
      _legN.rotation.x = -0.3;
      _legP.rotation.z = 0.1;
      _legN.rotation.z = -0.1;
      _kneeP.rotation.x = 1.1;
      _kneeN.rotation.x = 0.8;
      _torso.rotation.x = 0;
      _bob = 0;
      _torso.position.y = _hipY;
      return;
    }

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
