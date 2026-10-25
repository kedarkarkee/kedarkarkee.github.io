import 'dart:js_interop';
import 'dart:math' as math;

import 'package:web/web.dart' as web;

import 'terrain.dart';
import 'village.dart';

/// A round mini-map in the top-left corner.
///
/// It is rotated to match the camera, so "up" on the map is "up" on screen and
/// W always moves towards the top of it. It shows the terraces, stairs, houses
/// and trees, a coloured lettered badge on each house you can enter, the bike,
/// and the character (a dot with an arrow for the way he faces).
class Minimap {
  Minimap(this.container, this.entrances, {required this.cameraAzimuth}) {
    _build();
  }

  final web.HTMLElement container;
  final List<Entrance> entrances;

  /// How far the camera is swung round from due south, in radians.
  final double cameraAzimuth;

  late final web.HTMLCanvasElement _canvas;
  late final web.CanvasRenderingContext2D _ctx;
  bool _night = false;
  double _lastDraw = -1;

  static const _size = 340; // canvas pixels; CSS scales it down
  static const _centerX = 0.0, _centerZ = (worldNorth + worldSouth) / 2;

  /// Badge colour and letter for each house you can enter.
  static const _badges = {
    'about': (0xe53935, 'A'),
    'projects': (0x1e88e5, 'P'),
    'experience': (0x8e24aa, 'X'),
    'education': (0x43a047, 'E'),
    'skills': (0xfb8c00, 'S'),
    'contact': (0x00acc1, 'C'),
  };

  String _css(int hex) => '#${hex.toRadixString(16).padLeft(6, '0')}';

  void _build() {
    final box = web.document.createElement('div') as web.HTMLElement..className = 'minimap';
    _canvas = web.document.createElement('canvas') as web.HTMLCanvasElement
      ..className = 'minimap-canvas'
      ..width = _size
      ..height = _size;
    _ctx = _canvas.getContext('2d') as web.CanvasRenderingContext2D;
    box.append(_canvas);

    // A small legend naming each coloured badge.
    final legend = web.document.createElement('div') as web.HTMLElement..className = 'minimap-legend';
    for (final e in entrances) {
      final b = _badges[e.id];
      if (b == null) continue;
      final item = web.document.createElement('span') as web.HTMLElement..className = 'minimap-key';
      final dot = web.document.createElement('i') as web.HTMLElement
        ..className = 'minimap-dot'
        ..style.background = _css(b.$1)
        ..textContent = b.$2;
      item.append(dot);
      item.append(web.document.createTextNode(e.label));
      legend.append(item);
    }
    box.append(legend);
    container.append(box);
  }

  void setNight(bool night) {
    _night = night;
    _lastDraw = -1; // redraw straight away
  }

  /// Redraws (at most ~20 times a second) with the character at (x, z) facing [heading].
  void update(double seconds, double x, double z, double heading, {required ({double x, double z}) bike, required bool riding}) {
    if (seconds - _lastDraw < 0.05) return;
    _lastDraw = seconds;
    _draw(x, z, heading, bike, riding);
  }

  // --- drawing ---------------------------------------------------------------

  // World -> canvas pixels, rotated so camera-forward is up.
  static const _scale = 2.55;
  double get _a => cameraAzimuth;

  double _px(double x, double z) =>
      _size / 2 + _scale * ((x - _centerX) * math.cos(_a) - (z - _centerZ) * math.sin(_a));
  double _py(double x, double z) =>
      _size / 2 + _scale * ((x - _centerX) * math.sin(_a) + (z - _centerZ) * math.cos(_a));

  /// Applies the world->canvas transform so we can draw in world units.
  void _worldSpace() {
    final c = _scale * math.cos(_a), s = _scale * math.sin(_a);
    final e = _size / 2 - (c * _centerX - s * _centerZ);
    final f = _size / 2 - (s * _centerX + c * _centerZ);
    _ctx.setTransform(c.toJS, s, -s, c, e, f);
  }

  void _screenSpace() => _ctx.setTransform(1.toJS, 0, 0, 1, 0, 0);

  void _fill(String color) => _ctx.fillStyle = color.toJS;
  void _stroke(String color) => _ctx.strokeStyle = color.toJS;

  void _draw(double x, double z, double heading, ({double x, double z}) bike, bool riding) {
    final ctx = _ctx;
    final n = _night;
    _screenSpace();
    ctx.clearRect(0, 0, _size, _size);

    // Everything is clipped to a circle.
    ctx.save();
    ctx.beginPath();
    ctx.arc(_size / 2, _size / 2, _size / 2 - 4, 0, math.pi * 2);
    ctx.clip();
    _fill(n ? '#0d1626' : '#dfeccf');
    ctx.fillRect(0, 0, _size, _size);

    _worldSpace();

    // Terraces, darker as they climb.
    for (var i = 0; i < terraces.length; i++) {
      final t = terraces[i];
      _fill(n ? ['#1d2b3a', '#223344', '#273a4d', '#2c4157', '#314963'][i] : ['#cde2a8', '#c0d99b', '#b3cf8f', '#a6c583', '#99bb77'][i]);
      ctx.fillRect(-worldX, t.zNorth, worldX * 2, t.zSouth - t.zNorth);
    }
    // Retaining walls, with a gap for each staircase.
    _stroke(n ? '#6b7c92' : '#8a8070');
    ctx.lineWidth = 1.1;
    for (final s in stairs) {
      ctx.beginPath();
      ctx.moveTo(-worldX, s.wallZ);
      ctx.lineTo(s.x - Stair.halfWidth, s.wallZ);
      ctx.moveTo(s.x + Stair.halfWidth, s.wallZ);
      ctx.lineTo(worldX, s.wallZ);
      ctx.stroke();
    }
    _fill(n ? '#9aa6b5' : '#e8dfc9');
    for (final s in stairs) {
      ctx.fillRect(s.x - Stair.halfWidth, s.wallZ, Stair.halfWidth * 2, Stair.depth);
    }

    // Trees and the stupa.
    for (final p in posts) {
      ctx.beginPath();
      if (p.r > 2) {
        _fill(n ? '#d9d4c4' : '#fbf6e8');
        ctx.arc(p.x, p.z, 3.4, 0, math.pi * 2);
      } else {
        _fill(n ? '#25503a' : '#5f9a55');
        ctx.arc(p.x, p.z, 1.1, 0, math.pi * 2);
      }
      ctx.fill();
    }

    // Houses, and which block each enterable door belongs to.
    final enterable = <int, Entrance>{};
    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      for (final e in entrances) {
        if (e.x > b.x0 && e.x < b.x1 && e.z - 1.5 > b.z0 && e.z - 1.5 < b.z1) enterable[i] = e;
      }
    }
    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      final e = enterable[i];
      final badge = e == null ? null : _badges[e.id];
      _fill(badge != null ? _css(badge.$1) : (n ? '#59626f' : '#a99a84'));
      ctx.fillRect(b.x0 + 0.4, b.z0 + 0.4, b.x1 - b.x0 - 0.8, b.z1 - b.z0 - 0.8);
    }

    // Badges in screen space, so the letters stay upright.
    _screenSpace();
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.font = 'bold 17px sans-serif';
    for (final entry in enterable.entries) {
      final b = blocks[entry.key];
      final badge = _badges[entry.value.id]!;
      final cx = _px((b.x0 + b.x1) / 2, (b.z0 + b.z1) / 2), cy = _py((b.x0 + b.x1) / 2, (b.z0 + b.z1) / 2);
      ctx.beginPath();
      ctx.arc(cx, cy, 14, 0, math.pi * 2);
      _fill(_css(badge.$1));
      ctx.fill();
      ctx.lineWidth = 3;
      _stroke('#ffffff');
      ctx.stroke();
      _fill('#ffffff');
      ctx.fillText(badge.$2, cx, cy + 1);
    }

    // The bike (unless he is on it).
    if (!riding) {
      final bx = _px(bike.x, bike.z), by = _py(bike.x, bike.z);
      _fill('#ffd54f');
      ctx.fillRect(bx - 6, by - 6, 12, 12);
      ctx.lineWidth = 2;
      _stroke('#3b2a1d');
      ctx.strokeRect(bx - 6, by - 6, 12, 12);
    }

    // The character: a dot with an arrow for the way he faces.
    final cx = _px(x, z), cy = _py(x, z);
    final dx = math.sin(heading - _a), dy = math.cos(heading - _a);
    ctx.beginPath();
    ctx.moveTo(cx + dx * 17, cy + dy * 17);
    ctx.lineTo(cx - dy * 8 + dx * 3, cy + dx * 8 + dy * 3);
    ctx.lineTo(cx + dy * 8 + dx * 3, cy - dx * 8 + dy * 3);
    ctx.closePath();
    _fill('#ff3d3d');
    ctx.fill();
    ctx.beginPath();
    ctx.arc(cx, cy, 8, 0, math.pi * 2);
    _fill('#ffffff');
    ctx.fill();
    ctx.lineWidth = 3.5;
    _stroke('#ff3d3d');
    ctx.stroke();

    ctx.restore();

    // Rim and the north marker.
    ctx.beginPath();
    ctx.arc(_size / 2, _size / 2, _size / 2 - 4, 0, math.pi * 2);
    ctx.lineWidth = 6;
    _stroke(n ? '#8896ab' : '#ffffff');
    ctx.stroke();
    final nx = _size / 2 + math.sin(_a) * (_size / 2 - 26), ny = _size / 2 - math.cos(_a) * (_size / 2 - 26);
    ctx.font = 'bold 20px sans-serif';
    ctx.lineWidth = 4;
    _stroke(n ? '#0d1626' : '#ffffff');
    ctx.strokeText('N', nx, ny);
    _fill('#d32f2f');
    ctx.fillText('N', nx, ny);
  }
}
