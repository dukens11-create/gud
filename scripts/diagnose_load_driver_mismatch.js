#!/usr/bin/env node
/**
 * Load-Driver UID Mismatch Diagnostic Script
 * 
 * This script diagnoses the issue where loads assigned to drivers appear on the admin
 * dashboard but NOT on the driver dashboard. This happens when the `driverId` field
 * in Firestore loads does not match the driver's Firebase Authentication UID.
 * 
 * Usage:
 *   node scripts/diagnose_load_driver_mismatch.js
 * 
 * Prerequisites:
 *   - Node.js installed
 *   - Firebase Admin SDK configured
 *   - Service account key file at ./scripts/gud-express-firebase-adminsdk.json
 *     OR set GOOGLE_APPLICATION_CREDENTIALS environment variable
 * 
 * Setup:
 *   cd functions && npm install
 *   # Download service account key from Firebase Console and save to scripts/
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

async function diagnoseMismatch() {
  console.log('🔍 Diagnosing load-driver UID mismatches...\n');
  
  try {
    // Get all loads
    const loadsSnapshot = await db.collection('loads').get();
    console.log(`📊 Total loads in database: ${loadsSnapshot.size}\n`);
    
    // Get all drivers
    const driversSnapshot = await db.collection('drivers').get();
    const driverMap = {};
    driversSnapshot.forEach(doc => {
      const data = doc.data();
      driverMap[doc.id] = {
        name: data.name,
        email: data.email
      };
    });
    
    console.log(`👥 Total drivers in database: ${driversSnapshot.size}\n`);
    console.log('Driver UID → Name mapping:');
    Object.entries(driverMap).forEach(([uid, data]) => {
      console.log(`  ${uid} → ${data.name} (${data.email})`);
    });
    console.log('\n' + '='.repeat(80) + '\n');
    
    // Check each load
    let mismatchCount = 0;
    let validCount = 0;
    
    for (const loadDoc of loadsSnapshot.docs) {
      const load = loadDoc.data();
      const loadId = loadDoc.id;
      
      console.log(`Load: ${load.loadNumber || loadId}`);
      console.log(`  driverId field: "${load.driverId}"`);
      console.log(`  driverName field: "${load.driverName || 'N/A'}"`);
      console.log(`  status: ${load.status}`);
      
      // Check if driverId matches any Firebase Auth UID in drivers collection
      const matchesDriver = driverMap[load.driverId];
      
      if (matchesDriver) {
        console.log(`  ✅ VALID: driverId matches driver UID for ${matchesDriver.name}`);
        validCount++;
      } else {
        console.log(`  ❌ MISMATCH: driverId "${load.driverId}" does NOT match any driver UID`);
        console.log(`  ⚠️  This load will NOT appear on driver dashboard!`);
        
        // Try to find matching driver by name
        const possibleMatch = Object.entries(driverMap).find(
          ([uid, data]) => data.name.toLowerCase() === (load.driverName || load.driverId || '').toLowerCase()
        );
        
        if (possibleMatch) {
          console.log(`  💡 Suggested fix: Change driverId to "${possibleMatch[0]}" (${possibleMatch[1].name})`);
        }
        
        mismatchCount++;
      }
      
      console.log('');
    }
    
    console.log('='.repeat(80));
    console.log(`\n📊 Summary:`);
    console.log(`  ✅ Valid loads: ${validCount}`);
    console.log(`  ❌ Mismatched loads: ${mismatchCount}`);
    
    if (mismatchCount > 0) {
      console.log(`\n⚠️  ${mismatchCount} load(s) have incorrect driverId values!`);
      console.log(`   These loads will NOT appear on driver dashboards.`);
      console.log(`\n💡 To fix, run: node scripts/fix_load_driver_ids.js`);
    } else {
      console.log(`\n✅ All loads have valid driverId values!`);
      console.log(`   If drivers still can't see loads, check:`);
      console.log(`   1. Firebase Authentication - driver is logged in with correct account`);
      console.log(`   2. Firestore indexes - run: firebase deploy --only firestore:indexes`);
      console.log(`   3. Firestore rules - drivers can read their own loads`);
    }
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
  
  process.exit(0);
}

diagnoseMismatch();
