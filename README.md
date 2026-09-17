# RetroPhosphor

A macOS menu bar app that creates a live screen-bending illusion with optional retro CRT-style visual effects.

RetroPhosphor captures the display using Apple's public `ScreenCaptureKit` API and renders the captured desktop through a transparent, click-through overlay.

## Features

* Menu bar application
* Live desktop capture
* Click-through screen overlay
* Manual screen-fold simulation
* Automatic fold animation
* Adjustable Auto Fold speed
* Retro phosphor-green monochrome effect
* CRT glow effect
* CRT vignette
* Subtle scanlines
* Master visual-effect intensity control
* Reset Fold control
* Reset Visual Settings control
* Settings preserved using `UserDefaults`
* Automated Swift tests
* Automated render-preview testing
* GitHub Actions macOS build
* Automatically packaged `.app`
* Ad-hoc code-signed release build

## Requirements

* macOS 13 or newer
* Screen Recording permission
* Apple Silicon or Intel Mac capable of running macOS 13 or newer

## Installation

1. Download the latest `RetroPhosphor-macOS.zip` from the GitHub Releases page.

2. Extract the ZIP.

3. Move `RetroPhosphor.app` to your Applications folder.

4. Launch `RetroPhosphor`.

5. macOS may ask for Screen Recording permission.

6. Open:

   **System Settings → Privacy & Security → Screen Recording**

7. Enable permission for RetroPhosphor.

8. Restart the application if necessary.

## First Launch

RetroPhosphor requires Screen Recording permission because it needs to capture the display before applying the visual effects.

The application does not modify the physical display or hardware hinge.

The fold effect is a visual simulation rendered over the captured screen.

## Controls

### Enable Effect

Turns the screen effect on or off.

### Retro Phosphor Green

Applies a monochrome green CRT/phosphor appearance.

### CRT Glow

Adds a soft CRT-style glow and vignette.

### Effect Intensity

Controls the overall strength of the visual effects.

### Fold Simulation

Controls the simulated amount of screen folding.

* `Flat` — normal screen appearance
* `Folded` — maximum simulated fold

### Auto Fold

Automatically animates the fold between flat and folded states.

### Fold Speed

Controls the speed of the automatic fold animation.

### Reset Fold

Returns the fold amount to zero and disables Auto Fold.

### Reset Visual Settings

Restores the visual settings to their defaults.

## Default Visual Settings

The default state is:

* Effect Intensity: `100%`
* Fold Amount: `0%`
* Auto Fold: disabled
* Fold Speed: `50%`
* Retro Phosphor Green: disabled
* CRT Glow: disabled

## Building From Source

RetroPhosphor is a Swift Package Manager project.

The package targets macOS 13 or newer.

Build locally on a Mac with:

```bash
swift package resolve
swift build
```

Run tests with:

```bash
swift test
```

You can also open the package in Xcode and run the `RetroPhosphor` target.

## GitHub Actions

This repository includes a GitHub Actions workflow that builds and tests the application on Apple's hosted macOS runner.

The workflow performs:

1. Swift package resolution
2. Debug build
3. Automated tests
4. Render-preview collection
5. Release executable packaging
6. macOS `.app` bundle creation
7. `Info.plist` generation
8. Ad-hoc code signing
9. Code-signature verification
10. Release ZIP creation
11. Build diagnostics generation
12. Test report generation

The resulting artifacts include:

* `RetroPhosphor-macOS`
* `RetroPhosphor-render-preview`
* `RetroPhosphor-test-report`
* `RetroPhosphor-build-diagnostics`

## Testing

The project includes automated tests covering the visual-effect math and phosphor rendering pipeline.

Render-preview tests also provide generated PNG output that can be inspected from the GitHub Actions artifacts.

## Project Status

**Version: 1.0.0**

The current release focuses on a software-based visual simulation using public macOS APIs.

The project does not currently require or communicate with physical hinge-angle hardware.

## Privacy

RetroPhosphor requires Screen Recording permission to capture the display.

The application is designed as a local visual-effect application. The project does not require an online service for its core screen effect.

## Compatibility

RetroPhosphor is intended for macOS 13 or newer.

Because the application uses Apple's ScreenCaptureKit and SwiftUI/AppKit APIs, behavior may vary between macOS versions and hardware configurations.

## Legal / Attribution

RetroPhosphor is an independent software project.

The application is not affiliated with or endorsed by Apple.

The project name and visual-effect terminology are used to describe the application's functionality.

## License

See the repository license file for the applicable license terms.
