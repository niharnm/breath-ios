# Breath iOS

Native SwiftUI iPhone frontend for Breath.

Safety model:

- Always shows `Call 911 now`.
- Always prioritizes dispatcher instructions over Breath.
- Does not diagnose.
- Uses predefined local protocol objects for CPR, choking, and severe bleeding.
- Does not include infant CPR or advanced medical procedures.

The backend should be treated as a sync/API layer, not the only source of emergency guidance. The app keeps local protocol steps so it can still guide when the network is unavailable.

## Build

Open `Breath.xcodeproj` in Xcode, or run:

```sh
xcodebuild -project Breath.xcodeproj -scheme Breath -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```
