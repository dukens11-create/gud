# PWA Setup and Deployment

## Live Demo
**🚀 Try it now:** https://dukens11-create.github.io/gud/

This demo requires Firebase authentication to be configured.

## Authentication

**Production Ready:**
- Demo credentials have been removed for security
- Set up Firebase Authentication for your deployment
- Create test accounts through Firebase Console if needed

## Install as PWA

### Android (Chrome/Edge)
1. Visit the web app URL
2. Tap menu (⋮)
3. Select "Install app" or "Add to Home Screen"
4. App appears on home screen like a native app

### iOS (Safari)
1. Visit the web app URL
2. Tap Share button (⎙)
3. Select "Add to Home Screen"
4. Tap "Add"
5. Launch from home screen

### Desktop (Chrome/Edge/Firefox)
1. Visit the web app URL
2. Click install icon (⊕) in address bar
3. Click "Install"
4. App opens in standalone window

## Local Development

### Build for web
```bash
flutter build web --release
```

### Test locally
```bash
cd build/web
python3 -m http.server 8000
# Visit http://localhost:8000
```

Or use Flutter's built-in web server:
```bash
flutter run -d chrome
```

## Deployment

### Automatic (GitHub Pages)
The repository includes a GitHub Actions workflow that automatically:
- Builds the web app on push to main
- Deploys to GitHub Pages
- Available at https://dukens11-create.github.io/gud/

### Enabling GitHub Pages
1. Go to repository Settings
2. Navigate to "Pages" section
3. Source: GitHub Actions
4. The workflow will deploy on next push to main

### Manual Deployment
```bash
flutter build web --release --base-href /gud/
# Upload build/web/* to your web server
```

## PWA Features
- ✅ Offline support (service worker)
- ✅ Installable on all platforms
- ✅ Responsive design
- ✅ Fast loading (cached assets)
- ✅ No app store required
- ✅ Works without backend (demo mode)

## Troubleshooting

### PWA not installing
- Ensure you're using HTTPS (GitHub Pages provides this)
- Check that manifest.json is accessible
- Verify service worker is registered (check browser console)

### Build fails
```bash
flutter clean
flutter pub get
flutter build web --release
```

### App shows blank screen
- Check browser console for errors
- Verify base-href matches deployment path
- Clear browser cache and reload
