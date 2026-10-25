import 'dart:math' as math;

import 'three.dart';

/// The sky dome: a sun and drifting clouds by day, a moon and stars by night.
///
/// Everything sits far away and the group follows the camera, so it never
/// parallaxes, and it ignores fog so it stays crisp behind the hazy hills.
class Sky {
  Sky() {
    _build();
    setNight(false);
  }

  final root = Object3D.group();
  final _day = Object3D.group();
  final _night = Object3D.group();
  final _clouds = Object3D.group();
  final _cloudParts = <Object3D>[];

  static const _radius = 420.0;

  /// Puts [o] on the sky sphere in direction (x, y, z), facing the camera.
  T _place<T extends Object3D>(T o, Object3D parent, double x, double y, double z) {
    final len = math.sqrt(x * x + y * y + z * z);
    o.position.set(x / len * _radius, y / len * _radius, z / len * _radius);
    parent.add(o);
    return o;
  }

  Object3D _disc(double r, int color, {double opacity = 1}) => softDisc(r, color, opacity: opacity);

  void _build() {
    root.add(_day);
    root.add(_night);
    root.add(_clouds);

    // The camera looks towards about (-0.57, -0.82); the sun sits ahead and to the left.
    for (final (r, c, o) in [(40.0, 0xfff2b8, 0.18), (28.0, 0xffeaa0, 0.3), (17.0, 0xfffbe0, 1.0)]) {
      _place(_disc(r, c, opacity: o), _day, -0.80, 0.24, -0.56).lookAt(0, 0, 0);
    }

    for (final (r, c, o) in [(26.0, 0xbfd0ff, 0.14), (12.5, 0xf6f3e4, 1.0)]) {
      _place(_disc(r, c, opacity: o), _night, -0.42, 0.27, -0.86).lookAt(0, 0, 0);
    }
    // Craters, nudged in front of the moon's face.
    final moonDir = [-0.42, 0.27, -0.86];
    for (final (dx, dy, r) in [(-3.5, 2.5, 2.4), (3.0, -2.0, 1.8), (1.0, 4.5, 1.3)]) {
      final crater = _disc(r, 0xd9d5c4);
      final len = math.sqrt(moonDir[0] * moonDir[0] + moonDir[1] * moonDir[1] + moonDir[2] * moonDir[2]);
      // Offset along the moon's local axes, then pull slightly towards the camera.
      crater.position.set(
        moonDir[0] / len * (_radius - 0.5) + dx * 0.85,
        moonDir[1] / len * (_radius - 0.5) + dy,
        moonDir[2] / len * (_radius - 0.5) + dx * 0.5,
      );
      crater.lookAt(0, 0, 0);
      _night.add(crater);
    }

    // A scatter of stars over the upper sky.
    final rng = math.Random(5);
    for (var i = 0; i < 90; i++) {
      final az = rng.nextDouble() * 2 * math.pi;
      final el = (0.08 + rng.nextDouble() * 0.9);
      final c = math.cos(math.asin(el));
      final star = _disc(0.7 + rng.nextDouble() * 1.1, i % 7 == 0 ? 0xffe9b0 : 0xffffff, opacity: 0.55 + rng.nextDouble() * 0.45);
      _place(star, _night, math.sin(az) * c, el, math.cos(az) * c).lookAt(0, 0, 0);
    }

    // Puffy clouds all round the horizon, each a clump of flattened spheres.
    for (var i = 0; i < 16; i++) {
      final az = i * 2 * math.pi / 16 + rng.nextDouble() * 0.3;
      final el = 0.1 + rng.nextDouble() * 0.2;
      final c = math.cos(math.asin(el));
      final cloud = Object3D.group();
      for (var j = 0; j < 5; j++) {
        final puff = mesh('Sphere', [12 + rng.nextDouble() * 10, 10, 8], 0xffffff, basic: true, fog: false);
        puff.scale.set(1.3, 0.5, 0.8);
        puff.position.set((j - 2) * 15 + rng.nextDouble() * 6, rng.nextDouble() * 5, rng.nextDouble() * 8);
        cloud.add(puff);
        _cloudParts.add(puff);
      }
      _place(cloud, _clouds, math.sin(az) * c, el, math.cos(az) * c).lookAt(0, 0, 0);
    }
  }

  /// Swaps the sun and white clouds for the moon, stars and dim clouds.
  void setNight(bool night) {
    _day.visible = !night;
    _night.visible = night;
    for (final p in _cloudParts) {
      setMeshColor(p, night ? 0x3a4668 : 0xffffff);
    }
  }

  /// Follows the camera and lets the clouds drift.
  void update(Vec3 cameraPosition, double seconds) {
    root.position.set(cameraPosition.x, cameraPosition.y, cameraPosition.z);
    _clouds.rotation.y = seconds * 0.004;
  }
}
