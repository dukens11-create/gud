# GitHub Pages Setup Guide for GUD Express PWA

## 🚀 Automatic Setup (Recommended)

The GitHub Actions workflow will automatically enable GitHub Pages on the first successful run using the `enablement: true` parameter. No manual configuration needed!

## 📋 Manual Setup (Alternative)

If you prefer to enable Pages manually or if automatic setup fails:

1. **Go to Repository Settings:**
   - Navigate to: https://github.com/dukens11-create/gud/settings/pages

2. **Configure Build and Deployment:**
   - Under "Build and deployment" section
   - Find the "Source" dropdown
   - Select: **"GitHub Actions"**
   - Click: **"Save"**

3. **Trigger Deployment:**
   - Go to: https://github.com/dukens11-create/gud/actions
   - Click "Deploy to GitHub Pages" workflow
   - Click "Run workflow" → Select "main" branch → Click "Run workflow"

## ✅ Verify Setup

After the workflow runs successfully:

1. Go to: https://github.com/dukens11-create/gud/settings/pages
2. You should see: 
   ```
   ✅ Your site is live at https://dukens11-create.github.io/gud/
   ```

## 📱 Install the PWA

### Android (Chrome/Edge/Samsung Internet)

1. Visit: https://dukens11-create.github.io/gud/
2. Tap menu (⋮) in the top right
3. Select **"Install app"** or **"Add to Home Screen"**
4. Tap **"Install"** in the popup
5. The app icon appears on your home screen! 🎉

### iOS (iPhone/iPad - Safari)

1. Visit: https://dukens11-create.github.io/gud/
2. Tap the **Share button** (⎙) at the bottom
3. Scroll down and tap **"Add to Home Screen"**
4. Edit the name if desired (default: "GUD Express")
5. Tap **"Add"** in the top right
6. The app icon appears on your home screen! 🎉

### Desktop (Windows/Mac/Linux - Chrome/Edge)

1. Visit: https://dukens11-create.github.io/gud/
2. Look for the **install icon** (⊕) in the address bar (right side)
3. Click the install icon
4. Click **"Install"** in the popup
5. The app opens in its own window! 🎉

**Alternative Desktop Method:**
- Click the menu (⋮) → Select **"Install GUD Express"**

## 🎯 PWA Features

Once installed, your GUD Express PWA offers:

- ✅ **Offline Support** - Works without internet after first visit
- ✅ **Fast Loading** - Cached assets load instantly
- ✅ **Installable** - Add to home screen on any device
- ✅ **Automatic Updates** - Updates when you deploy new versions
- ✅ **No App Store** - No need for Google Play or App Store
- ✅ **Cross-Platform** - Works on Android, iOS, Windows, Mac, Linux

## 🔧 Troubleshooting

### 404 Error When Accessing the Site

**Symptoms:** Visiting the URL shows "404 Page Not Found"

**Solutions:**
1. **Wait for DNS propagation** - After deployment, wait 1-2 minutes
2. **Check workflow status** - Ensure the workflow has a green checkmark ✅
3. **Clear browser cache** - Hard refresh: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)
4. **Verify Pages is enabled** - Check Settings → Pages shows "GitHub Actions"

### Workflow Fails with "Not Found" Error

**Symptoms:** Build succeeds but deployment fails

**Solutions:**
1. **Enable Pages manually** - Follow the "Manual Setup" steps above
2. **Check repository permissions** - Ensure Actions have write permissions
3. **Re-run workflow** - Go to Actions tab and click "Re-run failed jobs"

### PWA Not Showing Install Prompt

**Symptoms:** No install icon appears in the browser

**Solutions:**
1. **Use supported browser** - Chrome, Edge, or Safari
2. **Visit via HTTPS** - GitHub Pages uses HTTPS automatically
3. **Check manifest** - View browser console for manifest errors
4. **Already installed?** - Check if the app is already installed

### Changes Not Appearing After Update

**Symptoms:** Old version of the app is still showing

**Solutions:**
1. **Uninstall and reinstall** - Remove the PWA and install again
2. **Clear service worker** - Browser DevTools → Application → Clear storage
3. **Hard refresh** - Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)

## 📊 Monitoring

### Check Deployment Status

1. **Actions Tab:** https://github.com/dukens11-create/gud/actions
   - View all workflow runs
   - Check for failures or warnings

2. **Pages Settings:** https://github.com/dukens11-create/gud/settings/pages
   - See current deployment status
   - View deployment history

### Testing the PWA

Use these tools to verify PWA functionality:

1. **Chrome DevTools:**
   - Open: F12 or Right-click → Inspect
   - Go to: Application tab → Service Workers
   - Verify service worker is registered and running

2. **Lighthouse:**
   - Open Chrome DevTools
   - Go to: Lighthouse tab
   - Run audit for: PWA, Performance, Accessibility, SEO
   - Aim for 90+ scores

## 🔄 Updating the PWA

When you push changes to the main branch:

1. GitHub Actions automatically builds and deploys
2. Service worker updates in the background
3. Users see updates on their next visit
4. No action required from users!

## 📞 Support

For issues or questions:

1. **Check documentation** - README.md and this guide
2. **Review workflow logs** - Actions tab for detailed errors
3. **Create an issue** - https://github.com/dukens11-create/gud/issues
4. **Contact maintainer** - Via GitHub issues

## 🎓 Additional Resources

- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [Progressive Web Apps (MDN)](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps)
- [Flutter Web Documentation](https://docs.flutter.dev/platform-integration/web)
- [Service Workers (MDN)](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API)

---

**Last Updated:** February 2, 2026
**Maintained By:** dukens11-create
