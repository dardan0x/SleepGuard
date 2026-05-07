# Feature: F8 — PDF Sleep Report

## Status: Done
## Completed: 2026-05-07

## Summary

Users can generate and share a formatted PDF sleep report from SessionDetailView. The report includes session date, sleep score, statistics grid, and a detailed event list.

## Files

| File | Purpose |
|------|---------|
| `Packages/Recordings/Sources/Recordings/SleepReportPDFGenerator.swift` | PDF generation using UIGraphicsPDFRenderer |
| `Packages/Recordings/Sources/Recordings/SessionDetailView.swift` | Export Report toolbar button and share presentation |

## Routes

No new routes added. PDF share is presented as a sheet within SessionDetailView.

## State

| Property | Location | Scope |
|----------|----------|-------|
| `isSharePresented` | SessionDetailView @State | View-local (reused for audio and PDF share) |
| `shareItems` | SessionDetailView @State | View-local (reused for audio and PDF share) |

## Edge Cases

- PDF is saved to temporary directory with session UUID filename
- Existing temp file is removed before generating new PDF
- Multi-page support: event list continues on new pages if it exceeds page height
- Score color and rating text adapt to score value (green/orange/red)

## Tasks Completed

| Task ID | Name |
|---------|------|
| F8-T1 | PDF generation service |
| F8-T2 | PDF share UI |
