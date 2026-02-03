# Render.com Deployment Guide for GUD Express

## 🚀 Quick Deploy to Render

### Prerequisites
- Render.com account (free tier available)
- GitHub repository access

---

## Automatic Deployment Setup

### Step 1: Connect Repository to Render

1. Go to [Render Dashboard](https://dashboard.render.com/)
2. Click **"New +"** → **"Static Site"**
3. Connect your GitHub account if not already connected
4. Select the `dukens11-create/gud` repository
5. Configure the deployment:

**Settings:**
- **Name:** `gud-express`
- **Branch:** `main`
- **Build Command:** `./render-build.sh`
- **Publish Directory:** `build/web`
- **Auto-Deploy:** Yes (recommended)

6. Click **"Create Static Site"**

### Step 2: Wait for Initial Build

- First build takes ~5-10 minutes (installs Flutter)
- Subsequent builds are faster (~2-3 minutes)
- Monitor build progress in Render dashboard

### Step 3: Access Your App

After deployment completes:
- Your app will be live at: `https://gud-express.onrender.com`
- Or your custom domain if configured

---

## Environment Variables (Optional)

If you need to configure Firebase or other services:

1. In Render dashboard, go to your service
2. Click **"Environment"** tab
3. Add variables:
   - `FIREBASE_API_KEY` (if needed for public config)
   - `FIREBASE_PROJECT_ID`
   - Any other public configuration

**Note:** Never add sensitive secrets here for client-side web apps!

---

## Custom Domain Setup

### Using Render Custom Domain

1. In Render dashboard, go to your service
2. Click **"Settings"** tab
3. Scroll to **"Custom Domains"**
4. Click **"Add Custom Domain"**
5. Enter your domain (e.g., `gudexpress.com`)
6. Follow DNS configuration instructions
7. Render provides free SSL certificates

### DNS Configuration Example

Add these DNS records to your domain:
```
Type: CNAME
Name: www (or @)
Value: gud-express.onrender.com
```

---

## Deployment Features

✅ **Automatic deployments** from GitHub pushes  
✅ **Free SSL certificates** (HTTPS)  
✅ **CDN-backed hosting** (fast global delivery)  
✅ **Automatic builds** on git push  
✅ **Custom domains** supported  
✅ **Branch deploys** (preview deployments)  
✅ **Build logs** and monitoring  

---

## Manual Deployment

If you need to manually trigger a deployment:

1. Go to Render dashboard
2. Select your service
3. Click **"Manual Deploy"** dropdown
4. Select **"Deploy latest commit"**
5. Or select **"Clear build cache & deploy"** for clean build

---

## Troubleshooting

### Build Fails

**Problem:** Flutter installation fails
**Solution:** Check build logs, ensure `render-build.sh` is executable

**Problem:** Build timeout
**Solution:** Render free tier has 15-minute build limit. Optimize by caching Flutter SDK.

### App Doesn't Load

**Problem:** White screen or "Failed to load"
**Solution:** 
1. Check browser console for errors
2. Verify Firebase configuration is correct
3. Ensure base href is set correctly for Render

### Firebase Not Working

**Problem:** Firebase initialization fails
**Solution:**
1. Verify Firebase config in `lib/firebase_options.dart`
2. Check Firebase project settings allow your Render domain
3. Add Render domain to Firebase authorized domains:
   - Firebase Console → Authentication → Settings → Authorized domains
   - Add: `gud-express.onrender.com`

---

## Comparison: Render vs GitHub Pages

| Feature | Render | GitHub Pages |
|---------|--------|--------------|
| Custom domain | ✅ Free SSL | ✅ Free SSL |
| Build time | 5-10 min | 2-3 min |
| Deploy trigger | Git push | Git push |
| Cost | Free tier available | Free |
| CDN | ✅ Built-in | ✅ Built-in |
| Build customization | ✅ Full control | ❌ Limited |
| Environment variables | ✅ Yes | ❌ No |
| Server-side routing | ✅ Yes | ⚠️ Client-side only |

---

## Cost

Render Free Tier includes:
- ✅ 750 hours/month of runtime (static sites don't use runtime)
- ✅ 100 GB bandwidth/month
- ✅ Automatic SSL
- ✅ Unlimited static sites

**For GUD Express:** Free tier is sufficient for testing and moderate traffic.

---

## Monitoring

### View Deployment Status
1. Render Dashboard → Your Service
2. Check **"Events"** tab for deployment history
3. View **"Logs"** tab for build/runtime logs

### Analytics
- Render provides basic traffic analytics
- For detailed analytics, integrate Google Analytics in your Flutter app

---

## Continuous Deployment Workflow

Once set up:
1. ✅ Push code to `main` branch
2. ✅ GitHub triggers Render webhook
3. ✅ Render builds Flutter web app
4. ✅ Render deploys to CDN
5. ✅ App is live at `https://gud-express.onrender.com`

**No manual intervention required!**

---

## Support Resources

- [Render Documentation](https://render.com/docs/static-sites)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- [Render Community](https://community.render.com/)

---

## Quick Links

- **Render Dashboard:** https://dashboard.render.com/
- **Build Logs:** https://dashboard.render.com/static/[your-service-id]/logs
- **Your Live App:** https://gud-express.onrender.com (after deployment)

---

**Happy Deploying! 🚀**
