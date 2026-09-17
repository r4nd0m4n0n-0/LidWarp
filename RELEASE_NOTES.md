# LidWarp v1.0.0

## Initial Release

LidWarp is a macOS menu bar application that creates a live screen-bending visual illusion with optional retro CRT/phosphor effects.

## Features

- Live desktop capture
- Transparent click-through overlay
- Manual fold simulation
- Automatic fold animation
- Adjustable fold speed
- Retro phosphor-green effect
- CRT glow
- CRT vignette
- Scanlines
- Master effect intensity
- Reset Fold
- Reset Visual Settings
- Screen Recording permission handling
- Persistent settings
- Automated rendering tests
- Automated visual-effect tests
- GitHub Actions macOS build
- macOS application bundle
- Ad-hoc code signing
- Release ZIP packaging

## Requirements

- macOS 13 or newer
- Screen Recording permission

## Installation

1. Download `LidWarp-macOS.zip`.
2. Extract the archive.
3. Move `LidWarp.app` to the Applications folder.
4. Launch LidWarp.
5. Grant Screen Recording permission when requested.

## Important

This release provides a software-based visual simulation.

It does not communicate with or control a physical laptop hinge.

## Build Verification

The release is produced by the repository's GitHub Actions macOS build workflow.

The workflow builds the application, runs automated tests, generates render previews, creates the application bundle, signs it ad-hoc, verifies the signature, and packages the final ZIP.

## Signing

This release is ad-hoc signed.

It is not Developer ID signed and is not notarized by Apple.
