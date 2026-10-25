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
  external Vec3 project(Camera camera);
}

Vec3 vec3(num x, num y, num z) => Vec3._(_new('Vector3', [x, y, z]));

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
  external bool visible;
  external void add(Object3D child);
  external void lookAt(num x, num y, num z);
}

extension type Camera._(JSObject _) implements Object3D {
  factory Camera.perspective(num fov, num aspect, num near, num far) =>
      Camera._(_new('PerspectiveCamera', [fov, aspect, near, far]));

  external double aspect;
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
Object3D mesh(String geometry, List<num> args, int color, {bool flat = false, bool basic = false, bool fog = true}) {
  final m = _new('Mesh');
  m.setProperty('geometry'.toJS, _new('${geometry}Geometry', args));
  m.setProperty(
    'material'.toJS,
    basic
        ? _new('MeshBasicMaterial', [
            {'color': color, 'fog': fog},
          ])
        : _new('MeshLambertMaterial', [
            {'color': color, 'flatShading': flat},
          ]),
  );
  return Object3D._(m);
}

/// A flat sign showing [text], drawn onto a canvas texture. Faces +z.
Object3D signboard(String text, double w, double h, {String bg = '#6b4a2b', String fg = '#fff3d6'}) {
  const px = 128; // canvas pixels per world unit
  final canvas = web.document.createElement('canvas') as web.HTMLCanvasElement
    ..width = (w * px).round()
    ..height = (h * px).round();
  final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;
  ctx.fillStyle = bg.toJS;
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  ctx.strokeStyle = fg.toJS;
  ctx.lineWidth = 6;
  ctx.strokeRect(10, 10, canvas.width - 20, canvas.height - 20);

  // Shrink the text until it fits inside the frame.
  var size = canvas.height * 0.5;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillStyle = fg.toJS;
  do {
    ctx.font = 'bold ${size.round()}px sans-serif';
    size -= 2;
  } while (ctx.measureText(text).width > canvas.width * 0.86 && size > 10);
  ctx.fillText(text, canvas.width / 2, canvas.height / 2 + 4);

  final texture = _new('CanvasTexture', [canvas]);
  texture.setProperty('colorSpace'.toJS, 'srgb'.toJS);
  final m = _new('Mesh');
  m.setProperty('geometry'.toJS, _new('PlaneGeometry', [w, h]));
  m.setProperty(
    'material'.toJS,
    _new('MeshBasicMaterial', [
      {'map': texture},
    ]),
  );
  return Object3D._(m);
}

/// A flat, unlit, optionally see-through disc that ignores fog. Used for the
/// sun, moon, stars and their glow; [Object3D.lookAt] turns it to face a point.
Object3D softDisc(double radius, int color, {double opacity = 1}) {
  final m = _new('Mesh');
  m.setProperty('geometry'.toJS, _new('CircleGeometry', [radius, 32]));
  m.setProperty(
    'material'.toJS,
    _new('MeshBasicMaterial', [
      {'color': color, 'fog': false, 'transparent': opacity < 1, 'opacity': opacity, 'depthWrite': false},
    ]),
  );
  return Object3D._(m);
}

/// A soft dark disc used as a ground shadow so jumps and flight read as height.
Object3D blobShadow(double radius) {
  final m = _new('Mesh');
  m.setProperty('geometry'.toJS, _new('CircleGeometry', [radius, 24]));
  m.setProperty(
    'material'.toJS,
    _new('MeshBasicMaterial', [
      {'color': 0x000000, 'transparent': true, 'opacity': 0.3, 'depthWrite': false},
    ]),
  );
  final o = Object3D._(m);
  o.rotation.x = -3.141592653589793 / 2;
  return o;
}

extension type Light._(JSObject _) implements Object3D {
  external double intensity;
}

Light light(String type, int color, num intensity) => Light._(_new(type, [color, intensity]));

Light hemisphereLight(int sky, int ground, num intensity) => Light._(_new('HemisphereLight', [sky, ground, intensity]));

/// Changes a light's colour (and a hemisphere light's ground colour if given).
void setLight(Light l, {int? color, int? ground, num? intensity}) {
  if (color != null) l.getProperty<JSObject>('color'.toJS).callMethod<JSAny?>('setHex'.toJS, color.toJS);
  if (ground != null) l.getProperty<JSObject>('groundColor'.toJS).callMethod<JSAny?>('setHex'.toJS, ground.toJS);
  if (intensity != null) l.intensity = intensity.toDouble();
}

/// Recolours a mesh's material in place (used for the day/night switch).
void setMeshColor(Object3D o, int hex) {
  o.getProperty<JSObject>('material'.toJS).getProperty<JSObject>('color'.toJS).callMethod<JSAny?>('setHex'.toJS, hex.toJS);
}

JSAny color(int hex) => _new('Color', [hex]);

JSAny fog(int hex, num near, num far) => _new('Fog', [hex, near, far]);

/// Raycasting against an object and its children, used for click-to-walk.
class Picker {
  Picker() : _raycaster = _new('Raycaster'), _ndc = _new('Vector2');

  final JSObject _raycaster;
  final JSObject _ndc;

  /// Distance from [origin] along the unit vector [dir] to the first thing hit
  /// on [target] within [maxDistance], or null. Used to keep the camera out of houses.
  double? castDistance(Vec3 origin, Vec3 dir, Object3D target, double maxDistance) {
    _raycaster.callMethodVarArgs('set'.toJS, [origin, dir]);
    _raycaster.setProperty('far'.toJS, maxDistance.toJS);
    final hits = _raycaster.callMethodVarArgs<JSArray<JSObject>>('intersectObject'.toJS, [target, true.toJS]);
    if (hits.length == 0) return null;
    return hits[0].getProperty<JSNumber>('distance'.toJS).toDartDouble;
  }

  /// Returns the (x, z) ground point under the NDC coordinate, or null.
  ({double x, double z})? pick(Camera camera, Object3D target, double nx, double ny) {
    _ndc.setProperty('x'.toJS, nx.toJS);
    _ndc.setProperty('y'.toJS, ny.toJS);
    _raycaster.callMethodVarArgs('setFromCamera'.toJS, [_ndc, camera]);
    final hits = _raycaster.callMethodVarArgs<JSArray<JSObject>>('intersectObject'.toJS, [target, true.toJS]);
    if (hits.length == 0) return null;
    final p = Vec3._(hits[0].getProperty<JSObject>('point'.toJS));
    return (x: p.x, z: p.z);
  }
}
