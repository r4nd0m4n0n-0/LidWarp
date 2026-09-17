# LidWarp

LidWarp is a macOS menu bar application that creates a live screen-bending visual illusion with optional retro CRT-style visual effects.

The application captures the display using Apple's public ScreenCaptureKit API and renders the captured desktop through a transparent, click-through overlay.

## Features

- Menu bar application
- Live desktop capture
- Click-through screen overlay
- Manual fold simulation
- Automatic fold animation
- Adjustable Auto Fold speed
- Retro phosphor-green monochrome effect
- CRT glow
- CRT vignette
- Subtle scanlines
- Master visual-effect intensity control
- Reset Fold control
- Reset Visual Settings control
- Persistent settings
- Automated Swift tests
- Automated render-preview testing
- GitHub Actions macOS build
- Automatically packaged macOS application
- Ad-hoc code-signed release build

## Requirements

- macOS 13 or newer
- Screen Recording permission
- A Mac capable of running macOS 13 or newer

## Installation

1. Download the latest `LidWarp-macOS.zip` from the GitHub Releases page.
2. Extract the ZIP.
3. Move `LidWarp.app` to your Applications folder.
4. Launch LidWarp.
5. Grant Screen Recording permission when requested.

If macOS blocks the application, check:

**System Settings → Privacy & Security**

and review the security prompt for LidWarp.

## Screen Recording Permission

LidWarp requires Screen Recording permission because it captures the display before applying its visual effects.

Open:

**System Settings → Privacy & Security → Screen Recording**

Enable permission for LidWarp and restart the application if necessary.

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

- `Flat` — normal screen appearance
- `Folded` — maximum simulated fold

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

- Effect Intensity: `100%`
- Fold Amount: `0%`
- Auto Fold: disabled
- Fold Speed: `50%`
- Retro Phosphor Green: disabled
- CRT Glow: disabled

## Building From Source

LidWarp uses Swift Package Manager.

The package targets macOS 13 or newer.

Build on a Mac with:

```bash
swift package resolve
swift build
