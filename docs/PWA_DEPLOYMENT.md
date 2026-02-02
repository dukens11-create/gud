# PWA Deployment Guide

This guide explains how to deploy the GUD Express Flutter app as a Progressive Web App (PWA) to GitHub Pages.

## Prerequisites

- Flutter SDK 3.0.0 or higher installed
- Access to the GitHub repository with push permissions
- GitHub Pages enabled in repository settings

## Automatic Deployment via GitHub Actions

The repository includes an automated deployment workflow that builds and deploys the web app to GitHub Pages whenever changes are pushed to the `main` branch.

### Enable GitHub Pages

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Pages**
3. Under **Source**, select **GitHub Actions**
4. The workflow will automatically deploy on the next push to `main`

### Workflow Configuration

The deployment workflow (`.github/workflows/web-deploy.yml`) performs the following steps:

1. Checks out the code
2. Sets up Flutter 3.24.0
3. Installs dependencies with `flutter pub get`
4. Builds the web app with `flutter build web --release --base-href /gud/`
5. Uploads the build artifacts
6. Deploys to GitHub Pages

**Important**: The `--base-href /gud/` flag must match your repository name. If your repository has a different name, update this in the workflow file.

## Manual Deployment

If you prefer to deploy manually, follow these steps:

### 1. Build the Web App Locally

```bash
# Navigate to the project directory
cd /path/to/gud

# Get dependencies
flutter pub get

# Build for web (adjust base-href to match your repo name)
flutter build web --release --base-href /gud/
```

The output will be in the `build/web/` directory.

### 2. Deploy to GitHub Pages

#### Option A: Using GitHub CLI

```bash
# Create a gh-pages branch if it doesn't exist
git checkout --orphan gh-pages
git rm -rf .
cp -r build/web/* .
git add .
git commit -m "Deploy web app"
git push origin gh-pages --force
```

#### Option B: Manual Upload

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Pages**
3. Select **Deploy from a branch** under Source
4. Select the `gh-pages` branch and `/ (root)` folder
5. Upload the contents of `build/web/` to the `gh-pages` branch

## Testing the PWA

After deployment, your app will be available at:
```
https://dukens11-create.github.io/gud/
```

### Install as PWA on Mobile Devices

#### Android/Chrome
1. Visit the web app URL in Chrome
2. Tap the menu (⋮) in the top-right
3. Select **"Install app"** or **"Add to Home Screen"**
4. The app will be added to your home screen like a native app

#### iOS/Safari
1. Visit the web app URL in Safari
2. Tap the Share button (⎙)
3. Scroll down and select **"Add to Home Screen"**
4. Tap **"Add"** in the top-right
5. The app will appear on your home screen

### Install on Desktop

#### Chrome/Edge
1. Visit the web app URL
2. Look for the install icon (⊕) in the address bar
3. Click it and select **"Install"**
4. The PWA will open in its own window

## Offline Capabilities

The PWA includes a service worker that caches assets for offline use. After the first visit:

- The app shell loads instantly, even offline
- Previously viewed data remains accessible
- The demo version works fully offline as it uses mock data
- Firebase version requires an initial online connection to fetch data

## Updating the App

The service worker automatically updates when new content is deployed. Users will see the updates on their next visit after the cache expires.

### Force Update

To force users to update immediately:

1. Update the `serviceWorkerVersion` in `web/index.html`
2. Rebuild and redeploy

## Troubleshooting

### Base Href Issues

If the app loads but shows a blank page or routing errors:

1. Verify the `--base-href` matches your repository name
2. Rebuild with the correct base href:
   ```bash
   flutter build web --release --base-href /your-repo-name/
   ```

### Service Worker Not Registering

1. Ensure you're accessing the site via HTTPS (GitHub Pages uses HTTPS)
2. Check browser console for service worker errors
3. Clear cache and reload

### Icons Not Appearing

1. Verify icon files exist in `web/icons/`
2. Check the paths in `web/manifest.json`
3. Clear browser cache and reload

### Firebase Configuration

For the production version with Firebase:

1. Add Firebase web configuration to `web/index.html`
2. Update Firebase settings in the Firebase Console
3. Add the domain to authorized domains in Firebase Authentication

## Performance Optimization

### Reduce Bundle Size

```bash
# Build with tree shaking and minification
flutter build web --release --tree-shake-icons
```

### Enable Compression

GitHub Pages automatically serves files with gzip compression, but you can pre-compress for better performance:

```bash
# Install gzip
apt-get install gzip

# Compress JavaScript files
find build/web -name "*.js" -exec gzip -k {} \;
```

## Custom Domain

To use a custom domain:

1. Go to **Settings** → **Pages**
2. Enter your custom domain
3. Add a `CNAME` file to the `gh-pages` branch with your domain
4. Configure DNS settings with your domain provider

## Monitoring

Monitor your PWA using:

- **Chrome DevTools**: Application tab → Service Workers
- **Lighthouse**: Run audits for PWA, Performance, SEO
- **GitHub Actions**: Check workflow runs for deployment status

## Support

For issues or questions:
- Check GitHub Actions logs for deployment errors
- Review browser console for runtime errors
- Create an issue in the repository
