# Team Teleprompter - Product Specification

**Version:** 1.0  
**Last Updated:** May 21, 2026  
**Build Timeline:** 8-12 weeks

---

## 1. Overview

A **centralized teleprompter app** for content creation teams. Enables creators to record video with professional prompting while maintaining a shared script library that the whole team can access and edit in real-time.

### Team Context
- **Team Size:** 3 core roles
  - **Publisher:** Manages script library, publishes final scripts
  - **Editor:** Drafts and revises scripts
  - **Creator:** Records content using teleprompter
- **Use Case:** Mixed live + pre-recorded video content creation
- **Tools:** Integrated with Adobe Creative Cloud workflow

---

## 2. Core Problem Statement

**Current Pain Point:**  
"Scripts are scattered. I record with my camera, they record with theirs. We need everything centralized."

**Solution:**  
Single source of truth for all scripts with real-time sync across all devices, allowing team members to work on their scripts from anywhere while creators read and record seamlessly.

---

## 3. User Roles & Permissions

| Role | Create Scripts | Edit All Scripts | Publish Scripts | Use Prompter | View Analytics |
|------|----------------|------------------|-----------------|--------------|----------------|
| **Publisher** | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Editor** | ✓ | ✓ | ✗ | ✓ | Limited |
| **Creator** | ✗ | Own only | ✗ | ✓ | Own only |

---

## 4. Must-Have Features (v1)

### 4.1 Real-Time Script Sync
- Central script library accessible from all devices
- Live updates when anyone edits
- Conflict-free collaborative editing
- Offline mode with sync when reconnected

### 4.2 Remote Control
- Publisher/Editor can control Creator's prompter remotely
- Control scroll speed, pause, jump to sections
- Emergency pause and position reset
- Works over internet or local network

### 4.3 Voice-Activated Auto-Scroll
- Prompter follows creator's voice in real-time
- Automatically pauses when creator stops speaking
- Adjustable sensitivity and catch-up speed
- Manual override always available

### 4.4 Recording with Prompter Overlay
- Record video while prompting
- Option to include/exclude prompter text in recording
- Timing markers and pace indicators
- Export to Adobe Creative Cloud workflow

### 4.5 Centralized Script Library
- Search and filter scripts
- Tags, categories, and folders
- Version history
- Draft vs Published status
- Quick duplicate and template creation

---

## 5. Device Support

### Primary Devices
- **iOS (iPad)** - Studio/home recording setup
- **iOS (iPhone) + Android (Phone)** - Field recording, mobile creation

### Desktop Support (Optional Phase 2)
- Web app for Publisher/Editor workflows
- Desktop Flutter app for large monitor setups

---

## 6. User Journeys

### Journey 1: Publisher Creates and Shares Script
1. Open app, tap "New Script"
2. Write or paste content
3. Add formatting, cues, timing markers
4. Tag and categorize
5. Tap "Publish" - instantly available to all team members
6. Push notification to Creator: "New script ready"

### Journey 2: Creator Records Content
1. Open app, see published scripts
2. Select script, tap "Start Prompter"
3. Position device with camera
4. Enable voice auto-scroll
5. Start recording (in-app or external camera)
6. Prompter scrolls as they speak
7. Tap "Done" - save recording metadata
8. Export to editing workflow

### Journey 3: Editor Updates Script During Recording
1. Receive notification: "Creator is using Script XYZ"
2. Open script in edit mode
3. Make changes (typo fix, reword line)
4. Tap "Push Update"
5. Creator's prompter updates in real-time
6. Creator sees subtle notification: "Script updated"

### Journey 4: Publisher Remotely Controls Prompter
1. Open "Live Sessions" view
2. See "Creator is recording Script ABC"
3. Tap "Take Control"
4. Adjust scroll speed remotely
5. Pause if needed
6. Jump to specific section
7. Hand control back to Creator

---

## 7. Key UI Components

### Script Library Screen
- Grid or list of all scripts
- Filters: Mine, Team, Published, Drafts
- Search bar with instant results
- Quick actions: Edit, Duplicate, Archive

### Script Editor
- Clean distraction-free editor
- Rich text formatting (bold, italic, emphasis)
- Cue markers (pause, emphasis, pronunciation notes)
- Character/word count
- Estimated read time
- Version history sidebar

### Prompter View
- Fullscreen text display
- High contrast, adjustable font size
- Scroll speed control (slider)
- Voice mode toggle
- Recording indicator
- Floating controls (minimize, pause, jump)

### Remote Control Panel
- Live session list
- Selected script preview
- Scroll control
- Section navigator
- Emergency reset button

---

## 8. Technical Requirements

### Performance
- Script load time: < 500ms
- Sync latency: < 1 second
- Voice auto-scroll lag: < 200ms
- Zero dropped frames during scroll at 60fps
- Works smoothly on 3-year-old devices

### Reliability
- Offline-first architecture
- Auto-save every 2 seconds
- Conflict resolution (last-write-wins with notifications)
- Crash recovery to last position
- Network reconnection handling

### Security
- Firebase Authentication
- Role-based access control
- Encrypted data in transit and at rest
- Team invitation system
- Audit log for published scripts

---

## 9. Integration Points

### Adobe Creative Cloud
- Export recording metadata (timings, takes, notes)
- Script export for video captions
- Consider Adobe CC login integration (Phase 2)

### Future Integrations (Phase 3+)
- Cloud storage (Dropbox, Google Drive)
- Video platforms (YouTube, Vimeo metadata sync)
- CMS integration for blog/article conversion

---

## 10. Success Metrics

### Usage Metrics
- Scripts created per week
- Recording sessions per creator
- Average script reuse rate
- Collaboration events (multi-user edits)

### Quality Metrics
- App crash rate < 0.1%
- Sync failure rate < 1%
- Voice tracking accuracy > 90%
- User-reported issues per month

### Team Efficiency
- Time saved vs previous workflow
- Script drafts to published ratio
- Remote control usage frequency

---

## 11. Out of Scope (v1)

These features are deferred to future versions:
- ❌ Multiple teams/organizations (single team only for v1)
- ❌ Advanced analytics and delivery coaching
- ❌ AI script generation or improvement suggestions
- ❌ Teleprompter hardware integration
- ❌ Live streaming integration
- ❌ Multi-language support
- ❌ Custom branding per user
- ❌ API for third-party integrations

---

## 12. Design Principles

1. **Simplicity First:** Clean, uncluttered interface. Every screen has one primary action.
2. **Fast Access:** From launch to prompting in < 5 taps.
3. **Fault Tolerant:** Never lose work. Always recoverable.
4. **Creator-Focused:** Prompter view is distraction-free and optimized for on-camera delivery.
5. **Team Harmony:** Real-time features should enhance, not interrupt, individual workflows.

---

## 13. Open Questions & Decisions Needed

- [ ] **Recording Storage:** Store videos in-app or rely on device camera roll?
- [ ] **Team Size Limit:** Cap at 10 users for v1?
- [ ] **Subscription Model:** Free tier limits? Paid features?
- [ ] **Branding:** App name and visual identity
- [ ] **Voice Recognition:** Use device speech recognition or third-party API?

---

## Next Steps

1. Review and approve this spec
2. Set up Firebase project
3. Initialize Flutter project structure
4. Begin Phase 1 implementation (Core Prompter + Sync)
