import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

// The stub is used when pre-rendering on the server; the browser build gets
// the real three.js scene.
import '../town/town_stub.dart' if (dart.library.js_interop) '../town/town_web.dart';

@client
class TownScene extends StatefulComponent {
  const TownScene({super.key});

  @override
  State<TownScene> createState() => TownSceneState();
}

class TownSceneState extends State<TownScene> {
  static const _id = 'town-canvas';

  @override
  void initState() {
    super.initState();
    startTown(_id);
  }

  @override
  Component build(BuildContext context) {
    return div(classes: 'town-root', [
      div(id: _id, classes: 'town', []),
      p(classes: 'town-hint', [.text('Move with WASD / arrow keys (hold Shift to sprint), or click the ground.')]),
    ]);
  }
}
