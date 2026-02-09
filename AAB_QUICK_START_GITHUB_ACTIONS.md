# Quick Start: GitHub Actions AAB Build

This is a quick reference guide for setting up and using the GitHub Actions workflow to build Android App Bundles (AAB) for GUD Express.

## 🚀 5-Minute Setup

### 1️⃣ Generate Keystore (One-time)

```bash
cd android/app
keytool -genkey -v -keystore gud_keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias gud_key
```

**Save these:**
- Keystore password
- Key password
- Key alias: `gud_key`

### 2️⃣ Encode Keystore to Base64

```bash
# Linux/Mac
base64 android/app/gud_keystore.jks > keystore_base64.txt

# Windows PowerShell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android\app\gud_keystore.jks")) | Out-File keystore_base64.txt
```

### 3️⃣ Add GitHub Secrets

Go to: **Repository Settings → Secrets and variables → Actions**

Add these 4 secrets:

| Secret Name | Value |
|------------|-------|
| `KEYSTORE_BASE64` | Contents of `keystore_base64.txt` |
| `KEYSTORE_PASSWORD` | Your keystore password |
| `KEY_PASSWORD` | Your key password |
| `KEY_ALIAS` | `gud_key` |

### 4️⃣ Delete Sensitive Files

```bash
rm keystore_base64.txt
# Keep gud_keystore.jks in a secure backup location
```

## 🎯 Usage

### Option A: Manual Build

1. Go to **Actions** tab
2. Select **Build Android App Bundle (AAB)**
3. Click **Run workflow**
4. Wait for completion (~5-10 minutes)
5. Download AAB from **Artifacts**

### Option B: Tag-based Build

```bash
git tag v2.1.0
git push origin v2.1.0
```

The workflow automatically:
- ✅ Builds signed AAB
- ✅ Uploads as artifact
- ✅ Attaches to GitHub release

## 📥 Download Built AAB

**From Actions:**
1. Actions tab → Completed workflow run
2. Scroll to **Artifacts** section
3. Download `gud-express-aab-{number}-v{version}`

**From Releases (for tagged builds):**
1. Releases tab → Find your version
2. Download `app-release.aab` from Assets

## 📤 Upload to Google Play Console

1. Go to https://play.google.com/console
2. Select GUD Express app
3. **Production** → **Create new release**
4. Upload `app-release.aab`
5. Upload `mapping.txt` (for crash reports)
6. Add release notes
7. **Review** → **Start rollout to Production**

## 🔧 Troubleshooting

### Build Fails with "Keystore not found"
- ✅ Check all 4 secrets are added correctly
- ✅ Verify KEYSTORE_BASE64 contains the full base64 string
- ✅ Ensure no extra spaces in secret values

### Build Fails with "Wrong password"
- ✅ Verify KEYSTORE_PASSWORD is correct
- ✅ Verify KEY_PASSWORD is correct
- ✅ Check KEY_ALIAS matches your keystore alias

### AAB is too large
- ✅ Enable ProGuard/R8 optimization (already enabled)
- ✅ Use `--split-per-abi` for multiple APKs
- ✅ Remove unused dependencies

### Can't download artifact
- ✅ Artifacts expire after 30 days
- ✅ Re-run the workflow if expired
- ✅ Check you're logged into GitHub

## 📚 Full Documentation

For detailed information, see:
- **[GITHUB_ACTIONS_AAB_GUIDE.md](GITHUB_ACTIONS_AAB_GUIDE.md)** - Complete setup guide
- **[AAB_BUILD_GUIDE.md](AAB_BUILD_GUIDE.md)** - Local build instructions

## 🎓 Key Features

✅ **Automated Builds** - Push tag and get AAB automatically  
✅ **Secure Signing** - Encrypted GitHub Secrets  
✅ **Fast Builds** - Dependency caching saves 2-3 minutes  
✅ **Release Integration** - Auto-attach to GitHub releases  
✅ **Crash Analysis** - ProGuard mapping file included  
✅ **Build History** - 30-day artifact retention  

## ⚡ Pro Tips

1. **Version Tags**: Always use semantic versioning (v2.1.0)
2. **Test First**: Run tests locally before pushing tags
3. **Backup Keystore**: Store in a secure location (not in git)
4. **Monitor Builds**: Check Actions tab for build status
5. **Update Regularly**: Keep Flutter and dependencies up to date

## 🆘 Need Help?

1. Check [Troubleshooting section](#-troubleshooting)
2. Review [GITHUB_ACTIONS_AAB_GUIDE.md](GITHUB_ACTIONS_AAB_GUIDE.md)
3. Check workflow logs in Actions tab
4. Open an issue with error details

---

**Ready to build?** Go to the **Actions** tab and click **Run workflow**! 🚀
