# Record Overlay Roadmap

Goal: build a practical teleprompter + video overlay workflow for single-user creator recording, then layer in advanced controls.

## Product Goal

A creator can:
1. Open a script
2. Start a guided record session
3. Read from a distraction-friendly overlay
4. Capture and review takes quickly

## Feature Backlog

### Core UX Enhancements (Immediate)
- [x] Pre-record countdown (3-2-1)
- [x] Tap anywhere to pause/resume scrolling
- [x] Focus mask (dim top/bottom, highlight read band)
- [x] Adjustable read-line position
- [x] Mirror mode
- [x] Orientation lock + accidental-touch lock
- [x] Auto-resume from last script position

### Recording Controls (Near-Term)
- [x] Front/rear camera toggle
- [x] Resolution selector (1080p/4K where available)
- [x] FPS selector (30/60 where available)
- [x] Hands-free controls (volume keys/Bluetooth clicker support via hardware keys)
- [x] Audio level indicator while recording (ambient level meter pre-record)
- [x] Device light/noise preflight check (mic/storage readiness + ambient sampling)

### Script Navigation (Near-Term)
- [x] Script section markers
- [x] Jump-to-marker controls
- [x] Section loop for retakes
- [x] Speed presets (slow/normal/presentation)

### Session Output (Near-Term)
- [x] Save takes list (local)
- [x] Rename/tag takes
- [x] Mark best take
- [x] Instant playback
- [x] Quick trim (head/tail)

### Review Screen v2 (Planned Next)
- [x] Lower third overlay:
  - text content
  - basic color controls (text/background)
  - position preset (bottom-left/bottom-center/bottom-right)
- [x] Captions overlay:
  - mode: one-word-at-a-time
  - mode: line/phrase
  - style: color/font size/background opacity
- [x] Image overlay:
  - import image asset
  - position, scale, opacity
- [ ] Green screen (Deferred):
  - explicitly deferred for current cycle
  - reconsider after export/reliability hardening

### Advanced / Phase 2
- [ ] Remote control from second device
- [ ] Burned-in caption export
- [ ] Reading pace analytics (wpm/pause hotspots)
- [ ] Team/session collaboration controls

## Implementation Checklist

### Phase 1: Stabilize Creator Flow (Now)
- [x] Add countdown before recording starts
- [x] Merge start controls into one launch action
- [x] Add tap-to-pause on overlay
- [x] Add focus mask with adjustable center line
- [x] Persist in-session settings (font, speed, line position)
- [x] Save and display recording file metadata locally
- [x] Recover interrupted recording finalization after app reload/crash

### Phase 2: Quality-of-Life Controls
- [x] Add mirror mode
- [x] Add orientation + touch lock toggles
- [x] Add script marker/jump support
- [x] Add speed presets

### Phase 3: Review + Retake Loop
- [x] Build recordings list screen
- [x] Add playback + scrub
- [x] Add rename/tag/best-take actions
- [x] Add quick trim

### Phase 4: Advanced Add-ons
- [ ] Add remote controller mode
- [ ] Add analytics and export enhancements

## Acceptance Criteria (Phase 1)
- [ ] User can start recording with countdown in <= 2 taps from script detail
- [ ] User can read with adjustable font and stable overlay while recording
- [ ] User can pause/resume scroll without stopping recording
- [ ] User sees clear recording state indicator and elapsed timer
- [ ] Saved recording is recoverable from local storage metadata

## Notes
- Prioritize local-first reliability over cloud sync.
- Keep controls minimal and high-contrast during active recording.
- Avoid adding team-dependent logic to recording flow until solo workflow is polished.
