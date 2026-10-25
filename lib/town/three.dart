// Minimal js_interop bindings for the parts of three.js used by the town.
// three.js is loaded lazily from a CDN as an ES module via `importModule`.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

const _threeUrl = 'https://cdn.jsdelivr.net/npm/three@0.170.0/build/three.module.js';

late final JSObject _three;

Future<void> loadThree() async {
  _three = await importModule(_threeUrl.toJS).toDart;
}

JSObject _new(String cls, [List<Object?> args = const []]) {
  final ctor = _three.getProperty<JSFunction>(cls.toJS);
  return ctor.callAsConstructorVarArgs([for (final a in args) a.jsify()]);
}

extension type Vec3._(JSObject _) implements JSObject {
  external double x, y, z;
  external Vec3 set(num x, num y, num z);
  external Vec3 copy(Vec3 v);
  external Vec3 lerp(Vec3 v, num t);
}

extension type Quat._(JSObject _) implements JSObject {
  external Quat copy(Quat q);
}

extension type Euler._(JSObject _) implements JSObject {
  external double x, y, z;
}

extension type Object3D._(JSObject _) implements JSObject {
  factory Object3D.group() => Object3D._(_new('Group'));

  external Vec3 position;
  external Vec3 scale;
  external Euler rotation;
  external Quat quaternion;
  external void add(Object3D child);
}

extension type Camera._(JSObject _) implements Object3D {
  factory Camera.perspective(num fov, num aspect, num near, num far) =>
      Camera._(_new('PerspectiveCamera', [fov, aspect, near, far]));

  external double aspect;
  external void lookAt(num x, num y, num z);
  external void updateProjectionMatrix();
}

extension type Scene._(JSObject _) implements Object3D {
  factory Scene() => Scene._(_new('Scene'));
  external JSAny? background;
  external JSAny? fog;
}

extension type Renderer._(JSObject _) implements JSObject {
  factory Renderer() => Renderer._(
    _new('WebGLRenderer', [
      {'antialias': true},
    ]),
  );

  external web.HTMLCanvasElement get domElement;
  external void setPixelRatio(num ratio);
  external void setSize(num w, num h, [bool updateStyle]);
  external void render(Scene scene, Camera camera);
  external void dispose();
}

/// Builds a mesh from a `<geometry>Geometry` class name. [basic] gives an
/// unlit, flat-coloured material (used for the stickman).
Object3D mesh(String geometry, List<num> args, int color, {bool flat = false, bool basic = false}) {
  final m = _new('Mesh');
  m.setProperty('geometry'.toJS, _new('${geometry}Geometry', args));
  m.setProperty(
    'material'.toJS,
    basic
        ? _new('MeshBasicMaterial', [
            {'color': color},
          ])
        : _new('MeshLambertMaterial', [
            {'color': color, 'flatShading': flat},
          ]),
  );
  return Object3D._(m);
}

Object3D light(String type, int color, num intensity) => Object3D._(_new(type, [color, intensity]));

Object3D hemisphereLight(int sky, int ground, num intensity) =>
    Object3D._(_new('HemisphereLight', [sky, ground, intensity]));

JSAny color(int hex) => _new('Color', [hex]);

JSAny fog(int hex, num near, num far) => _new('Fog', [hex, near, far]);

/// Raycasting against a single object, used for click-to-walk.
class Picker {
  Picker() : _raycaster = _new('Raycaster'), _ndc = _new('Vector2');

  final JSObject _raycaster;
  final JSObject _ndc;

  /// Returns the (x, z) ground point under the NDC coordinate, or null.
  ({double x, double z})? pick(Camera camera, Object3D target, double nx, double ny) {
    _ndc.setProperty('x'.toJS, nx.toJS);
    _ndc.setProperty('y'.toJS, ny.toJS);
    _raycaster.callMethodVarArgs('setFromCamera'.toJS, [_ndc, camera]);
    final hits = _raycaster.callMethodVarArgs<JSArray<JSObject>>('intersectObject'.toJS, [target]);
    if (hits.length == 0) return null;
    final p = Vec3._(hits[0].getProperty<JSObject>('point'.toJS));
    return (x: p.x, z: p.z);
  }
}
