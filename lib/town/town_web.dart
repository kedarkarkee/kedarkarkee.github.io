import 'dart:js_interop';
import 'dart:math' as math;

import 'package:web/web.dart' as web;

import 'stickman.dart';
import 'three.dart';

/// A house/tree footprint the character cannot walk through.
typedef Obstacle = ({double x, double z, double r});

const _bound = 38.0;
const _walkSpeed = 5.5;
const _sprintSpeed = 11.0;

Future<void> startTown(String containerId) async {
  final container = await _waitFor(containerId);
  await loadThree();
  _Town(container).start();
}

Future<web.HTMLElement> _waitFor(String id) async {
  while (true) {
    final el = web.document.getElementById(id);
    if (el != null) return el as web.HTMLElement;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

class _Town {
  _Town(this.container);

  final web.HTMLElement container;
  final scene = Scene();
  final renderer = Renderer();
  final camera = Camera.perspective(50, 1, 0.1, 200);
  final picker = Picker();
  final keys = <String>{};
  final obstacles = <Obstacle>[];
  late final Object3D ground;
  late final Stickman stickman;

  double? targetX, targetZ;
  double heading = 0;
  bool sprint = false; // Shift is held
  double lastTime = 0;

  void start() {
    scene.background = color(0x9ad8ff);
    scene.fog = fog(0x9ad8ff, 40, 110);
    scene.add(hemisphereLight(0xffffff, 0x6b8f5a, 1.6));
    final sun = light('DirectionalLight', 0xfff2d0, 2.2);
    sun.position.set(20, 30, 10);
    scene.add(sun);

    _buildTown();
    stickman = Stickman();
    stickman.root.position.set(0, 0, 8);
    scene.add(stickman.root);
    scene.add(stickman.face);

    renderer.setPixelRatio(math.min(web.window.devicePixelRatio, 2));
    container.append(renderer.domElement);
    _resize();

    web.window.addEventListener('resize', ((web.Event _) => _resize()).toJS);
    web.window.addEventListener(
      'keydown',
      ((web.KeyboardEvent e) {
        sprint = e.shiftKey;
        final k = e.key.toLowerCase();
        if (_moveKeys.contains(k)) {
          keys.add(k);
          targetX = targetZ = null;
          e.preventDefault();
        }
      }).toJS,
    );
    web.window.addEventListener(
      'keyup',
      ((web.KeyboardEvent e) {
        sprint = e.shiftKey;
        keys.remove(e.key.toLowerCase());
      }).toJS,
    );
    web.window.addEventListener(
      'blur',
      ((web.Event _) {
        keys.clear();
        sprint = false;
      }).toJS,
    );
    renderer.domElement.addEventListener('pointerdown', ((web.PointerEvent e) => _click(e)).toJS);

    web.window.requestAnimationFrame(_frame.toJS);
  }

  static const _moveKeys = {'w', 'a', 's', 'd', 'arrowup', 'arrowdown', 'arrowleft', 'arrowright'};

  void _resize() {
    final w = container.clientWidth.toDouble();
    final h = container.clientHeight.toDouble();
    if (w == 0 || h == 0) return;
    renderer.setSize(w, h, false);
    camera.aspect = w / h;
    camera.updateProjectionMatrix();
  }

  void _click(web.PointerEvent e) {
    final rect = renderer.domElement.getBoundingClientRect();
    final nx = (e.clientX - rect.left) / rect.width * 2 - 1;
    final ny = -((e.clientY - rect.top) / rect.height) * 2 + 1;
    final hit = picker.pick(camera, ground, nx, ny);
    if (hit != null) {
      targetX = hit.x.clamp(-_bound, _bound);
      targetZ = hit.z.clamp(-_bound, _bound);
    }
  }

  void _frame(double ms) {
    final dt = math.min((ms - lastTime) / 1000, 0.05);
    lastTime = ms;
    _update(dt, ms / 1000);
    renderer.render(scene, camera);
    web.window.requestAnimationFrame(_frame.toJS);
  }

  void _update(double dt, double t) {
    var dx = 0.0, dz = 0.0;
    if (keys.contains('a') || keys.contains('arrowleft')) dx -= 1;
    if (keys.contains('d') || keys.contains('arrowright')) dx += 1;
    if (keys.contains('w') || keys.contains('arrowup')) dz -= 1;
    if (keys.contains('s') || keys.contains('arrowdown')) dz += 1;

    final pos = stickman.root.position;
    if (dx == 0 && dz == 0 && targetX != null) {
      final tx = targetX! - pos.x, tz = targetZ! - pos.z;
      final dist = math.sqrt(tx * tx + tz * tz);
      if (dist < 0.2) {
        targetX = targetZ = null;
      } else {
        dx = tx / dist;
        dz = tz / dist;
      }
    }

    final moving = dx != 0 || dz != 0;
    if (moving) {
      final len = math.sqrt(dx * dx + dz * dz);
      dx /= len;
      dz /= len;
      final speed = sprint ? _sprintSpeed : _walkSpeed;
      var nx = (pos.x + dx * speed * dt).clamp(-_bound, _bound);
      var nz = (pos.z + dz * speed * dt).clamp(-_bound, _bound);
      for (final o in obstacles) {
        final ox = nx - o.x, oz = nz - o.z;
        final d = math.sqrt(ox * ox + oz * oz);
        if (d < o.r && d > 0) {
          nx = o.x + ox / d * o.r;
          nz = o.z + oz / d * o.r;
        }
      }
      pos.x = nx;
      pos.z = nz;

      // Turn smoothly towards the direction of travel.
      var diff = math.atan2(dx, dz) - heading;
      while (diff > math.pi) {
        diff -= 2 * math.pi;
      }
      while (diff < -math.pi) {
        diff += 2 * math.pi;
      }
      heading += diff * math.min(1, dt * 12);
      stickman.root.rotation.y = heading;
    }
    stickman.animate(t, moving, sprint: sprint);

    // Chase camera.
    final k = math.min(1, dt * (sprint && moving ? 6 : 4));
    camera.position.x += (pos.x - camera.position.x) * k;
    camera.position.y += (8.5 - camera.position.y) * k;
    camera.position.z += (pos.z + 11 - camera.position.z) * k;
    camera.lookAt(pos.x, 1.8, pos.z);
    stickman.updateFace(camera);
  }

  // --- Town -----------------------------------------------------------

  void _buildTown() {
    ground = mesh('Plane', [120, 120], 0x7cc46b);
    ground.rotation.x = -math.pi / 2;
    scene.add(ground);

    // Crossing roads.
    for (final (w, d) in [(7.0, 120.0), (120.0, 7.0)]) {
      final road = mesh('Plane', [w, d], 0x5d5f66);
      road.rotation.x = -math.pi / 2;
      road.position.y = 0.02;
      scene.add(road);
    }

    const houseColors = [0xf6c85f, 0xe76f51, 0xf4a261, 0xa8dadc, 0xe9c46a, 0xb5838d];
    var i = 0;
    for (final x in [-24.0, -12.0, 12.0, 24.0]) {
      for (final z in [-22.0, -10.0, 12.0, 24.0]) {
        _house(x, z, houseColors[i++ % houseColors.length]);
      }
    }

    final rng = math.Random(7);
    for (var n = 0; n < 40; n++) {
      final x = rng.nextDouble() * 76 - 38, z = rng.nextDouble() * 76 - 38;
      // Keep the roads and house plots clear.
      if (x.abs() < 6 || z.abs() < 6) continue;
      if (obstacles.any((o) => (o.x - x).abs() < 6 && (o.z - z).abs() < 6)) continue;
      _tree(x, z);
    }
  }

  void _house(double x, double z, int color) {
    final g = Object3D.group();
    final walls = mesh('Box', [6, 4, 6], color);
    walls.position.y = 2;
    final roof = mesh('Cone', [5.2, 2.8, 4], 0x9c3d2e);
    roof.position.y = 5.4;
    roof.rotation.y = math.pi / 4;
    final door = mesh('Box', [1.2, 2.2, 0.1], 0x6b4226);
    door.position.set(0, 1.1, 3.05);
    g.add(walls);
    g.add(roof);
    g.add(door);
    g.position.set(x, 0, z);
    // Doors face the nearest road (z = 0 axis).
    g.rotation.y = z < 0 ? 0 : math.pi;
    scene.add(g);
    obstacles.add((x: x, z: z, r: 4.6));
  }

  void _tree(double x, double z) {
    final g = Object3D.group();
    final trunk = mesh('Cylinder', [0.35, 0.5, 2, 8], 0x7a5230);
    trunk.position.y = 1;
    final top = mesh('Cone', [1.8, 4, 8], 0x2f8f4e);
    top.position.y = 4;
    g.add(trunk);
    g.add(top);
    g.position.set(x, 0, z);
    scene.add(g);
    obstacles.add((x: x, z: z, r: 1.0));
  }
}
