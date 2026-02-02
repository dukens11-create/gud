# PWA Setup and Deployment

## Live Demo
https://dukens11-create.github.io/gud/

## Install as PWA

### Android (Chrome/Edge)
1. Visit the web app URL
2. Tap menu (⋮)
3. Select "Install app" or "Add to Home Screen"

### iOS (Safari)
1. Visit the web app URL
2. Tap Share button (⎙)
3. Select "Add to Home Screen"

### Desktop (Chrome/Edge)
1. Visit the web app URL
2. Click install icon in address bar
3. App opens in standalone window

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

## Deployment

### Automatic (GitHub Pages)
- Push to main branch
- GitHub Actions builds and deploys automatically
- Live at https://dukens11-create.github.io/gud/

### Manual
```bash
flutter build web --release --base-href /gud/
# Upload build/web/* to your web server
```

## Features
- ✅ Offline support (service worker)
- ✅ Installable on all platforms
- ✅ Responsive design
- ✅ Fast loading
- ✅ No app store required
