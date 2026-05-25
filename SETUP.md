# Setup & Direction Snapshot

## Current Direction

This app has pivoted to a **single-user teleprompter recorder**.

- Focus: creator records directly from phone with script overlay.
- Team/collaboration flows are not part of the current milestone.

## Environment

- Flutter installed and runnable locally
- Firebase configured and functional
- iOS device testing active

## What Is Working

- Authentication and persistent login
- Team creation path still exists in code, but no longer core to product direction
- Script creation/edit/save
- Script library loading with deployed Firestore rules/indexes
- Teleprompter view with adjustable font size
- Record-with-overlay flow:
  - camera preview
  - script overlay
  - countdown
  - focus mask + read-line control
  - recording indicator + timer

## Immediate Build Goal

Deliver a reliable solo workflow:
1. Create script
2. Record with overlay
3. Save to device gallery
4. Review takes in-app

## Notes

- Existing team modules may remain temporarily but are considered legacy scope.
- Future work should prioritize solo recording UX over collaboration architecture.
