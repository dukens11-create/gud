#!/usr/bin/env node
/**
 * Load-Driver UID Auto-Fix Script
 * 
 * This script automatically fixes loads where the `driverId` field doesn't match
 * any Firebase Authentication UID. It attempts to match loads to drivers by name
 * and updates the driverId to the correct Firebase Auth UID.
 * 
 * Usage:
 *   node scripts/fix_load_driver_ids.js
 * 
 * Prerequisites:
 *   - Node.js installed
 *   - Firebase Admin SDK configured
 *   - Service account key file at ./scripts/gud-express-firebase-adminsdk.json
 *     OR set GOOGLE_APPLICATION_CREDENTIALS environment variable
 *   - Run diagnose_load_driver_mismatch.js first to identify issues
 * 
 * Setup:
 *   cd functions && npm install
 *   # Download service account key from Firebase Console and save to scripts/
 * 
 * Safety:
 *   - Uses Firestore batched writes for atomic updates
 *   - Updates both driverId and driverName to ensure consistency
 *   - Only updates loads where driver can be matched by name
 *   - Skips loads that already have valid driverId
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
let serviceAccount;
try {
  // Try to load service account from scripts directory
  serviceAccount = require('./gud-express-firebase-adminsdk.json');
} catch (e1) {
  try {
    // Try to load from project root
    serviceAccount = require('../serviceAccountKey.json');
  } catch (e2) {
    console.log('⚠️  Service account key not found.');
    console.log('   Expected locations:');
    console.log('   1. ./scripts/gud-express-firebase-adminsdk.json');
    console.log('   2. ./serviceAccountKey.json');
    console.log('   3. Set GOOGLE_APPLICATION_CREDENTIALS environment variable');
    console.log('\n   Download from: Firebase Console > Project Settings > Service Accounts');
    process.exit(1);
  }
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function fixDriverIds() {
  console.log('🔧 Fixing load driverId mismatches...\n');
  
  try {
    // Get all loads
    const loadsSnapshot = await db.collection('loads').get();
    
    // Get all drivers
    const driversSnapshot = await db.collection('drivers').get();
    const driversByName = {};
    const driversById = {};
    
    driversSnapshot.forEach(doc => {
      const data = doc.data();
      const uid = doc.id;
      driversById[uid] = data;
      driversByName[data.name.toLowerCase()] = { uid, ...data };
    });
    
    console.log(`👥 Loaded ${driversSnapshot.size} drivers\n`);
    
    let fixedCount = 0;
    let skippedCount = 0;
    const batch = db.batch();
    
    for (const loadDoc of loadsSnapshot.docs) {
      const load = loadDoc.data();
      const loadRef = loadDoc.ref;
      
      // Check if driverId is valid (matches a driver UID)
      if (driversById[load.driverId]) {
        console.log(`✅ ${load.loadNumber}: driverId already correct`);
        skippedCount++;
        continue;
      }
      
      // Try to find correct driver by name
      const driverName = (load.driverName || load.driverId || '').toLowerCase();
      const matchingDriver = driversByName[driverName];
      
      if (matchingDriver) {
        console.log(`🔧 ${load.loadNumber}: Fixing driverId`);
        console.log(`   From: "${load.driverId}"`);
        console.log(`   To:   "${matchingDriver.uid}" (${matchingDriver.name})`);
        
        batch.update(loadRef, {
          driverId: matchingDriver.uid,
          driverName: matchingDriver.name // Ensure driverName is also correct
        });
        
        fixedCount++;
      } else {
        console.log(`⚠️  ${load.loadNumber}: Cannot find matching driver for "${load.driverId}"`);
      }
    }
    
    if (fixedCount > 0) {
      console.log(`\n💾 Committing ${fixedCount} update(s) to Firestore...`);
      await batch.commit();
      console.log(`✅ Successfully fixed ${fixedCount} load(s)!`);
    } else {
      console.log(`\n✅ No fixes needed - all loads have correct driverId values`);
    }
    
    console.log(`\n📊 Summary:`);
    console.log(`  Fixed: ${fixedCount}`);
    console.log(`  Skipped (already correct): ${skippedCount}`);
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
  
  process.exit(0);
}

fixDriverIds();
