# Mascot Studio

A Flutter web workshop that turns an app description or landing page into a mascot palette, then animates the character you pick.

## Run

You need a Google AI Studio key in `.env`:

```
GEMINI_API_KEY=your_key_here
```

Then:

```bash
flutter run -d chrome
```

## Flow

1. Paste a product URL and/or a short description
2. Pick one of four generated mascot palettes
3. Lock a hero still, animate actions, download a zip
