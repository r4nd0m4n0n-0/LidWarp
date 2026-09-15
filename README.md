# RetroPhosphor

A clean-room macOS experiment inspired by the general idea of displaying a transformed live desktop while the user visually simulates a folding display.

This repository is an independent implementation. It does **not** copy source code, assets, or trademarks from another project.

## Current features

- Menu-bar-only SwiftUI app.
- Live desktop capture using Apple's public ScreenCaptureKit API.
- Click-through overlay.
- Manual fold simulation.
- Optional monochrome retro-phosphor green treatment.
- Subtle scanlines.
- Preferences stored with UserDefaults.

## Requirements

- macOS 13 or newer.
- Screen Recording permission.
- Apple Silicon or Intel Mac capable of running macOS 13.

## Build

Open the package in Xcode and run the `RetroPhosphor` target.

A GitHub Actions workflow is included to build on Apple's hosted macOS runners.

## Legal / attribution

This project is intended to be an independent clean-room implementation. It does not include copied code from a third-party repository.

The name "RetroPhosphor" is used to describe the visual effect; this project is not affiliated with or endorsed by any third-party screen-bending project or by Apple.

## Next steps

The architecture intentionally starts with public APIs and a manual fold control. A future version can add a hardware-specific hinge-angle adapter only after separately reviewing the relevant platform and licensing considerations.
