# TestFlight Release QA Matrix

Date: May 26, 2026

## Scope
- iOS device build/install
- Auth entry flow
- Script read/edit flow
- Record with overlay flow
- Review/export flow

## Build Gates
- [x] `flutter analyze` passes
- [x] `flutter test` passes
- [ ] `integration_test/auth_navigation_test.dart` passes on physical iOS device
- [ ] Xcode Archive (Release) succeeds

## Critical Functional Checks
- [ ] Login screen loads without crash
- [ ] Signup screen opens and returns to login
- [ ] Scripts list loads
- [ ] Script detail opens
- [ ] `Start Teleprompter` opens prompter screen
- [ ] `Record With Overlay` opens recorder screen
- [ ] Start/stop recording works
- [ ] Recording appears in recordings list
- [ ] Playback opens
- [ ] Lower third + captions + image overlay controls update preview
- [ ] `Export Styled Take` creates derived take

## Reliability / Edge Cases
- [ ] App cold restart after recording finalization still preserves take
- [ ] Gallery save fail path falls back to app-local recording
- [ ] Export failure path returns non-crashing error snackbar
- [ ] Low storage simulation handled (no crash)
- [ ] Denied camera/mic permissions handled (clear UI message)
- [ ] Airplane mode / offline does not break local recording flow

## Known Deferred / Beta
- Native iOS FFmpeg render path is intentionally unavailable (`native_ffmpeg_unavailable_ios`)
- Styled export currently uses fallback-safe path and metadata snapshot/derived take flow

## TestFlight Decision
- Internal TestFlight: [ ] GO  [ ] NO-GO
- External TestFlight: [ ] GO  [ ] NO-GO

Notes:
-
