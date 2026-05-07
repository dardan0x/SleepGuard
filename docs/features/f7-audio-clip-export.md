# Feature: F7 — Audio Clip Export

## Status: Done
## Completed: 2026-05-07

## Summary

Users can export and share their recorded sleep audio from SessionDetailView. Supports sharing the full session recording or individual snore event clips via the native iOS share sheet.

## Files

| File | Purpose |
|------|---------|
| `Packages/Recordings/Sources/Recordings/SessionDetailView.swift` | Added share functionality to toolbar and event rows |

## Routes

No new routes added. Share functionality is presented as a sheet within the existing SessionDetailView.

## State

| Property | Location | Scope |
|----------|----------|-------|
| `isSharePresented` | SessionDetailView @State | View-local |
| `shareItems` | SessionDetailView @State | View-local |

## Edge Cases

- Share button hidden when `audioFileURL` is nil (session has no recorded audio)
- Event clip export trims to valid bounds (start ≥ 0, end ≤ file duration)
- Export uses AVAssetExportSession with AppleM4A preset for broad compatibility
- Temp clip files use event UUID in filename to avoid collisions

## Tasks Completed

| Task ID | Name |
|---------|------|
| F7-T1 | Share full session audio |
| F7-T2 | Export individual event clips |
