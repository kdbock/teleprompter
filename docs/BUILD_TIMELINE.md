# Solo Teleprompter Build Timeline

## Objective

Ship a reliable single-user teleprompter recorder that runs on phone and stores recordings locally.

## Phase 1 (Current): Core Recording Workflow

- [x] Auth and app entry flow
- [x] Script create/edit/save
- [x] Teleprompter scroll view
- [x] Record-with-overlay screen
- [x] Countdown + recording indicator + timer
- [x] Font size and scroll speed controls
- [x] Focus mask + adjustable read line
- [x] Tap-to-pause scrolling while recording

## Phase 2: Output Reliability

- [x] Save recordings to Photos/Videos gallery (best effort with fallback to app-local save)
- [x] Persist local metadata for recordings
- [x] Build recordings list screen
- [x] Add playback screen
- [x] Add delete/rename for takes
- [x] Add crash/reload recovery during post-record finalize

## Phase 3: Creator UX Polish

- [x] Mirror mode
- [x] Orientation lock
- [x] Touch lock (distraction-free mode)
- [x] Script markers / jump points
- [x] Speed presets
- [x] Section loop for retakes
- [x] Front/rear camera toggle
- [x] Resolution selector (1080p/4K attempt)
- [x] FPS selector (30/60 with fallback handling)
- [x] Hands-free controls (hardware key toggle)
- [x] Audio preflight + ambient level indicator

## Phase 4: Review Screen v2 (Next)

- [x] Lower third overlay (text + position + basic color controls)
- [x] Captions overlay (minimal modes: one-word-at-a-time and line mode)
- [x] Caption style controls (font size, color, background opacity)
- [x] Image overlay (import, position, scale, opacity)
- [ ] Green screen option (deferred)

## Phase 5: Optional Advanced

- [ ] Burned-in caption export
- [ ] Basic pace analytics
- [ ] Optional cloud backup

## Deferred Scope

- Team management and roles
- Team script sync/collaboration
- Remote producer control

These may be revisited after the solo recording product is stable.
