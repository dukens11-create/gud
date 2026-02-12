# 🚀 Firestore Index Quick Start Guide

**Get your Firestore indexes deployed in under 2 minutes!**

---

## ⚡ Quick Deploy (One Command)

Run this script from your project root:

```bash
bash scripts/deploy-indexes.sh
```

That's it! The script will:
- ✅ Check if Firebase CLI is installed
- ✅ Verify you're logged in to Firebase
- ✅ Deploy all indexes from `firestore.indexes.json`
- ✅ Show deployment status

---

## 📋 Step-by-Step Instructions

### 1️⃣ Prerequisites

Make sure you have Firebase CLI installed:

```bash
# Check if installed
firebase --version

# If not installed, install it
npm install -g firebase-tools
```

### 2️⃣ Login to Firebase

If you haven't logged in yet:

```bash
firebase login
```

This will open a browser window for authentication.

### 3️⃣ Deploy Indexes

Run the deployment script:

```bash
bash scripts/deploy-indexes.sh
```

Or deploy manually:

```bash
firebase deploy --only firestore:indexes
```

### 4️⃣ Wait for Index Build

- ⏱️ **Small databases**: 2-5 minutes
- ⏱️ **Large databases**: 10-30+ minutes

Check index status at:
👉 https://console.firebase.google.com/project/YOUR_PROJECT_ID/firestore/indexes

---

## 🔧 Troubleshooting

### ❌ "Firebase CLI not found"

**Solution**: Install Firebase CLI globally

```bash
npm install -g firebase-tools
```

### ❌ "Not authorized" or "Login required"

**Solution**: Log in to Firebase

```bash
firebase login
```

If you're already logged in, try logging out and back in:

```bash
firebase logout
firebase login
```

### ❌ "No project ID found"

**Solution**: Initialize Firebase or specify project

```bash
# Initialize Firebase (if not done)
firebase init

# Or specify project explicitly
firebase use YOUR_PROJECT_ID
```

### ❌ "Permission denied" when running script

**Solution**: Make the script executable

```bash
chmod +x scripts/deploy-indexes.sh
```

### ⚠️ Deployment succeeds but app still shows "Index Required" error

**Possible causes**:

1. **Index is still building** ⏳
   - Wait a few more minutes
   - Check status in Firebase Console

2. **Wrong Firebase project** 🎯
   - Verify you deployed to the correct project
   - Run: `firebase projects:list`
   - Run: `firebase use YOUR_PROJECT_ID`

3. **App is using cached data** 🔄
   - Restart your app
   - Clear app cache
   - Force refresh the app

---

## 📚 Need More Details?

For comprehensive information about:
- Index configuration
- Query patterns
- Manual index creation
- Advanced troubleshooting

See the detailed documentation:
👉 [FIRESTORE_INDEX_SETUP.md](FIRESTORE_INDEX_SETUP.md)

---

## 🆘 Still Having Issues?

1. Check the [Troubleshooting Guide](TROUBLESHOOTING.md)
2. Review [FIRESTORE_INDEX_SETUP.md](FIRESTORE_INDEX_SETUP.md)
3. Check Firebase Console for specific error messages
4. Open an issue on GitHub with:
   - Error message
   - Output from `firebase --version`
   - Output from `firebase projects:list`

---

## 💡 Pro Tips

- **Always deploy indexes before deploying code** that uses new queries
- **Test queries in development** before deploying to production
- **Monitor index usage** in Firebase Console to identify unused indexes
- **Use the deployment script** for consistency across team members
- **Keep `firestore.indexes.json` in version control** to track changes

---

## 🔗 Quick Links

- 🔥 [Firebase Console](https://console.firebase.google.com)
- 📖 [Firebase CLI Documentation](https://firebase.google.com/docs/cli)
- 📚 [Firestore Index Documentation](https://firebase.google.com/docs/firestore/query-data/indexing)
- 🎯 [Project Documentation](FIRESTORE_INDEX_SETUP.md)
