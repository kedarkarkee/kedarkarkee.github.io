// All the text on the site lives here. Replace the placeholder content with
// your own and the components pick it up automatically.

class Fact {
  const Fact(this.label, this.value);
  final String label;
  final String value;
}

class Profile {
  const Profile({
    required this.name,
    required this.email,
    required this.headline,
    required this.intro,
    required this.facts,
    required this.about,
    required this.contactNote,
  });

  final String name;
  final String email;

  /// One entry per line of the big hero headline.
  final List<String> headline;
  final String intro;
  final List<Fact> facts;
  final List<String> about;
  final String contactNote;
}

class SocialLink {
  const SocialLink(this.label, this.url);
  final String label;
  final String url;
}

class Job {
  const Job({
    required this.years,
    required this.role,
    required this.place,
    required this.note,
  });

  final String years;
  final String role;
  final String place;
  final String note;
}

class Skill {
  const Skill(this.area, this.items);
  final String area;
  final String items;
}

class Project {
  const Project({
    required this.title,
    required this.summary,
    required this.category,
    required this.year,
    required this.tags,
    required this.tone,
    required this.url,
  });

  final String title;
  final String summary;
  final String category;
  final int year;
  final String tags;

  /// 1-4, picks the swatch colour (see .tone-* in styles.css).
  final int tone;
  final String url;
}

// TODO: replace everything below with your own details.

const profile = Profile(
  name: 'Kedar Karki',
  email: 'hello@alexmorgan.dev',
  headline: [
    "Hi, I'm Kedar.",
    'I build web apps',
    'that load fast and',
    'stay easy to change.',
  ],
  intro:
      'I\'m a full-stack developer who writes Dart on the server and in the '
      'browser. I like small teams, clear code and products people use daily.',
  facts: [
    Fact('Working with', 'Dart, Jaspr, Flutter'),
    Fact('Based', 'Remote, any timezone'),
    Fact('Availability', 'Open to freelance work'),
  ],
  about: [
    'I started out writing JavaScript, moved to Flutter for mobile apps, and '
        'now spend most of my time building websites in Dart so the front end '
        'and back end can share code.',
    'I care about pages that load quickly on slow connections, interfaces '
        'that can be used with a keyboard, and codebases a new teammate can '
        'understand in a day.',
  ],
  contactNote:
      'Tell me what you are building or which role you are hiring for. '
      'I reply within two working days.',
);

const socialLinks = [
  SocialLink('GitHub', 'https://github.com/your-username'),
  SocialLink('LinkedIn', 'https://linkedin.com/in/your-username'),
  SocialLink('Bluesky', 'https://bsky.app/profile/your-username'),
];

const experience = [
  Job(
    years: '2024 to now',
    role: 'Freelance developer',
    place: 'Self-employed',
    note: 'Websites and internal tools for small businesses, built with Jaspr.',
  ),
  Job(
    years: '2021 to 2024',
    role: 'Software engineer',
    place: 'Northwind Labs',
    note: 'Built the customer dashboard and moved its front end to Dart.',
  ),
  Job(
    years: '2019 to 2021',
    role: 'Junior developer',
    place: 'Brightside Agency',
    note: 'Shipped marketing sites and small web apps for agency clients.',
  ),
];

const skills = [
  Skill('Front end', 'Dart, Jaspr, Flutter web, HTML, CSS, TypeScript'),
  Skill('Back end', 'Dart server, Shelf, PostgreSQL, REST APIs'),
  Skill('Tooling', 'Git, GitHub Actions, Docker, Firebase'),
];

const categories = ['All', 'Web apps', 'Tools', 'Open source'];

const projects = [
  Project(
    title: 'Tidepool',
    summary: 'A habit tracker that works offline and syncs when you reconnect.',
    category: 'Web apps',
    year: 2025,
    tags: 'Jaspr, Dart, IndexedDB',
    tone: 1,
    url: 'https://example.com/tidepool',
  ),
  Project(
    title: 'Fieldnotes',
    summary: 'Markdown notes with instant full-text search, all in the browser.',
    category: 'Tools',
    year: 2025,
    tags: 'Dart, Web Workers',
    tone: 2,
    url: 'https://example.com/fieldnotes',
  ),
  Project(
    title: 'Parcel Map',
    summary: 'A dispatch dashboard that shows where every delivery is right now.',
    category: 'Web apps',
    year: 2024,
    tags: 'Jaspr, PostgreSQL, Maps',
    tone: 3,
    url: 'https://example.com/parcel-map',
  ),
  Project(
    title: 'Kettle',
    summary: 'A command-line tool that turns a folder of Markdown into a site.',
    category: 'Open source',
    year: 2024,
    tags: 'Dart, CLI',
    tone: 4,
    url: 'https://example.com/kettle',
  ),
  Project(
    title: 'Rulebook',
    summary: 'A board game\'s rules as a searchable, printable web reference.',
    category: 'Tools',
    year: 2023,
    tags: 'Jaspr, Static hosting',
    tone: 1,
    url: 'https://example.com/rulebook',
  ),
  Project(
    title: 'jaspr_toast',
    summary: 'A small package for showing toast notifications in Jaspr apps.',
    category: 'Open source',
    year: 2023,
    tags: 'Dart, pub.dev',
    tone: 2,
    url: 'https://example.com/jaspr_toast',
  ),
];
