# App Icon Requirements for GUD Express

**Last Updated:** February 6, 2026  
**Version:** 1.0

This document outlines all app icon requirements for both Android (Google Play Store) and iOS (Apple App Store) platforms.

---

## Overview

App icons are the first visual representation of your app that users see. They must be:
- **Clear and recognizable** at all sizes
- **Consistent** across all platforms
- **Professional** and high-quality
- **Representative** of the app's purpose
- **Compliant** with platform guidelines

---

## Android (Google Play Store) Icon Requirements

### Primary App Icon

**High-Resolution Icon**
- **Size:** 512×512 pixels
- **Format:** 32-bit PNG
- **Color Space:** RGB
- **Max File Size:** 1 MB
- **Transparency:** Allowed (optional)
- **Purpose:** Used in Play Store listing

**Requirements:**
- Must be square (1:1 aspect ratio)
- Should work well at all sizes (48dp to 512px)
- No rounded corners needed (system applies them)
- Full bleed design (use entire canvas)
- Text should be minimal and legible

**Where It Appears:**
- Google Play Store app listing
- Search results
- App details page
- Installation confirmation
- User's home screen (scaled down)

### Adaptive Icon (Android 8.0+)

**Foreground Layer**
- **Size:** 108×108dp in design
- **Safe Zone:** 66dp diameter circle in center
- **Format:** Vector drawable (XML) or PNG
- **Transparency:** Required (where applicable)

**Background Layer**
- **Size:** 108×108dp in design
- **Format:** Vector drawable (XML) or PNG
- **Can be:** Solid color or gradient
- **No Transparency:** Should be opaque

**Important Notes:**
- System crops icon into various shapes (circle, squircle, rounded square)
- Keep important elements within 66dp safe zone
- Foreground and background layers should work together
- Test with different system shapes
- Avoid placing critical elements near edges

**Implementation Files:**
```
android/app/src/main/res/
├── mipmap-mdpi/ic_launcher.png (48×48px)
├── mipmap-hdpi/ic_launcher.png (72×72px)
├── mipmap-xhdpi/ic_launcher.png (96×96px)
├── mipmap-xxhdpi/ic_launcher.png (144×144px)
├── mipmap-xxxhdpi/ic_launcher.png (192×192px)
└── mipmap-anydpi-v26/
    ├── ic_launcher.xml (adaptive icon config)
    └── ic_launcher_round.xml (round icon variant)
```

### Feature Graphic (Optional but Recommended)

**Dimensions:** 1024×500 pixels
- **Format:** PNG or JPEG
- **Purpose:** Featured placement in Play Store
- **Content:** Showcases app branding, key features
- **No Text:** Avoid critical text (may be covered)
- **Safe Zone:** Keep important content in center 922×450px

**Where It Appears:**
- Play Store banner (featured apps)
- Promotional materials
- Search results (featured)

### Additional Android Assets

**TV Banner (if supporting Android TV)**
- Size: 1280×720 pixels
- Format: PNG
- Purpose: Android TV home screen

**Notification Icon**
- Size: 24×24dp
- Format: PNG (white with transparency)
- Purpose: Status bar notifications

---

## iOS (Apple App Store) Icon Requirements

### App Store Icon

**Primary Icon**
- **Size:** 1024×1024 pixels
- **Format:** PNG
- **Color Space:** RGB
- **No Alpha Channel:** Must be completely opaque
- **No Transparency:** All pixels must be filled
- **Max File Size:** 1 MB
- **Purpose:** App Store listing

**Critical Requirements:**
- Must be exactly 1024×1024 pixels
- Must not include alpha channel
- Must not have transparency
- Must be square with square corners (no pre-rounded corners)
- Must not include Apple Watch, iPhone, or iPad screen in icon
- Must match the icon in your app binary

**Where It Appears:**
- App Store search results
- App detail page
- Featured collections
- Purchase confirmation
- Update notifications

### In-App Icons (Asset Catalog)

iOS requires multiple icon sizes for different devices and contexts. These are managed in Xcode's asset catalog (`Assets.xcassets/AppIcon.appiconset/`).

**iPhone Icons:**
- 120×120px (60@2x) - iPhone home screen
- 180×180px (60@3x) - iPhone home screen (Plus/Pro models)
- 80×80px (40@2x) - Spotlight search
- 120×120px (40@3x) - Spotlight search
- 58×58px (29@2x) - Settings
- 87×87px (29@3x) - Settings

**iPad Icons:**
- 152×152px (76@2x) - iPad home screen
- 167×167px (83.5@2x) - iPad Pro home screen
- 80×80px (40@2x) - Spotlight search
- 58×58px (29@2x) - Settings

**App Store Icon:**
- 1024×1024px (1024@1x) - App Store

**Notification Icons (optional):**
- 40×40px (20@2x)
- 60×60px (20@3x)

**Asset Catalog Configuration:**
```json
{
  "images": [
    {
      "size": "60x60",
      "idiom": "iphone",
      "filename": "Icon-App-60x60@2x.png",
      "scale": "2x"
    },
    {
      "size": "60x60",
      "idiom": "iphone",
      "filename": "Icon-App-60x60@3x.png",
      "scale": "3x"
    },
    // ... more icons
  ]
}
```

### iOS Design Guidelines

**Do:**
- Use simple, recognizable imagery
- Design for various backgrounds (light and dark mode)
- Test at all sizes (from 20px to 1024px)
- Ensure icon works in Spotlight search
- Use a consistent color palette
- Make it memorable and unique

**Don't:**
- Include text (it may be too small to read)
- Use photos or screenshots
- Include UI controls or common glyphs
- Use transparency or alpha channel (App Store icon)
- Add rounded corners (iOS applies them)
- Use iPhone or iPad device frames

---

## Design Guidelines (Both Platforms)

### Universal Design Principles

**1. Simplicity**
- Focus on a single, central element
- Avoid clutter and excessive detail
- Use bold, clear shapes
- Minimize gradients and shadows

**2. Recognizability**
- Should be identifiable at small sizes
- Must stand out among other icons
- Should represent the app's purpose
- Memorable and unique design

**3. Consistency**
- Same design language across platforms
- Consistent color scheme
- Similar visual style (but platform-optimized)
- Recognizable as the same app

**4. Color**
- Use vibrant, eye-catching colors
- Ensure good contrast
- Work on both light and dark backgrounds
- Avoid pure black or white (use dark gray or off-white)
- Limit color palette (2-4 colors maximum)

**5. Typography**
- Avoid text in icons if possible
- If text is necessary, make it large and bold
- Limit to 1-3 characters maximum
- Ensure readability at small sizes

**6. Testing**
- View at actual device sizes (not just design size)
- Test on different backgrounds
- Check in light mode and dark mode
- View alongside competitor icons
- Get feedback from target users

### GUD Express Icon Recommendations

**Concept Ideas:**

**Option 1: Truck Symbol**
- Stylized truck silhouette
- Forward-facing or side view
- Bold, simple lines
- Brand colors: Blue and white or orange

**Option 2: Route/Path**
- Circular route with location pins
- Represents tracking and logistics
- Clean, modern design
- Could incorporate initial "G"

**Option 3: Letter Mark**
- Bold "G" or "GUD" letters
- Geometric, professional style
- Could include subtle truck or route element
- Strong typography-based design

**Option 4: Package/Load**
- Stylized box or package icon
- Motion lines suggesting delivery
- Simple and recognizable
- Represents core functionality

**Recommended Color Schemes:**
1. **Professional Blue:** #1E88E5 (primary) + #FFFFFF (accent)
2. **Logistics Orange:** #FF6F00 (primary) + #263238 (dark)
3. **Modern Green:** #43A047 (primary) + #212121 (dark)
4. **Bold Red:** #D32F2F (primary) + #FFFFFF (accent)

---

## Icon Generation Tools

### Design Tools

**Professional Design Software:**
- Adobe Illustrator (vector design)
- Adobe Photoshop (raster design)
- Figma (collaborative design)
- Sketch (Mac only)
- Affinity Designer (budget-friendly)

**Icon-Specific Tools:**
- App Icon Generator (online)
- Icon Slate (Mac)
- Asset Catalog Creator (Xcode)

### Automated Icon Generators

**Online Tools:**
1. **MakeAppIcon** - https://makeappicon.com
   - Upload 1024×1024 icon
   - Generates all required sizes
   - Both iOS and Android

2. **AppIcon.co** - https://appicon.co
   - Free icon generator
   - Multiple platform support
   - Asset catalog output

3. **Icon Kitchen** - http://icon.kitchen
   - Android adaptive icons
   - Material Design support
   - Foreground/background layers

### Flutter Icon Tools

**flutter_launcher_icons Package:**

Add to `pubspec.yaml`:
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  adaptive_icon_background: "#1E88E5"
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
```

Run:
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

---

## Quality Checklist

### Before Submission

**File Quality:**
- [ ] Correct dimensions (512×512 for Android, 1024×1024 for iOS)
- [ ] Correct format (PNG, 32-bit for Android)
- [ ] No alpha channel for iOS App Store icon
- [ ] File size under 1 MB
- [ ] High resolution and sharp
- [ ] No compression artifacts

**Design Quality:**
- [ ] Clear and recognizable at small sizes
- [ ] Works on light and dark backgrounds
- [ ] No text or minimal text only
- [ ] Follows platform design guidelines
- [ ] Consistent with app branding
- [ ] Professional appearance
- [ ] Unique and memorable

**Platform Compliance:**
- [ ] Android: 512×512 PNG uploaded to Play Console
- [ ] Android: Adaptive icon layers configured
- [ ] iOS: 1024×1024 PNG with no transparency
- [ ] iOS: All device sizes in asset catalog
- [ ] Both: Icon matches in-app design
- [ ] Both: No copyrighted or trademarked content

**Testing:**
- [ ] Viewed at actual device sizes
- [ ] Tested on light mode devices
- [ ] Tested on dark mode devices
- [ ] Checked in app store search results
- [ ] Reviewed on actual devices
- [ ] Feedback collected from team

---

## Implementation Steps

### For Android

1. **Design Icon**
   - Create 512×512 high-res PNG
   - Design adaptive icon layers (108×108dp)

2. **Generate Assets**
   - Use flutter_launcher_icons or manual export
   - Create all required densities (mdpi to xxxhdpi)

3. **Upload to Play Console**
   - Navigate to Store presence > Main store listing
   - Upload 512×512 PNG icon
   - Preview in different contexts

### For iOS

1. **Design Icon**
   - Create 1024×1024 PNG (no transparency)
   - Design must work at all sizes

2. **Add to Xcode**
   - Open ios/Runner.xcworkspace
   - Select Assets.xcassets > AppIcon
   - Drag icon into 1024×1024 slot
   - Xcode generates other sizes automatically

3. **Verify**
   - Build app and check on device
   - Ensure icon appears correctly
   - Test in various contexts (home, spotlight, settings)

---

## Common Mistakes to Avoid

**Design Mistakes:**
- ❌ Too much detail (won't scale down well)
- ❌ Using photos or gradients that lose clarity
- ❌ Including tiny text that becomes illegible
- ❌ Using colors that don't contrast well
- ❌ Creating busy or cluttered designs

**Technical Mistakes:**
- ❌ Wrong dimensions or aspect ratio
- ❌ Including alpha channel for iOS
- ❌ Low resolution or pixelation
- ❌ Wrong file format (JPEG instead of PNG)
- ❌ Forgetting to test on actual devices

**Platform-Specific Mistakes:**
- ❌ Android: Not considering adaptive icon safe zone
- ❌ Android: Not providing adaptive icon layers
- ❌ iOS: Including pre-rounded corners
- ❌ iOS: Using transparency in App Store icon
- ❌ Both: Icons don't match between platforms

---

## Resources

### Official Guidelines

**Apple:**
- Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/app-icons
- App Icon Requirements: https://developer.apple.com/design/human-interface-guidelines/app-icons#Specifications

**Google:**
- Material Design Icons: https://material.io/design/iconography/product-icons.html
- Adaptive Icons: https://developer.android.com/guide/practices/ui_guidelines/icon_design_adaptive
- Play Store Asset Requirements: https://support.google.com/googleplay/android-developer/answer/9866151

### Design Inspiration

- Dribbble (Mobile App Icons): https://dribbble.com/tags/app-icon
- Behance (Icon Design): https://www.behance.net/search/projects?search=app%20icon
- App Icon Gallery: https://www.appicon.gallery/

### Testing Tools

- **iOS:** Test on various iOS devices and simulators
- **Android:** Test on devices with different icon shapes
- **Both:** View in app store search results before launch

---

## Contact & Support

For design questions or icon creation assistance:

**Email:** support@gudexpress.com  
**Design Team:** design@gudexpress.com

**Icon Approval:**
All icons must be approved by design lead and product manager before submission to app stores.

---

**Document Version:** 1.0  
**Last Updated:** February 6, 2026  
**Prepared By:** GUD Express Team
