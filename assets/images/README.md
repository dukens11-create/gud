# GUD Express Logo Assets

This directory contains the official GUD Express logo and branding assets.

## Files

- **logo.svg** - Vector source file of the GUD Express logo (512x512)
- **logo.png** - PNG version of the logo for use in the Flutter app (512x512)

## Logo Design

The GUD Express logo features:
- Solid royal blue background (#2654C1)
- White "GUD" text in large, bold, stylized font with italic appearance
- Orange "Express" text (#FFA500) in cursive/script style positioned below and to the right of "GUD"
- Text-only design on blue background, no icons or graphics
- Clean, modern design suitable for all platforms

## Usage in Flutter App

The logo is used in the following locations:

### In-App Usage
- **Login Screen** (`lib/screens/login_screen.dart`) - Displays the logo prominently on the login page
- **Settings Screen** (`lib/screens/settings_screen.dart`) - Shows in the About dialog

### Platform Icons

#### Web
- `web/favicon.png` (48x48)
- `web/icons/icon-192.png` (192x192)
- `web/icons/icon-512.png` (512x512)
- Referenced in `web/manifest.json` and `web/index.html`

#### Android
App icons generated for all density buckets:
- `mipmap-mdpi/ic_launcher.png` (48x48)
- `mipmap-hdpi/ic_launcher.png` (72x72)
- `mipmap-xhdpi/ic_launcher.png` (96x96)
- `mipmap-xxhdpi/ic_launcher.png` (144x144)
- `mipmap-xxxhdpi/ic_launcher.png` (192x192)

Referenced in `android/app/src/main/AndroidManifest.xml` as `@mipmap/ic_launcher`

#### iOS
App icons generated for all required sizes (15 files total):
- Various sizes from 20x20 to 1024x1024 for different iOS devices and contexts
- Located in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- Configured via `Contents.json` in the same directory

## Regenerating Icons

If the logo needs to be updated, modify `logo.svg` and then regenerate all platform icons:

### Linux (Ubuntu/Debian)
```bash
# Install required tools
sudo apt-get install imagemagick librsvg2-bin
```

### macOS
```bash
# Install required tools via Homebrew
brew install imagemagick librsvg
```

### Windows
```powershell
# Install via Chocolatey
choco install imagemagick rsvg-convert

# Or download installers:
# - ImageMagick: https://imagemagick.org/script/download.php
# - librsvg: https://github.com/miyako/console-rsvg-convert
```

### Regenerate All Icons
```bash
# Run from repository root after installing tools

# Web icons
rsvg-convert -w 192 -h 192 assets/images/logo.svg -o web/icons/icon-192.png
rsvg-convert -w 512 -h 512 assets/images/logo.svg -o web/icons/icon-512.png
rsvg-convert -w 48 -h 48 assets/images/logo.svg -o web/favicon.png

# App PNG
rsvg-convert -w 512 -h 512 assets/images/logo.svg -o assets/images/logo.png

# Android (see deployment docs for full commands)
# iOS (see deployment docs for full commands)
```

## Notes

- All icons are generated from the SVG source to ensure consistency
- The logo uses transparency (RGBA) for proper rendering on different backgrounds
- Web manifest and HTML files are already configured to reference these icons
- Platform-specific icon configurations are already set up in Android and iOS projects
