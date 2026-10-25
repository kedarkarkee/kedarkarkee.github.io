import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../data/portfolio.dart';

/// The full-screen panel that opens when the character walks into a house.
/// Its content comes from lib/data/portfolio.dart.
class Overlay {
  Overlay(this.container) {
    _build();
  }

  final web.HTMLElement container;
  late final web.HTMLElement _root, _title, _body, _sheet;

  bool get isOpen => !_root.classList.contains('hidden');

  /// Called after the overlay closes.
  void Function()? onClose;

  web.HTMLElement _el(String tag, String className, [String? text]) {
    final el = web.document.createElement(tag) as web.HTMLElement..className = className;
    if (text != null) el.textContent = text;
    return el;
  }

  web.HTMLElement _link(String label, String url, {String className = 'ov-button'}) {
    final a = web.document.createElement('a') as web.HTMLAnchorElement
      ..className = className
      ..href = url
      ..target = '_blank'
      ..rel = 'noopener noreferrer'
      ..textContent = label;
    return a;
  }

  void _build() {
    _root = _el('div', 'overlay hidden');
    _sheet = _el('div', 'ov-sheet');
    _sheet.setAttribute('role', 'dialog');
    _sheet.setAttribute('aria-modal', 'true');

    // A strip of prayer-flag colours along the top of the sheet.
    final flags = _el('div', 'ov-flags');
    for (final c in ['blue', 'white', 'red', 'green', 'yellow']) {
      flags.append(_el('span', 'ov-flag ov-$c'));
    }

    final header = _el('div', 'ov-header');
    _title = _el('h2', 'ov-title');
    final closeButton = _el('button', 'ov-close', '×');
    closeButton.setAttribute('aria-label', 'Close');
    closeButton.addEventListener('click', ((web.Event _) => close()).toJS);
    header.append(_title);
    header.append(closeButton);

    _body = _el('div', 'ov-body');
    final hint = _el('div', 'ov-hint');
    hint.append(_el('span', 'ov-hint-keys', 'Press E or Esc to walk back out'));
    hint.append(_el('span', 'ov-hint-touch', 'Tap \u00d7 to walk back out'));

    _sheet.append(flags);
    _sheet.append(header);
    _sheet.append(_body);
    _sheet.append(hint);
    _root.append(_sheet);
    // Clicking the dimmed backdrop closes it too.
    _root.addEventListener(
      'click',
      ((web.MouseEvent e) {
        if (e.target == _root) close();
      }).toJS,
    );
    container.append(_root);
  }

  void close() {
    if (!isOpen) return;
    _root.classList.add('hidden');
    web.document.body?.classList.remove('overlay-open');
    onClose?.call();
  }

  void open(String id) {
    _body.textContent = '';
    switch (id) {
      case 'about':
        _title.textContent = 'About me';
        _about();
      case 'projects':
        _title.textContent = 'Projects';
        _projects();
      case 'experience':
        _title.textContent = 'Experience';
        _timeline([for (final j in experience) (years: j.years, title: j.role, place: j.place, url: j.url, note: j.note)]);
      case 'education':
        _title.textContent = 'Education';
        _timeline([for (final e in education) (years: e.years, title: e.degree, place: e.school, url: null, note: e.note)]);
      case 'skills':
        _title.textContent = 'Skills';
        _skills();
      case 'contact':
        _title.textContent = 'Contact me';
        _contact();
    }
    _body.scrollTop = 0;
    _root.classList.remove('hidden');
    // Lets the stylesheet hide the controls hint behind the panel.
    web.document.body?.classList.add('overlay-open');
  }

  // --- content ------------------------------------------------------------------

  void _about() {
    _body.append(_el('p', 'ov-lead', profile.intro));
    for (final p in profile.about) {
      _body.append(_el('p', 'ov-text', p));
    }
    final facts = _el('dl', 'ov-facts');
    for (final f in profile.facts) {
      final row = _el('div', 'ov-fact');
      row.append(_el('dt', 'ov-fact-label', f.label));
      row.append(_el('dd', 'ov-fact-value', f.value));
      facts.append(row);
    }
    _body.append(facts);
  }

  void _projects() {
    final grid = _el('div', 'ov-grid');
    for (final p in projects) {
      final card = _el('div', 'ov-card ov-tone-${p.tone}');
      final top = _el('div', 'ov-card-top');
      top.append(_el('span', 'ov-badge', p.category));
      if (p.year != null) top.append(_el('span', 'ov-year', '${p.year}'));
      card.append(top);
      card.append(_el('h3', 'ov-card-title', p.title));
      card.append(_el('p', 'ov-card-text', p.summary));
      final tags = _el('div', 'ov-chips');
      for (final t in p.tags.split(',')) {
        tags.append(_el('span', 'ov-chip', t.trim()));
      }
      card.append(tags);
      final links = _el('div', 'ov-card-links');
      for (final l in p.links) {
        links.append(_link('${l.label} →', l.url, className: 'ov-card-link'));
      }
      card.append(links);
      grid.append(card);
    }
    _body.append(grid);
  }

  void _timeline(List<({String years, String title, String place, String? url, String note})> items) {
    final list = _el('div', 'ov-timeline');
    for (final item in items) {
      final row = _el('div', 'ov-item');
      row.append(_el('div', 'ov-item-years', item.years));
      row.append(_el('h3', 'ov-item-title', item.title));
      // The place links to the company's site when we have one.
      row.append(item.url == null
          ? _el('div', 'ov-item-place', item.place)
          : _link('${item.place} \u2197', item.url!, className: 'ov-item-place ov-item-link'));
      if (item.note.isNotEmpty) row.append(_el('p', 'ov-text', item.note));
      list.append(row);
    }
    _body.append(list);
  }

  void _skills() {
    for (final s in skills) {
      final group = _el('div', 'ov-skill');
      group.append(_el('h3', 'ov-skill-title', s.area));
      final chips = _el('div', 'ov-chips');
      for (final i in s.items.split(',')) {
        chips.append(_el('span', 'ov-chip ov-chip-big', i.trim()));
      }
      group.append(chips);
      _body.append(group);
    }
  }

  void _contact() {
    _body.append(_el('p', 'ov-lead', profile.contactNote));
    final actions = _el('div', 'ov-actions');
    actions.append(_link(profile.email, 'mailto:${profile.email}', className: 'ov-button ov-button-primary'));
    for (final l in socialLinks) {
      actions.append(_link(l.label, l.url));
    }
    _body.append(actions);
  }
}
