# Solo Teleprompter Recorder - Product Spec

## Vision

A focused mobile app for creators to read scripts and record themselves with a teleprompter overlay, without paying for premium app features.

## Primary User

- Single creator using their own phone
- Needs a distraction-resistant reading experience
- Needs fast repeatable record/review workflow

## Core User Flow

1. Create or open script
2. Enter Record With Overlay
3. Adjust readability settings
4. Start countdown
5. Record while scrolling
6. Stop and save take
7. Review and select best take

## Must-Have Features (Current Cycle)

- Script CRUD
- Smooth scroll teleprompter
- Adjustable font size
- Adjustable scroll speed
- Focus mask + read line
- Countdown start
- Record indicator + timer
- Tap-to-pause scrolling

## Must-Have Features (Next Cycle)

- Improve save reliability edge-cases (permission denied, low storage, interrupted writes)
- Review Screen v2 overlays: lower third + captions + image overlay
- Caption minimal modes: one-word-at-a-time and line mode
- Basic style controls for overlays (color/font/opacity)
- Green screen feasibility decision (native live effect vs post-processing)

## Current Build Snapshot (May 24, 2026)

- Script CRUD is functional.
- Teleprompter scrolling and readability controls are functional.
- Record-with-overlay flow is functional (countdown, indicator, timer).
- Takes are persisted locally and listed in-app with playback.
- Gallery save is best-effort; app-local save remains source of truth.
- Crash/reload resilience added for interrupted post-record finalization.

## Non-Goals (Current Cycle)

- Multi-user collaboration
- Team roles/permissions
- Live remote control by producer
- Shared cloud script editing

## Storage Strategy

- Video files: device storage (gallery)
- App metadata (takes, script links, flags): local database
- Cloud sync: optional future enhancement
