# Solo Teleprompter Recorder

A single-user teleprompter app for recording video with script overlay on phone.

## Product Direction (Current)

This project is now focused on a **solo creator workflow**:
1. Create/edit script
2. Start teleprompter
3. Record with overlay
4. Save takes on device

Team collaboration features are now deferred.

## Current Status

✅ Login works
✅ Script creation/saving works
✅ Teleprompter works with adjustable font size
✅ Record-with-overlay flow works (camera + script overlay + recording)
✅ Countdown, read-line focus mask, tap-to-pause, recording indicator

## Scope Now

### In Scope
- Single user account
- Local script and recording workflow
- Recording directly from phone
- Readability controls (font/scroll/focus line)

### Deferred
- Team roles and permissions
- Team creation/invite workflows
- Real-time collaboration/sync for teams
- Remote producer controls

## Storage Strategy

- **Primary:** Phone-local storage for recordings
- **Secondary:** App metadata cache for organizing takes (local DB)
- Cloud sync is optional and can be reintroduced later.

## Run

```bash
flutter run
```

## Local Secret Key Setup (Whisper)

1. Edit `.env.local` and set your key:

```bash
OPENAI_API_KEY=sk-...
```

2. Run with local env injection:

```bash
./scripts/run_with_env.sh -d <device-id>
```

## Key Docs

- [Record Overlay Features](docs/RECORD_OVERLAY_FEATURES.md)
- [Build Timeline](docs/BUILD_TIMELINE.md)
- [Product Spec](docs/PRODUCT_SPEC.md)

## Next Priorities

1. Save recordings to Photos/Videos + metadata list in app
2. Playback/review screen for takes
3. Mirror mode and orientation lock
4. Distraction-free recording mode
