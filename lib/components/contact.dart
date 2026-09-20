import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../data/portfolio.dart';

class Contact extends StatelessComponent {
  const Contact({super.key});

  @override
  Component build(BuildContext context) {
    return section(id: 'contact', classes: 'contact', [
      div(classes: 'wrap', [
        h2(classes: 'contact-title', [.text('Have something in mind?')]),
        p(classes: 'contact-lead', [.text(profile.contactNote)]),
        a(
          classes: 'contact-mail',
          href: 'mailto:${profile.email}',
          [.text(profile.email)],
        ),
        ul(classes: 'contact-links', [
          for (final link in socialLinks)
            li([
              a(
                href: link.url,
                attributes: {'target': '_blank', 'rel': 'noopener noreferrer'},
                [.text(link.label)],
              ),
            ]),
        ]),
        p(classes: 'contact-foot', [
          .text('© ${DateTime.now().year} ${profile.name}. Built with Jaspr.'),
        ]),
      ]),
    ]);
  }
}
