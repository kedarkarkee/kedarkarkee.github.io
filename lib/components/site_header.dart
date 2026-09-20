import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../data/portfolio.dart';

class SiteHeader extends StatelessComponent {
  const SiteHeader({super.key});

  @override
  Component build(BuildContext context) {
    return header(classes: 'site-header', [
      a(classes: 'skip', href: '#work', [.text('Skip to projects')]),
      div(classes: 'bar', [
        a(classes: 'brand', href: '#top', [.text(profile.name)]),
        nav(
          classes: 'nav-links',
          attributes: {'aria-label': 'Main'},
          [
            a(href: '#work', [.text('Work')]),
            a(href: '#about', [.text('About')]),
            a(href: '#contact', [.text('Contact')]),
          ],
        ),
      ]),
    ]);
  }
}
