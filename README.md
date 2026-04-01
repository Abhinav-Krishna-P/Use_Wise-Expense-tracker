<<<<<<< HEAD
# 💸 AI Expense Tracker

A beautiful, production-ready Flutter UI for an AI-powered personal expense tracker.

**Dark glassmorphism aesthetic** · **Animated charts** · **AI chat interface** · **Mock data ready for backend wiring**

## Screenshots

| Chat Screen | Analytics Dashboard |
|---|---|
| AI-powered expense input via natural language | Full spending analytics with interactive charts |

## Features

### 🤖 AI Chat Screen
- Natural language expense input ("Spent ₹450 on Zomato")
- Chat bubbles with user/AI styling (gradient user bubbles, teal-accented AI)
- Animated typing indicator with bouncing dots
- Camera & voice input placeholders (ready for Gemini Vision/Audio)
- Frosted glass input bar with auto-expanding text field

### 📊 Analytics Dashboard
- **Hero Spend Card** — Total spent with shimmer loading, comparison badge
- **Period Toggle** — Switch between Today / This Week / This Month
- **Stats Cards** — Horizontal scroll with emoji icons and % change badges
- **Pie Chart** — Interactive category breakdown (tap to highlight)
- **Line Chart** — 7-day spending trend with gradient fill
- **Bar Chart** — Monthly overview with average line overlay
- **Forecast Card** — AI spending forecast with progress bar
- **Category Bars** — Animated horizontal bars showing spending distribution
- **Recent Transactions** — Swipe-to-dismiss expense list with staggered animations

## Architecture

```
lib/
├── main.dart                          # App entry point, Provider setup
├── theme/app_theme.dart               # Complete design system
├── models/                            # Data classes
├── mock/mock_data_service.dart        # All dummy data & AI responses
├── providers/                         # State management (Provider)
├── screens/                           # Chat, Analytics, Home (nav)
└── widgets/                           # Reusable UI components
    ├── chat/                          # Chat bubbles, typing indicator, input bar
    ├── analytics/                     # All chart & card widgets
    └── shared/                        # Expense list item, gradient button
```

## Tech Stack

- **Flutter** 3.x + **Dart** 3.11+
- **Provider** — State management
- **fl_chart** — Pie, line, and bar charts
- **flutter_animate** — Entrance animations
- **google_fonts** — Poppins typography
- **shimmer** — Loading skeletons
- **intl** — Date formatting

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run on device/emulator
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze
```

## Design System

| Token | Value |
|-------|-------|
| Background | `#0A0A1A` |
| Card | `#13132B` |
| Glass | `#1E1E3A` |
| Primary | `#6C63FF` (Purple) |
| Secondary | `#3ECFCF` (Teal) |
| Gradient | Purple → Teal |
| Font | Poppins (Google Fonts) |

## Future Integration

The mock layer is designed for easy backend replacement:
- `chat_provider.dart` — Replace `MockDataService` responses with **Gemini API** calls
- `expense_provider.dart` — Replace seed data with **database/API** persistence
- Camera button → **Gemini Vision** for receipt scanning
- Voice button → **Gemini Audio** for voice expense logging

## License

This project is for educational/portfolio purposes.
=======
# expense_tracker
track  expenses  with  ai
>>>>>>> b8152bc94967a82ca17ac6b010f8ffdf1ef0d793

finished