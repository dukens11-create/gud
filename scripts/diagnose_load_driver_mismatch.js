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
        email: data.email,
        completedLoads: data.completedLoads || 0,
        totalEarnings: data.totalEarnings || 0
      };
    });
    
    console.log(`👥 Total drivers in database: ${driversSnapshot.size}\n`);
    console.log('Driver UID → Name mapping:');
    Object.entries(driverMap).forEach(([uid, data]) => {
      console.log(`  ${uid} → ${data.name} (${data.email})`);
      console.log(`     Completed Loads: ${data.completedLoads}, Total Earnings: $${data.totalEarnings}`);
    });
    console.log('\n' + '='.repeat(80) + '\n');
    
    // Check each load
    let mismatchCount = 0;
    let validCount = 0;
    let deliveredCount = 0;
    const statusCounts = {};
    
    for (const loadDoc of loadsSnapshot.docs) {
      const load = loadDoc.data();
      const loadId = loadDoc.id;
      
      // Track status distribution
      const status = load.status || 'unknown';
      statusCounts[status] = (statusCounts[status] || 0) + 1;
      
      if (status === 'delivered') {
        deliveredCount++;
      }
      
      console.log(`Load: ${load.loadNumber || loadId}`);
      console.log(`  driverId field: "${load.driverId || 'N/A'}"`);
      console.log(`  driverName field: "${load.driverName || 'N/A'}"`);
      console.log(`  status: ${status}`);
      console.log(`  rate: $${load.rate || 0}`);
      
      if (!load.driverId) {
        console.log(`  ⚠️  WARNING: Load has no driverId - will not appear in any driver dashboard`);
        mismatchCount++;
        console.log('');
        continue;
      }
      
      // Check if driverId matches any Firebase Auth UID in drivers collection
      const matchesDriver = driverMap[load.driverId];
      
      if (matchesDriver) {
        console.log(`  ✅ VALID: driverId matches driver UID for ${matchesDriver.name}`);
        if (status === 'delivered') {
          console.log(`  ℹ️  This load should count toward driver's completed loads`);
        }
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
    console.log(`  Total loads: ${loadsSnapshot.size}`);
    console.log(`  ✅ Valid loads: ${validCount}`);
    console.log(`  ❌ Mismatched/Missing driverId: ${mismatchCount}`);
    console.log(`  📦 Delivered loads: ${deliveredCount}`);
    console.log(`\n  Status distribution:`);
    Object.entries(statusCounts).sort((a, b) => b[1] - a[1]).forEach(([status, count]) => {
      console.log(`     ${status}: ${count}`);
    });
    
    console.log(`\n👥 Driver Statistics Summary:`);
    Object.entries(driverMap).forEach(([uid, data]) => {
      console.log(`  ${data.name}:`);
      console.log(`     UID: ${uid}`);
      console.log(`     Completed Loads (from driver doc): ${data.completedLoads}`);
      console.log(`     Total Earnings (from driver doc): $${data.totalEarnings}`);
      
      // Count actual delivered loads for this driver
      const actualLoads = Array.from(loadsSnapshot.docs).filter(doc => 
        doc.data().driverId === uid && doc.data().status === 'delivered'
      ).length;
      console.log(`     Actual delivered loads (from query): ${actualLoads}`);
      
      if (actualLoads !== data.completedLoads) {
        console.log(`     ⚠️  MISMATCH: Driver doc shows ${data.completedLoads} but ${actualLoads} delivered loads found`);
        console.log(`     Possible causes:`);
        console.log(`       - Cloud Function "calculateEarnings" not triggered`);
        console.log(`       - Cloud Function failed during execution`);
        console.log(`       - Manual data entry without updating stats`);
      }
    });
    
    if (mismatchCount > 0) {
      console.log(`\n⚠️  ${mismatchCount} load(s) have incorrect or missing driverId values!`);
      console.log(`   These loads will NOT appear on driver dashboards.`);
      console.log(`\n💡 To fix, run: node scripts/fix_load_driver_ids.js`);
    } else {
      console.log(`\n✅ All loads have valid driverId values!`);
    }
    
    if (deliveredCount === 0) {
      console.log(`\n⚠️  No delivered loads found!`);
      console.log(`   Driver Performance Dashboard will show 0 loads for all drivers.`);
      console.log(`   Ensure loads are marked with status="delivered" when completed.`);
    }
    
    console.log(`\n📋 Next steps:`);
    console.log(`   1. Check Firebase Functions logs for calculateEarnings execution`);
    console.log(`   2. Verify Firestore indexes are deployed: firebase deploy --only firestore:indexes`);
    console.log(`   3. Check Firestore security rules allow driver stat updates`);
    console.log(`   4. Test completing a delivery and verify stats update`);
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
  
  process.exit(0);
}

diagnoseMismatch();
