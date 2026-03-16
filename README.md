# VisionAid - AI Accessibility Companion

**"See the world. Navigate freely. Live independently."**

VisionAid is an autonomous AI accessibility app for blind and low vision (BLV) individuals. Built with Flutter for iOS, it uses NVIDIA Nemotron models to provide real-time scene descriptions, text reading, and obstacle detection.

## Features (MVP)

- **Real-Time Scene Description** - AI-powered environment narration using Nemotron Vision-Language model
- **Text Reading (OCR)** - Read printed text aloud with Google ML Kit
- **Accessible Navigation UI** - Full VoiceOver compatibility with gesture controls
- **Mode Selector** - Scene, Read, Navigate, and Explore modes
- **Priority-Based TTS** - Safety alerts preempt other audio

## NVIDIA Nemotron Integration

VisionAid uses a hybrid Nemotron architecture:

| Model | Purpose |
|-------|---------|
| `nvidia/nemotron-nano-12b-v2-vl` | Vision-language image understanding |
| `nvidia/nemotron-nano-30b-a3b` | Agentic orchestration and tool-calling |
| `nvidia/nemotron-super-120b-a12b` | Complex multi-step reasoning |

## Gesture Controls

| Gesture | Action |
|---------|--------|
| Double tap | Describe current scene |
| Single tap | Read text in view |
| Long press | Open settings/mode selector |
| Swipe up | Cycle through modes |
| Swipe down | Repeat last spoken output |
| Two-finger tap | Pause/resume continuous description |

## Getting Started

### Prerequisites

- Flutter 3.19+
- Xcode 15+ (for iOS)
- NVIDIA NIM API key

### Installation

```bash
# Clone the repository
git clone https://github.com/nick-mama/nvdia-hackathon.git
cd nvdia-hackathon

# Install dependencies
flutter pub get

# Install iOS pods
cd ios && pod install && cd ..

# Run on iOS simulator or device
flutter run
```

### Configuration

1. Launch the app and complete onboarding
2. Go to Settings (long press on camera screen)
3. Enter your NVIDIA NIM API key
4. Save and start using VisionAid

## Project Structure

```
lib/
├── core/
│   ├── constants/       # App constants and enums
│   ├── providers/       # Riverpod state providers
│   └── theme/           # Brand colors and typography
├── features/
│   ├── agent/           # Agentic orchestration logic
│   ├── camera/          # Camera capture and preview
│   ├── modes/           # Mode selector UI
│   ├── ocr/             # ML Kit text recognition
│   ├── onboarding/      # Audio-guided tutorial
│   ├── scene/           # Nemotron AI service
│   ├── settings/        # App settings
│   └── tts/             # Text-to-speech service
└── ui/
    └── widgets/         # Accessible UI components
```

## Tech Stack

- **Framework**: Flutter 3.x (Dart)
- **State Management**: Riverpod 2.x
- **AI Vision**: NVIDIA Nemotron (VL, 30b, 120b)
- **OCR**: Google ML Kit Text Recognition
- **TTS**: flutter_tts with iOS AVSpeechSynthesizer

## Accessibility

VisionAid is designed with accessibility as a core requirement:

- WCAG 2.1 AA compliance
- Full VoiceOver/TalkBack support
- Minimum 44x44pt touch targets
- High contrast color palette
- Audio-first design pattern

## Brand Colors

| Role | Color | Hex |
|------|-------|-----|
| Primary | Deep Navy | #1A3A5C |
| Accent | Accessibility Teal | #00A896 |
| Highlight | Warm Amber | #F4A261 |
| Background | Soft Mint | #EAF6F4 |

## License

This project was created for the Impact on Humankind Hackathon.

## Acknowledgments

- NVIDIA for the Nemotron model family
- Google ML Kit for on-device OCR
- Flutter team for the accessibility framework
