# Feature: F9 — Enhanced Detection

## Status: Done
## Completed: 2026-05-07

## Summary

Replaced amplitude-threshold snore detection with a CoreML-based classifier for more accurate snoring detection and reduced false positives. The model classifies a single decibel reading into none/quiet/light/loud probabilities. SnoreDetector now prefers CoreML inference when available and falls back to dB thresholds automatically.

## Files

| File | Purpose |
|------|---------|
| `Packages/AudioEngine/Sources/AudioEngine/SnoreClassifier.mlmodel` | CoreML model (decibel → 4-class softmax probabilities) |
| `Packages/AudioEngine/Sources/AudioEngine/SnoreDetector.swift` | Updated detector with lazy CoreML loading, CPU-only compute, confidence threshold, and threshold fallback |

## Routes

No new routes added. Detection logic is internal to the AudioEngine package.

## State

| Property | Location | Scope |
|----------|----------|-------|
| `classifier: SnoreClassifier?` | SnoreDetector | Singleton, lazy-loaded |
| `useCoreML: Bool` | SnoreDetector | Singleton, defaults to true |
| `confidenceThreshold: Float` | SnoreDetector | Singleton, defaults to 0.6 |

## Edge Cases

- Model load failure (missing file, incompatible OS) → `classifier = nil`, `useCoreML = false`, threshold fallback activates automatically
- Prediction failure (malformed input, runtime error) → `classifyWithThresholds` called as fallback
- Confidence below threshold → returns `.none` even if a snore class has highest probability (reduces false positives)
- Simulator builds: CoreML runs on CPU via `.cpuOnly` config; no GPU/ANE dependency

## Tasks Completed

| Task ID | Name |
|---------|------|
| F9-T1 | CoreML model integration |
| F9-T2 | Replace threshold detection with ML |
