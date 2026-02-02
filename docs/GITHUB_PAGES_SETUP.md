# GitHub Pages Setup Guide

## Automatic Setup (Recommended)

The workflow will automatically enable GitHub Pages on the first run with the `enablement: true` parameter.

## Manual Setup (If Needed)

If you prefer to enable Pages manually:

1. Go to: https://github.com/dukens11-create/gud/settings/pages
2. Under "Build and deployment" → "Source"
3. Select: **"GitHub Actions"**
4. Click: **"Save"**

## Verify Setup

After the workflow runs successfully:

1. Go to: https://github.com/dukens11-create/gud/settings/pages
2. You should see: "Your site is live at https://dukens11-create.github.io/gud/"

## Install the PWA

### Mobile (Android/iOS)
1. Visit: https://dukens11-create.github.io/gud/
2. Tap "Add to Home Screen" or "Install app"

### Desktop (Chrome/Edge)
1. Visit: https://dukens11-create.github.io/gud/
2. Click the install icon in the address bar

## Troubleshooting

### 404 Error
- Wait 1-2 minutes after deployment for DNS propagation
- Check that workflow completed successfully (green checkmark)
- Clear browser cache and reload

### Workflow Fails
- Ensure repository has Actions enabled
- Check workflow logs for specific errors
- Verify Flutter version compatibility

## Support

For issues, create an issue at: https://github.com/dukens11-create/gud/issues
