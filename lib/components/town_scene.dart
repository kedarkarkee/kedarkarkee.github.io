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
      // Shown on keyboard devices.
      p(classes: 'town-hint hint-desktop', [
        .text('WASD / arrows to move, Shift to sprint, Space to jump, F to fly, R to ride the bike, E to enter a house, P to honk.'),
      ]),
      // Shown on touch screens.
      p(classes: 'town-hint hint-touch', [.text('Drag the pad to move. Push it to the edge to run.')]),
    ]);
  }
}
