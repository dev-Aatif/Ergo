# Ergo 🧠

A scalable, offline-first mobile learning application built with Flutter.

**Learn anything, anywhere — no internet required.**

---

## ✨ Features

- **Quiz Engine** — Multiple-choice quizzes with 3 difficulty modes (Plot Armor, Almost Him, Canon Event) and 3 speed modes (Snail, Crunch Time, Panic)
- **Offline-First** — All data stored locally in SQLite. Internet only needed to download new quiz packs
- **DLC Store** — Browse and download quiz packs from a growing catalog
- **Analytics** — Activity heatmap, performance trends, category breakdowns, and streak tracking
- **Audio Feedback** — Sound effects for correct/incorrect answers, streaks, and level-ups
- **Onboarding** — Interactive first-launch walkthrough explaining quiz modes, analytics, and the DLC store
- **Dark Mode** — Follows system theme automatically

## 📦 Tech Stack

| Component | Technology |
|---|---|
| Framework | Flutter |
| State Management | Riverpod |
| Database | SQLite (sqflite) |
| Routing | GoRouter |
| Charts | FL Chart + Heatmap Calendar |
| Typography | Google Fonts (Inter) |

## 🏗️ Architecture

```
lib/
├── core/
│   ├── audio/          # Audio feedback service
│   ├── database/       # SQLite service + seed data
│   ├── models/         # Category, Subject, Question, QuizAttempt
│   ├── router/         # GoRouter configuration
│   ├── ui/             # Main layout with navigation bar
│   └── utils.dart      # Shared utilities (color parsing, icon mapping)
├── features/
│   ├── home/           # Category grid + streak display
│   ├── category/       # Subject listing
│   ├── quiz/           # Quiz engine + game modes
│   ├── history/        # Analytics dashboard
│   ├── onboarding/     # First-launch walkthrough
│   ├── settings/       # User preferences + About page
│   ├── splash/         # Animated splash screen
│   └── storefront/     # DLC store + download manager
└── main.dart
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ≥ 3.2.0
- Android SDK (API 21+)

### Run

```bash
flutter pub get
flutter run
```

### Test

```bash
flutter test
```

## 🧪 Test Coverage

| Suite | Tests |
|---|---|
| Quiz Provider | 14 (init, config, scoring, game-over, timeout) |
| Streak Provider | 7 (gaps, consecutive days, edge cases) |
| History Provider | 6 (accuracy, heatmap, category breakdown) |
| Category Provider | 4 (filtering, description, isolation) |
| Analytics Provider | 5 (aggregation, accuracy, time) |
| Database Service | 9 (schema, CRUD, DLC merge, upsert) |
| Core Utils | 15 (color parsing, icon mapping) |

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

## 🤝 Contributing

1. Fork the repo
2. Create a feature branch
3. Submit a PR

Quiz packs can be contributed to [ergo-db](https://github.com/dev-Aatif/ergo-db).
