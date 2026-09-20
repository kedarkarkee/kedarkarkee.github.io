import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../components/about.dart';
import '../components/contact.dart';
import '../components/hero.dart';
import '../components/site_header.dart';
import '../components/work_section.dart';

// The page itself is pre-rendered on the server. Only WorkSection (which has
// the project filter) is a @client component and gets compiled to JavaScript.
class Home extends StatelessComponent {
  const Home({super.key});

  @override
  Component build(BuildContext context) {
    return div(classes: 'page', [
      const SiteHeader(),
      const Hero(),
      const WorkSection(),
      const About(),
      const Contact(),
    ]);
  }
}
