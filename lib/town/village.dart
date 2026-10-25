import 'dart:math' as math;

import 'terrain.dart';
import 'three.dart';

/// A door the character can enter, opening the overlay named [id].
typedef Entrance = ({String id, String label, double x, double y, double z});

/// Builds the hillside village: stepped terraces with stone retaining walls and
/// stairs, houses with slate roofs and wooden balconies, flagstone paths,
/// trees, prayer flags, a stupa and the mountains behind.
///
/// Everything is made of primitives. Walls, houses and trees are also
/// registered with [terrain.dart] so the character can't walk through them.
class Village {
  Village() {
    _ground();
    _terraces();
    _stairs();
    _paths();
    _houses();
    _stupa();
    _flags();
    _trees();
    _mountains();
  }

  final root = Object3D.group();

  /// The tops of the terraces; click-to-walk raycasts against these.
  final walkable = Object3D.group();

  final entrances = <Entrance>[];
  final _rng = math.Random(11);

  static const _stone = [0x8d877b, 0x9b9484, 0x7f796d, 0xa39c8b];
  static const _grass = [0x8dbb5e, 0x7fae55, 0x93b65f, 0x86a851, 0x7b9f4f];

  // --- helpers ----------------------------------------------------------------

  Object3D _box(Object3D parent, double w, double h, double d, int color, double x, double y, double z) {
    final m = mesh('Box', [w, h, d], color);
    m.position.set(x, y, z);
    parent.add(m);
    return m;
  }

  Object3D _put(Object3D parent, Object3D o, double x, double y, double z) {
    o.position.set(x, y, z);
    parent.add(o);
    return o;
  }

  // --- ground, terraces, stairs ------------------------------------------------

  void _ground() {
    // Far-away green below everything so there is never a hole at the edges.
    final far = mesh('Plane', [700, 700], 0x6f9a52);
    far.rotation.x = -math.pi / 2;
    far.position.y = -1.2;
    root.add(far);
  }

  void _terraces() {
    const width = 100.0;
    for (var i = 0; i < terraces.length; i++) {
      final t = terraces[i];
      final depth = t.zSouth - t.zNorth;
      final zMid = (t.zNorth + t.zSouth) / 2;

      // Solid stone body, so the front reads as a dry-stone retaining wall.
      _box(root, width, t.height + 1.2, depth, _stone[0], 0, (t.height - 1.2) / 2, zMid);

      // Courses of slightly different stones across the wall face.
      if (t.height > 0) {
        const courses = 4;
        final bh = t.height / courses;
        for (var c = 0; c < courses; c++) {
          _box(root, width, bh * 0.9, 0.12, _stone[_rng.nextInt(_stone.length)], 0, bh * (c + 0.5), t.zSouth + 0.04);
        }
        // Coping stones along the top edge.
        _box(root, width, 0.2, 0.7, _stone[3], 0, t.height - 0.05, t.zSouth - 0.25);
      }

      final top = mesh('Plane', [width, depth], _grass[i % _grass.length]);
      top.rotation.x = -math.pi / 2;
      top.position.set(0, t.height + 0.01, zMid);
      walkable.add(top);
    }
    root.add(walkable);
  }

  void _stairs() {
    const n = Stair.steps;
    for (final s in stairs) {
      // The top step is the terrace itself, so build the n - 1 below it.
      for (var k = 1; k < n; k++) {
        final h = s.rise * k / n;
        final z = s.wallZ + Stair.depth * (1 - (k + 0.5) / n);
        _box(root, Stair.halfWidth * 2, h, Stair.depth / n + 0.02, 0xb4ad9b, s.x, s.lower + h / 2, z);
      }
      // Stone side walls that follow the slope of the flight.
      final slope = math.atan2(s.rise, Stair.depth);
      final len = math.sqrt(Stair.depth * Stair.depth + s.rise * s.rise);
      for (final side in [-1.0, 1.0]) {
        final rail = mesh('Box', [0.4, 1.0, len], _stone[1]);
        rail.rotation.x = slope;
        rail.position.set(s.x + side * (Stair.halfWidth + 0.2), s.lower + s.rise / 2 + 0.1, s.wallZ + Stair.depth / 2);
        root.add(rail);
      }
    }
  }

  // --- paths ------------------------------------------------------------------

  /// Flagstone path segments as (x0, z0, x1, z1) on a terrace of the given height.
  static const _paths_ = <(double, double, double, double, double)>[
    (0, 18, 0, 10, 0), (0, 10, -4, 10, 0), (-4, 10, -4, 8, 0),
    (-4, 3.2, -4, 0.7, 1.5), (-10, 0.7, 14, 0.7, 1.5), (6, 0.7, 6, -5.6, 1.5),
    (6, -10.6, 6, -12.4, 3.0), (-12, -12.4, 6, -12.4, 3.0), (-12, -12.4, -12, -19.6, 3.0),
    (-24, -12.4, -12, -12.4, 3.0),
    (-12, -24.6, -12, -26.3, 4.5), (-12, -26.3, 22, -26.3, 4.5), (10, -26.3, 10, -33.6, 4.5),
    (10, -38.6, 10, -41.5, 6.0),
  ];

  void _paths() {
    for (final (x0, z0, x1, z1, h) in _paths_) {
      final dx = x1 - x0, dz = z1 - z0;
      final len = math.sqrt(dx * dx + dz * dz);
      final angle = math.atan2(dx, dz);

      // A darker bed with lighter slabs laid on it.
      final bed = mesh('Box', [2.4, 0.06, len + 1.0], 0x9a9282);
      bed.position.set((x0 + x1) / 2, h + 0.03, (z0 + z1) / 2);
      bed.rotation.y = angle;
      root.add(bed);

      final n = (len / 1.25).ceil();
      for (var i = 0; i <= n; i++) {
        final t = i / n;
        final px = x0 + dx * t, pz = z0 + dz * t;
        for (final side in [-0.6, 0.6]) {
          final jitter = (_rng.nextDouble() - 0.5) * 0.2;
          final slab = mesh('Box', [1.0 + _rng.nextDouble() * 0.15, 0.1, 0.95], [0xb9b2a1, 0xc4bdab, 0xaaa392][_rng.nextInt(3)]);
          slab.position.set(px + math.cos(angle) * (side + jitter), h + 0.07 + _rng.nextDouble() * 0.02, pz - math.sin(angle) * (side + jitter));
          slab.rotation.y = angle + (_rng.nextDouble() - 0.5) * 0.15;
          root.add(slab);
        }
      }
    }
  }

  bool _nearPath(double x, double z, double margin) {
    for (final (x0, z0, x1, z1, _) in _paths_) {
      final minX = math.min(x0, x1) - margin, maxX = math.max(x0, x1) + margin;
      final minZ = math.min(z0, z1) - margin, maxZ = math.max(z0, z1) + margin;
      if (x >= minX && x <= maxX && z >= minZ && z <= maxZ) return true;
    }
    return false;
  }

  // --- houses -----------------------------------------------------------------

  void _houses() {
    // Labelled houses: the ones you can walk into.
    _house(-10, -4, w: 9, d: 6, id: 'about', label: 'About me');
    _house(14, -4, w: 10, d: 6, id: 'projects', label: 'Projects', awning: true);
    _house(-24, -17, w: 10, d: 6, id: 'experience', label: 'Experience');
    _house(6, -17, w: 9, d: 6, id: 'education', label: 'Education', awning: true);
    _house(-12, -31, w: 9, d: 6, id: 'skills', label: 'Skills');
    _house(22, -31, w: 10, d: 6, id: 'contact', label: 'Contact me', awning: true);

    // Neighbours, to make it feel like a village.
    for (final (x, z, w, floors) in [
      (-34.0, -4.0, 8.0, 2), (32.0, -4.0, 8.0, 2), (-36.0, 16.0, 7.0, 1), (36.0, 18.0, 7.0, 1),
      (-34.0, -17.0, 7.0, 1), (34.0, -17.0, 8.0, 2), (-34.0, -31.0, 8.0, 2), (36.0, -31.0, 7.0, 1),
      (-26.0, -45.0, 8.0, 2), (28.0, -45.0, 8.0, 2), (-6.0, -45.0, 7.0, 1),
    ]) {
      _house(x, z, w: w, d: 6, floors: floors, awning: _rng.nextBool());
    }
  }

  void _house(
    double cx,
    double cz, {
    required double w,
    required double d,
    int floors = 2,
    String? id,
    String? label,
    bool awning = false,
  }) {
    final base = heightAt(cx, cz);
    final g = Object3D.group();
    g.position.set(cx, base, cz);
    root.add(g);

    const wood = 0x7a4b2a, blue = 0x2f6fb5, dark = 0x26323c;
    final lowerWall = [0xc9c3b5, 0xd8d2c4, 0xb85c3f][_rng.nextInt(3)];
    final upperWall = [0xefeadc, 0xe6dccb, 0xf3efe4][_rng.nextInt(3)];
    const storey = 3.3;

    _box(g, w + 0.4, 0.5, d + 0.4, 0x8a8478, 0, 0.25, 0); // stone plinth
    _box(g, w, storey, d, lowerWall, 0, 0.5 + storey / 2, 0);
    var top = 0.5 + storey;
    if (floors > 1) {
      _box(g, w + 0.15, 0.15, d + 0.15, wood, 0, top, 0); // timber band between floors
      _box(g, w - 0.3, 3.0, d - 0.3, upperWall, 0, top + 1.5, 0);
      top += 3.0;
    }

    // Front door with a blue frame.
    _box(g, 1.7, 2.9, 0.1, blue, 0, 0.5 + 1.45, d / 2 + 0.01);
    _box(g, 1.3, 2.7, 0.12, 0x5e3b22, 0, 0.5 + 1.35, d / 2 + 0.06);

    // Windows with blue frames.
    void window(double x, double y) {
      _box(g, 1.15, 1.15, 0.1, blue, x, y, d / 2 + 0.01);
      _box(g, 0.9, 0.9, 0.12, dark, x, y, d / 2 + 0.05);
    }

    final xs = w >= 9 ? [-w * 0.32, w * 0.32] : [-w * 0.28, w * 0.28];
    for (final x in xs) {
      window(x, 0.5 + 1.9);
    }
    if (floors > 1) {
      for (final x in [...xs, 0.0]) {
        window(x, 0.5 + storey + 1.7);
      }
      // Wooden balcony with a blue railing.
      final bw = w - 1.2;
      _box(g, bw, 0.15, 1.1, wood, 0, 0.5 + storey + 0.08, d / 2 + 0.55);
      _box(g, bw, 0.08, 0.08, blue, 0, 0.5 + storey + 0.95, d / 2 + 1.05);
      _box(g, bw, 0.06, 0.06, blue, 0, 0.5 + storey + 0.45, d / 2 + 1.05);
      for (var i = 0; i <= 6; i++) {
        _box(g, 0.07, 0.9, 0.07, blue, -bw / 2 + bw * i / 6, 0.5 + storey + 0.5, d / 2 + 1.05);
      }
    }

    if (awning) {
      // Blue tin awning over the entrance, held up by two poles.
      final a = _box(g, w * 0.55, 0.08, 1.8, 0x2478c8, 0, 0.5 + 3.2, d / 2 + 0.9);
      a.rotation.x = 0.18;
      for (final s in [-1.0, 1.0]) {
        _box(g, 0.08, 3.0, 0.08, wood, s * w * 0.25, 0.5 + 1.5, d / 2 + 1.7);
      }
    }

    // Slate roof: a hipped pyramid with a wide overhang.
    final roof = Object3D.group();
    roof.scale.set((w / 2 + 0.8) / 0.7071, 1, (d / 2 + 0.8) / 0.7071);
    final cone = mesh('Cone', [1, 2.8, 4], [0x6f6b68, 0x77726c, 0x66625f][_rng.nextInt(3)]);
    cone.rotation.y = math.pi / 4;
    cone.position.y = 1.4;
    roof.add(cone);
    _put(g, roof, 0, top, 0);

    // Footprint the character can't walk through.
    blocks.add((x0: cx - w / 2 - 0.5, x1: cx + w / 2 + 0.5, z0: cz - d / 2 - 0.4, z1: cz + d / 2 + 0.5));

    if (id == null || label == null) return;

    // Signboard hung from the balcony, facing the camera.
    final sign = signboard(label, w - 2.0, 1.0);
    _put(g, sign, 0, 0.5 + storey + 0.55, d / 2 + 1.12);

    // A glowing ring marks the spot to stand on to go in.
    final ring = mesh('Torus', [0.8, 0.07, 8, 28], 0xffc107, basic: true);
    ring.rotation.x = math.pi / 2;
    _put(g, ring, 0, 0.1, d / 2 + 1.7);
    entrances.add((id: id, label: label, x: cx, y: base, z: cz + d / 2 + 1.7));
  }

  // --- the stupa on the top terrace -----------------------------------------------

  void _stupa() {
    const x = 10.0, z = -47.0;
    final y = heightAt(x, z);
    final g = Object3D.group();
    g.position.set(x, y, z);
    root.add(g);

    const white = 0xf6f1e7;
    _put(g, mesh('Cylinder', [3.6, 3.8, 0.5, 20], 0xd9d2c3), 0, 0.25, 0);
    _put(g, mesh('Cylinder', [3.0, 3.2, 0.5, 20], 0xe6dfd0), 0, 0.75, 0);
    final dome = mesh('Sphere', [2.5, 24, 14], white);
    dome.scale.set(1, 0.8, 1);
    _put(g, dome, 0, 1.0, 0);
    _box(g, 1.7, 1.3, 1.7, white, 0, 3.4, 0); // harmika
    _box(g, 1.72, 0.25, 1.72, 0xc0392b, 0, 3.1, 0);
    // The painted eyes of the Buddha on the front.
    for (final s in [-1.0, 1.0]) {
      _box(g, 0.34, 0.12, 0.05, 0x1a1a1a, s * 0.38, 3.5, 0.87);
    }
    _box(g, 0.1, 0.22, 0.05, 0xc0392b, 0, 3.3, 0.87);
    _put(g, mesh('Cone', [0.95, 3.2, 14], 0xd4a017), 0, 6.0, 0);
    _put(g, mesh('Sphere', [0.22, 10, 8], 0xd4a017), 0, 7.7, 0);

    posts.add((x: x, z: z, r: 4.0));
  }

  // --- prayer flags -----------------------------------------------------------------

  void _flags() {
    // Strings of lungta between poles; the stupa gets a few going out to the corners.
    _flagString(-26, 7, -14, 7, 0);
    _flagString(14, -12, 30, -12, 3.0);
    _flagString(-4, -27.8, -22, -27.8, 4.5);
    for (final (x, z) in [(2.0, -40.0), (18.0, -40.0), (2.0, -51.0), (18.0, -51.0)]) {
      _flagString(10, -47, x, z, 6.0, from: 7.2);
    }
  }

  void _flagString(double x0, double z0, double x1, double z1, double baseY, {double from = 5.5}) {
    const colors = [0x1e88e5, 0xfafafa, 0xe53935, 0x43a047, 0xfdd835];
    final dx = x1 - x0, dz = z1 - z0;
    final len = math.sqrt(dx * dx + dz * dz);
    final angle = -math.atan2(dz, dx);
    final startY = baseY + from;
    final endY = baseY + 5.5;

    for (final (x, z, h) in [(x0, z0, startY), (x1, z1, endY)]) {
      if (from > 6 && x == x0 && z == z0) continue; // the stupa itself is the pole
      _put(root, mesh('Cylinder', [0.08, 0.1, h - baseY, 6], 0x7a4b2a), x, baseY + (h - baseY) / 2, z);
    }
    final n = math.max(6, (len / 0.9).floor());
    for (var i = 1; i < n; i++) {
      final t = i / n;
      final sag = 1.0 * (1 - math.pow(2 * t - 1, 2));
      final y = startY + (endY - startY) * t - sag - 0.3;
      final flag = mesh('Box', [0.65, 0.5, 0.03], colors[i % colors.length]);
      flag.position.set(x0 + dx * t, y, z0 + dz * t);
      flag.rotation.y = angle;
      root.add(flag);
    }
  }

  // --- trees ------------------------------------------------------------------------

  bool _clear(double x, double z) {
    for (final (ox, oz) in [(0.0, 0.0), (2.0, 0.0), (-2.0, 0.0), (0.0, 2.0), (0.0, -2.0)]) {
      if (isBlocked(x + ox, z + oz)) return false;
    }
    if (_nearPath(x, z, 2.2)) return false;
    for (final s in stairs) {
      if ((x - s.x).abs() < 5 && z > s.wallZ - 3 && z < s.wallZ + Stair.depth + 3) return false;
    }
    for (final e in entrances) {
      if ((x - e.x).abs() < 3.5 && (z - e.z).abs() < 3.5) return false;
    }
    return true;
  }

  void _trees() {
    var placed = 0;
    for (var tries = 0; tries < 500 && placed < 55; tries++) {
      final x = _rng.nextDouble() * 88 - 44, z = _rng.nextDouble() * 78 - 50;
      if (!_clear(x, z)) continue;
      final y = heightAt(x, z);
      final g = Object3D.group();
      g.position.set(x, y, z);
      root.add(g);
      final s = 0.8 + _rng.nextDouble() * 0.7;
      if (_rng.nextInt(4) == 0) {
        // Pine
        _put(g, mesh('Cylinder', [0.25 * s, 0.35 * s, 2 * s, 6], 0x6b4a2b), 0, s, 0);
        for (var i = 0; i < 3; i++) {
          _put(g, mesh('Cone', [(1.9 - i * 0.45) * s, 2.4 * s, 7], 0x2f6b3f, flat: true), 0, (2.6 + i * 1.5) * s, 0);
        }
      } else {
        // Broadleaf, as on the hillsides
        _put(g, mesh('Cylinder', [0.25 * s, 0.4 * s, 2.6 * s, 6], 0x7a5a3a), 0, 1.3 * s, 0);
        final leaf = [0x5a9a3c, 0x6aa84a, 0x4f8a3c, 0x78b04c][_rng.nextInt(4)];
        _put(g, mesh('Sphere', [1.7 * s, 8, 6], leaf, flat: true), 0, 3.4 * s, 0);
        _put(g, mesh('Sphere', [1.2 * s, 8, 6], leaf, flat: true), 0.9 * s, 2.9 * s, 0.4 * s);
      }
      posts.add((x: x, z: z, r: 0.9));
      placed++;
    }
  }

  // --- mountains ----------------------------------------------------------------------

  void _mountains() {
    void peak(double x, double z, double r, double h, int color) {
      final m = mesh('Cone', [r, h, 7], color, flat: true);
      m.position.set(x, h / 2 - 3, z);
      m.rotation.y = _rng.nextDouble() * 3;
      root.add(m);
    }

    // Hazy blue range behind the village, snow-free like the photo.
    for (var i = 0; i < 12; i++) {
      peak(-150 + i * 28.0 + _rng.nextDouble() * 12, -150 - _rng.nextDouble() * 50, 48 + _rng.nextDouble() * 20,
          70 + _rng.nextDouble() * 50, i.isEven ? 0x5f8fb8 : 0x6a98bd);
    }
    // Greener hills flanking the terraces.
    for (var i = 0; i < 7; i++) {
      for (final side in [-1.0, 1.0]) {
        peak(side * (80 + _rng.nextDouble() * 25), -110 + i * 20.0, 28 + _rng.nextDouble() * 12,
            34 + _rng.nextDouble() * 22, [0x4c7d53, 0x588a4c, 0x477a58][_rng.nextInt(3)]);
      }
    }
    peak(-62, -75, 30, 44, 0x4f8553);
    peak(66, -80, 32, 48, 0x4c7d53);
  }
}
