import 'dart:js_interop';
import 'dart:math' as math;

import 'package:web/web.dart' as web;

import 'bicycle.dart';
import 'overlay.dart';
import 'stickman.dart';
import 'terrain.dart';
import 'three.dart';
import 'village.dart';

const _walkSpeed = 3.8;
const _sprintSpeed = 7.5;
const _rideSpeed = 7.0;
const _rideSprintSpeed = 11.0;

/// How close he must be to the parked bicycle to get on.
const _mountDistance = 3.5;

// Jumping and flying. Heights are in world units above the ground.
const _gravity = 24.0;
const _jumpSpeed = 9.0;
const _cruiseHeight = 10.5;
const _flySpeed = 13.0;
const _flySprintSpeed = 24.0;

/// How close he must be to a house's glowing ring to go in.
const _enterDistance = 2.4;

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
  final camera = Camera.perspective(50, 1, 0.1, 600);
  final picker = Picker();
  final keys = <String>{};
  late final Village village;
  late final Overlay overlay;
  late final Stickman stickman;
  final bike = Bicycle();
  late final web.HTMLElement prompt;
  final _anchor = vec3(0, 0, 0);
  bool riding = false;

  // Vertical state: height above the ground, vertical speed, and flight.
  double altitude = 0, vy = 0;
  bool flying = false;
  late final Object3D shadow;
  late final web.HTMLElement enterPrompt;

  // Touch controls.
  late final web.HTMLElement _joyKnob, _joyPad, _rideButton, _enterButton, _honkButton, _flyButton, honkLabel;
  int? _joyPointer;
  double _joyX = 0, _joyY = 0; // -1..1, screen space (up is negative y)
  double _honkUntil = 0;
  late final web.HTMLAudioElement _honkSound;

  double? targetX, targetZ;
  double heading = 0;
  bool sprint = false; // Shift is held
  double lastTime = 0;

  void start() {
    // Hazy mountain-air blue, with distant hills fading into it.
    scene.background = color(0xb7d9f0);
    scene.fog = fog(0xb7d9f0, 90, 320);
    scene.add(hemisphereLight(0xffffff, 0x7d9a5f, 1.7));
    final sun = light('DirectionalLight', 0xfff0d0, 2.3);
    sun.position.set(-30, 50, 40);
    scene.add(sun);

    village = Village();
    scene.add(village.root);
    overlay = Overlay(container)..onClose = () => keys.clear();

    stickman = Stickman();
    stickman.root.position.set(0, 0, 14);
    scene.add(stickman.root);
    scene.add(stickman.face);

    // Parked on the path by the village entrance, lying along the x axis.
    bike.root.position.set(6, 0, 14);
    bike.root.rotation.y = math.pi / 2;
    bike.root.scale.set(Stickman.scale, Stickman.scale, Stickman.scale);
    scene.add(bike.root);

    shadow = blobShadow(0.9);
    shadow.visible = false;
    scene.add(shadow);

    _honkSound = web.HTMLAudioElement()
      ..src = 'audio/honk.mp3'
      ..preload = 'auto';

    enterPrompt = web.document.createElement('div') as web.HTMLElement..className = 'prompt prompt-hidden';
    container.append(enterPrompt);
    prompt = web.document.createElement('div') as web.HTMLElement..className = 'prompt prompt-hidden';
    container.append(prompt);
    honkLabel = web.document.createElement('div') as web.HTMLElement..className = 'prompt prompt-hidden honk';
    honkLabel.textContent = 'Honk!';
    container.append(honkLabel);
    _buildControls();

    renderer.setPixelRatio(math.min(web.window.devicePixelRatio, 2));
    container.append(renderer.domElement);
    _resize();

    web.window.addEventListener('resize', ((web.Event _) => _resize()).toJS);
    web.window.addEventListener(
      'keydown',
      ((web.KeyboardEvent e) {
        sprint = e.shiftKey;
        final k = e.key.toLowerCase();
        if (overlay.isOpen) {
          if ((k == 'e' || k == 'escape') && !e.repeat) overlay.close();
          return;
        }
        if (!e.repeat) {
          switch (k) {
            case 'e':
              _enterHouse();
            case 'r':
              _toggleBike();
            case 'f':
              _toggleFly();
            case 'p':
              _honk();
            case ' ':
              _jump();
          }
        }
        if (k == ' ') e.preventDefault(); // don't scroll the page
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

  double get _distanceToBike {
    final dx = stickman.root.position.x - bike.root.position.x;
    final dz = stickman.root.position.z - bike.root.position.z;
    return math.sqrt(dx * dx + dz * dz);
  }

  bool get _onGround => !flying && altitude < 0.5;

  /// The house door he is standing at, if any. Works on foot or on the bike.
  Entrance? get _nearEntrance {
    if (!_onGround) return null;
    final p = stickman.root.position;
    for (final e in village.entrances) {
      final dx = p.x - e.x, dz = p.z - e.z;
      if (dx * dx + dz * dz < _enterDistance * _enterDistance) return e;
    }
    return null;
  }

  /// What R would do right now: 'Ride', 'Get off', or null.
  String? get _bikeAction {
    if (flying) return null;
    if (riding) return 'Get off';
    if (_onGround && _distanceToBike < _mountDistance) return 'Ride';
    return null;
  }

  /// R: get on or off the bicycle.
  void _toggleBike() {
    if (overlay.isOpen) return;
    switch (_bikeAction) {
      case 'Get off':
        _dismount();
      case 'Ride':
        _mount();
    }
  }

  /// E: go into the house at the door (also while riding).
  void _enterHouse() {
    final e = _nearEntrance;
    if (e != null && !overlay.isOpen) _enter(e);
  }

  /// Space: jump, on foot or on the bike.
  void _jump() {
    if (overlay.isOpen || flying || altitude > 0.05) return;
    vy = _jumpSpeed;
  }

  /// F: take off in the Superman pose, or come back down to walk.
  void _toggleFly() {
    if (overlay.isOpen) return;
    if (riding) riding = false; // leaves the bike parked where it is
    flying = !flying;
    targetX = targetZ = null;
    vy = 0;
  }

  void _mount() {
    riding = true;
    final p = bike.root.position;
    stickman.root.position.set(p.x, p.y, p.z);
    heading = bike.root.rotation.y;
    stickman.root.rotation.y = heading;
    targetX = targetZ = null;
  }

  void _dismount() {
    riding = false;
    targetX = targetZ = null;
    // Step off to either side of the bike, whichever is open.
    final h = bike.root.rotation.y;
    final p = stickman.root.position;
    for (final side in [2.2, -2.2]) {
      final x = p.x + math.cos(h) * side, z = p.z - math.sin(h) * side;
      if (!isBlocked(x, z)) {
        p.x = x;
        p.z = z;
        return;
      }
    }
  }

  void _enter(Entrance e) {
    keys.clear();
    _joyX = _joyY = 0;
    _joyKnob.style.transform = 'translate(-50%, -50%)';
    targetX = targetZ = null;
    overlay.open(e.id);
  }

  /// After landing from a flight, step out of any house, wall or tree below.
  void _unstick() {
    final p = stickman.root.position;
    if (!isBlocked(p.x, p.z)) return;
    for (var r = 0.5; r <= 14; r += 0.5) {
      for (var i = 0; i < 16; i++) {
        final a = i * math.pi / 8;
        final x = p.x + math.sin(a) * r, z = p.z + math.cos(a) * r;
        if (!isBlocked(x, z)) {
          p.x = x;
          p.z = z;
          return;
        }
      }
    }
  }

  /// Shows a key prompt above whatever R and E would act on right now.
  void _updatePrompt() {
    final honking = riding && lastTime / 1000 < _honkUntil;
    honkLabel.classList.toggle('prompt-hidden', !honking);
    final p = stickman.root.position;
    if (honking) _place(honkLabel, p, p.y + 4.0);

    final bike = _bikeAction;
    prompt.classList.toggle('prompt-hidden', bike == null || overlay.isOpen);
    if (bike != null) {
      prompt.textContent = bike == 'Ride' ? 'Press R to ride' : 'Press R to get off';
      final bp = this.bike.root.position;
      if (bike == 'Ride') {
        _place(prompt, bp, bp.y + 2.4);
      } else {
        _place(prompt, p, p.y + 3.3);
      }
    }

    // The entrance prompt sits higher so the two never overlap.
    final entrance = _nearEntrance;
    enterPrompt.classList.toggle('prompt-hidden', entrance == null || overlay.isOpen);
    if (entrance != null) {
      enterPrompt.textContent = 'Press E to enter ${entrance.label}';
      _place(enterPrompt, p, p.y + 5.2);
    }
  }

  /// Positions [el] on screen above the world point [p] at height [y].
  void _place(web.HTMLElement el, Vec3 p, double y) {
    _anchor.set(p.x, y, p.z);
    _anchor.project(camera);
    final w = container.clientWidth, h = container.clientHeight;
    // Keep the label fully on screen when the anchor is near an edge.
    final half = el.offsetWidth / 2 + 8;
    final x = ((_anchor.x * 0.5 + 0.5) * w).clamp(half, math.max(half, w - half));
    el.style.left = '${x}px';
    el.style.top = '${(-_anchor.y * 0.5 + 0.5) * h}px';
  }

  // --- Touch controls -------------------------------------------------

  web.HTMLElement _el(String className, [String? text]) {
    final el = web.document.createElement('div') as web.HTMLElement..className = className;
    if (text != null) el.textContent = text;
    return el;
  }

  /// A virtual pad (bottom left) plus context buttons (bottom right). The
  /// stylesheet only shows them on touch screens.
  void _buildControls() {
    _joyPad = _el('joy');
    _joyKnob = _el('joy-knob');
    _joyPad.append(_joyKnob);
    container.append(_joyPad);

    _joyPad.addEventListener(
      'pointerdown',
      ((web.PointerEvent e) {
        e.preventDefault();
        _joyPointer = e.pointerId;
        _joyPad.setPointerCapture(e.pointerId);
        targetX = targetZ = null;
        _moveJoy(e);
      }).toJS,
    );
    _joyPad.addEventListener(
      'pointermove',
      ((web.PointerEvent e) {
        if (e.pointerId == _joyPointer) _moveJoy(e);
      }).toJS,
    );
    for (final type in ['pointerup', 'pointercancel']) {
      _joyPad.addEventListener(
        type,
        ((web.PointerEvent e) {
          if (e.pointerId != _joyPointer) return;
          _joyPointer = null;
          _joyX = _joyY = 0;
          _joyKnob.style.transform = 'translate(-50%, -50%)';
        }).toJS,
      );
    }

    _rideButton = _tapButton('ride-button hidden', 'Ride', _toggleBike);
    _enterButton = _tapButton('enter-button hidden', 'Enter', _enterHouse);
    _honkButton = _tapButton('honk-button hidden', 'Honk', _honk);
    _tapButton('jump-button', 'Jump', _jump);
    _flyButton = _tapButton('fly-button', 'Fly', _toggleFly);
  }

  web.HTMLElement _tapButton(String className, String label, void Function() onTap) {
    final b = _el('touch-button $className', label);
    b.addEventListener(
      'pointerdown',
      ((web.PointerEvent e) {
        e.preventDefault();
        onTap();
      }).toJS,
    );
    container.append(b);
    return b;
  }

  void _moveJoy(web.PointerEvent e) {
    final r = _joyPad.getBoundingClientRect();
    final radius = r.width / 2;
    var vx = (e.clientX - (r.left + radius)) / radius;
    var vy = (e.clientY - (r.top + radius)) / radius;
    final len = math.sqrt(vx * vx + vy * vy);
    if (len > 1) {
      vx /= len;
      vy /= len;
    }
    _joyX = vx;
    _joyY = vy;
    final travel = radius * 0.55;
    _joyKnob.style.transform = 'translate(-50%, -50%) translate(${vx * travel}px, ${vy * travel}px)';
  }

  void _updateButtons() {
    final bike = overlay.isOpen ? null : _bikeAction;
    _rideButton.classList.toggle('hidden', bike == null);
    if (bike != null) _rideButton.textContent = bike;
    final canEnter = !overlay.isOpen && _nearEntrance != null;
    _enterButton.classList.toggle('hidden', !canEnter);
    _honkButton.classList.toggle('hidden', !riding);
    _flyButton.textContent = flying ? 'Land' : 'Fly';
  }

  // --- Horn -------------------------------------------------------------

  /// P (or the Honk button): plays the horn while riding.
  void _honk() {
    if (!riding || overlay.isOpen) return;
    _honkSound.currentTime = 0;
    // Browsers may refuse until the page has had a user gesture; ignore that.
    _honkSound.play().toDart.catchError((Object _) => null);
    _honkUntil = lastTime / 1000 + 0.7;
  }

  void _click(web.PointerEvent e) {
    final rect = renderer.domElement.getBoundingClientRect();
    final nx = (e.clientX - rect.left) / rect.width * 2 - 1;
    final ny = -((e.clientY - rect.top) / rect.height) * 2 + 1;
    if (overlay.isOpen) return;
    final hit = picker.pick(camera, village.walkable, nx, ny);
    if (hit != null) {
      targetX = hit.x;
      targetZ = hit.z;
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

    // The virtual pad is analog in direction; pushing it to the edge sprints.
    final joyLen = math.sqrt(_joyX * _joyX + _joyY * _joyY);
    final joyActive = dx == 0 && dz == 0 && joyLen > 0.15 && !overlay.isOpen;
    if (joyActive) {
      dx = _joyX;
      dz = _joyY;
    }
    final sprinting = sprint || (joyActive && joyLen > 0.85);

    if (overlay.isOpen) {
      dx = dz = 0;
      targetX = targetZ = null;
    }

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
      final speed = flying
          ? (sprinting ? _flySprintSpeed : _flySpeed)
          : riding
              ? (sprinting ? _rideSprintSpeed : _rideSpeed)
              : (sprinting ? _sprintSpeed : _walkSpeed);
      // On the ground he slides along walls, houses and trees (the stairs are
      // the way up); in the air he flies over everything inside the village limits.
      final next = flying
          ? (
              x: inWorld(pos.x + dx * speed * dt, pos.z) ? pos.x + dx * speed * dt : pos.x,
              z: inWorld(pos.x, pos.z + dz * speed * dt) ? pos.z + dz * speed * dt : pos.z,
            )
          : moveWithin(pos.x, pos.z, dx * speed * dt, dz * speed * dt);
      final moved = math.sqrt((next.x - pos.x) * (next.x - pos.x) + (next.z - pos.z) * (next.z - pos.z));
      pos.x = next.x;
      pos.z = next.z;
      if (riding) bike.roll(moved / Stickman.scale);
      // Gave up on a click target we can't reach (a wall in the way).
      if (moved < speed * dt * 0.1) targetX = targetZ = null;

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

    // Vertical motion: jump arc, or a smooth climb to cruising height in flight.
    final ground = heightAt(pos.x, pos.z);
    final wasAirborne = altitude > 0;
    if (flying) {
      altitude += (_cruiseHeight - altitude) * math.min(1, dt * 2.5);
    } else {
      vy = math.max(vy - _gravity * dt, -12.0);
      altitude += vy * dt;
      if (altitude <= 0) {
        altitude = 0;
        vy = 0;
        if (wasAirborne) _unstick(); // came down on a house or wall
      }
    }
    pos.y = ground + altitude;
    if (riding) {
      bike.root.position.set(pos.x, pos.y, pos.z);
      bike.root.rotation.y = heading;
    }

    // A shadow on the ground shows how high he is.
    shadow.visible = altitude > 0.05;
    final shadowSize = math.max(0.35, 1 - altitude * 0.06) * (riding ? 1.7 : 1.0);
    shadow.scale.set(shadowSize, shadowSize, shadowSize);
    shadow.position.set(pos.x, ground + 0.14, pos.z);

    stickman.animate(
      t,
      moving,
      sprint: sprinting,
      riding: riding,
      crank: bike.crank,
      airborne: altitude > 0.05 && !flying,
      flying: flying,
    );

    // Chase camera.
    final k = math.min(1, dt * (sprinting && moving ? 6 : 4));
    camera.position.x += (pos.x - camera.position.x) * k;
    // Pull the camera back on tall (portrait) screens so the scene still fits.
    final zoom = camera.aspect < 1 ? 1 + (1 - camera.aspect) * 0.9 : 1.0;
    // In flight the camera only follows part of the way up, so the ground stays in view.
    final focus = pos.y - altitude * 0.5;
    camera.position.y += (focus + 8.5 * zoom - camera.position.y) * k;
    camera.position.z += (pos.z + 11 * zoom - camera.position.z) * k;
    camera.lookAt(pos.x, focus + 1.8, pos.z);
    stickman.updateFace(camera);
    _updatePrompt();
    _updateButtons();
  }
}
