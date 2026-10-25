import 'dart:math' as math;

/// The village sits on a hillside cut into terraces that rise towards -z, the
/// way hill villages in Nepal are built. This file is the (browser-free) model
/// of that terrain: heights, stairs and the walls that block walking.

/// A flat strip of the hillside. [zSouth] is its front (low) edge.
class Terrace {
  const Terrace(this.zNorth, this.zSouth, this.height);
  final double zNorth, zSouth, height;
}

/// A flight of stone steps climbing the retaining wall at [wallZ] (the front
/// edge of the upper terrace). The steps stand on the lower terrace, in front
/// of the wall, and run from z = wallZ + depth (bottom) to z = wallZ (top).
class Stair {
  const Stair({required this.x, required this.wallZ, required this.lower, required this.upper});

  static const halfWidth = 2.0;
  static const depth = 3.6;
  static const steps = 6;

  final double x, wallZ, lower, upper;

  double get rise => upper - lower;
}

const worldX = 46.0;
const worldNorth = -52.0;
const worldSouth = 30.0;

const terraces = [
  Terrace(4, worldSouth, 0),
  Terrace(-10, 4, 1.5),
  Terrace(-24, -10, 3.0),
  Terrace(-38, -24, 4.5),
  Terrace(worldNorth, -38, 6.0),
];

/// One staircase per retaining wall, alternating sides so the way up zig-zags.
const stairs = [
  Stair(x: -4, wallZ: 4, lower: 0, upper: 1.5),
  Stair(x: 6, wallZ: -10, lower: 1.5, upper: 3.0),
  Stair(x: -12, wallZ: -24, lower: 3.0, upper: 4.5),
  Stair(x: 10, wallZ: -38, lower: 4.5, upper: 6.0),
];

double _smoothstep(double a, double b, double x) {
  final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// Height of the ground at (x, z), including the steps.
double heightAt(double x, double z) {
  for (final s in stairs) {
    if ((x - s.x).abs() <= Stair.halfWidth && z >= s.wallZ && z <= s.wallZ + Stair.depth) {
      // 0 at the bottom of the flight, 1 at the wall.
      final f = (1 - (z - s.wallZ) / Stair.depth) * Stair.steps;
      final step = f.floor();
      // Quantised to treads, with a short ramp so walking up is smooth.
      final h = (step + _smoothstep(0.6, 1.0, f - step)) / Stair.steps;
      return s.lower + h.clamp(0.0, 1.0) * s.rise;
    }
  }
  for (final t in terraces) {
    if (z >= t.zNorth) return t.height;
  }
  return terraces.last.height;
}

/// An axis-aligned rectangle that can't be walked through (a house).
typedef Block = ({double x0, double x1, double z0, double z1});

final blocks = <Block>[];

/// Trees and other round obstacles.
final posts = <({double x, double z, double r})>[];

bool _inBlock(double x, double z) {
  for (final b in blocks) {
    if (x > b.x0 && x < b.x1 && z > b.z0 && z < b.z1) return true;
  }
  for (final p in posts) {
    final dx = x - p.x, dz = z - p.z;
    if (dx * dx + dz * dz < p.r * p.r) return true;
  }
  return false;
}

/// Whether (x, z) can't be stood on: outside the village, inside a house, in a
/// retaining wall (except at a staircase) or against a staircase's side rails.
bool isBlocked(double x, double z) {
  if (x.abs() > worldX || z < worldNorth || z > worldSouth) return true;

  for (final s in stairs) {
    final dx = (x - s.x).abs();
    // Retaining wall, with a gap where the stairs arrive.
    if ((z - s.wallZ).abs() < 0.35 && dx > Stair.halfWidth) return true;
    // Side rails along the flight.
    if (z >= s.wallZ && z <= s.wallZ + Stair.depth && dx > Stair.halfWidth && dx < Stair.halfWidth + 0.45) {
      return true;
    }
  }
  return _inBlock(x, z);
}

/// Moves from (x, z) by (dx, dz), sliding along anything in the way. Steps are
/// kept short so a fast rider can't skip through a thin wall.
({double x, double z}) moveWithin(double x, double z, double dx, double dz) {
  final dist = math.sqrt(dx * dx + dz * dz);
  final n = math.max(1, (dist / 0.2).ceil());
  final sx = dx / n, sz = dz / n;
  for (var i = 0; i < n; i++) {
    if (!isBlocked(x + sx, z)) x += sx;
    if (!isBlocked(x, z + sz)) z += sz;
  }
  return (x: x, z: z);
}
