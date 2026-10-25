// All the text shown inside the houses lives here. Edit it and the overlays
// pick it up automatically.

class Fact {
  const Fact(this.label, this.value);
  final String label;
  final String value;
}

class Profile {
  const Profile({
    required this.name,
    required this.email,
    required this.intro,
    required this.facts,
    required this.about,
    required this.contactNote,
  });

  final String name;
  final String email;
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
    this.url,
    this.note = '',
  });

  final String years;
  final String role;
  final String place;

  /// The company's website, if any.
  final String? url;
  final String note;
}

class Education {
  const Education({
    required this.years,
    required this.degree,
    required this.school,
    this.note = '',
  });

  final String years;
  final String degree;
  final String school;
  final String note;
}

class Skill {
  const Skill(this.area, this.items);
  final String area;

  /// Comma-separated.
  final String items;
}

class Project {
  const Project({
    required this.title,
    required this.summary,
    required this.category,
    required this.tags,
    required this.tone,
    required this.links,
    this.year,
  });

  final String title;
  final String summary;
  final String category;
  final int? year;
  final String tags;

  /// 1-4, picks the card's accent colour (see .ov-tone-* in styles.css).
  final int tone;
  final List<SocialLink> links;
}

const profile = Profile(
  name: 'Kedar Karki',
  email: 'kedarkarky@gmail.com',
  intro:
      "I'm Kedar, a software engineer who builds mobile apps with Flutter and Dart "
      'and publishes open-source packages for the community.',
  facts: [
    Fact('Role', 'Software Engineer (Mobile)'),
    Fact('Works with', 'Flutter, Dart, Firebase'),
    Fact('Studying', 'MSc, Informatics and Intelligent Systems Engineering'),
  ],
  about: [
    'I work mostly with Flutter and Dart. Since November 2023 I have been a '
        'software engineer on the mobile team at Karobar Digital, and before that '
        'I was a Flutter developer at InternSathi.',
    'Outside of work I build and maintain open-source Dart and Flutter packages '
        'on pub.dev, including tools for image editing, converting HTML to images, '
        'and working with Nepali (Bikram Sambat) dates.',
    "I finished my bachelor's in Computer Engineering at Tribhuvan University, "
        'Institute of Engineering, in 2024, and I am now doing a master\'s in '
        'Informatics and Intelligent Systems Engineering there.',
  ],
  contactNote:
      "Working on something with Flutter, or want to talk about one of my packages? "
      'Send me a message, or find me on any of these.',
);

const socialLinks = [
  SocialLink('LinkedIn', 'https://www.linkedin.com/in/kedarkarkii/'),
  SocialLink('GitHub', 'https://github.com/kedarkarkee'),
  SocialLink('Facebook', 'https://www.facebook.com/kedarkarkii'),
];

const experience = [
  Job(
    years: 'Nov 2023 to now',
    role: 'Software Engineer (Mobile)',
    place: 'Karobar Digital Pvt. Ltd.',
    url: 'https://karobarapp.com',
  ),
  Job(
    years: 'Jan 2023 to Sep 2023',
    role: 'Flutter Developer',
    place: 'InternSathi (Sathi Edtech Pvt. Ltd.)',
    url: 'https://internsathi.com',
  ),
];

const education = [
  Education(
    years: '2025 to now',
    degree: "Master's in Informatics and Intelligent Systems Engineering",
    school: 'Tribhuvan University, Institute of Engineering',
  ),
  Education(
    years: '2019 to 2024',
    degree: "Bachelor's in Computer Engineering",
    school: 'Tribhuvan University, Institute of Engineering',
  ),
];

const skills = [
  Skill('Languages', 'Dart, JavaScript, Go, C, Python'),
  Skill('Frameworks', 'Flutter, Express.js'),
  Skill('Databases', 'SQLite, PostgreSQL, MongoDB, Cloud Firestore'),
  Skill('Tools and technologies', 'Flutter and Dart, Firebase, Git and GitHub, AWS S3, GitHub Actions, Nifty, Project Management'),
];

const projects = [
  Project(
    title: 'image_loom',
    summary:
        'Fast native image editing for Flutter. Compose crop, rotate, flip and '
        'resize operations and render them in one pass.',
    category: 'Flutter package',
    tags: 'Flutter, Dart, Image editing',
    tone: 1,
    links: [
      SocialLink('GitHub', 'https://github.com/kedarkarkee/image_loom'),
      SocialLink('pub.dev', 'https://pub.dev/packages/image_loom'),
    ],
  ),
  Project(
    title: 'html_to_image',
    summary:
        'A Flutter plugin for Android and iOS that converts an HTML web page '
        'into raster images.',
    category: 'Flutter plugin',
    tags: 'Flutter, Android, iOS',
    tone: 2,
    links: [
      SocialLink('GitHub', 'https://github.com/kedarkarkee/html_to_image'),
      SocialLink('pub.dev', 'https://pub.dev/packages/html_to_image'),
    ],
  ),
  Project(
    title: 'bikram_sambat',
    summary:
        'A Dart package for working with Nepali dates, with extensive date '
        'formatting and arithmetic in the Bikram Sambat calendar.',
    category: 'Dart package',
    tags: 'Dart, Nepali dates',
    tone: 3,
    links: [
      SocialLink('GitHub', 'https://github.com/kedarkarkee/bikram_sambat'),
      SocialLink('pub.dev', 'https://pub.dev/packages/bikram_sambat'),
    ],
  ),
];
