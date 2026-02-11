#!/usr/bin/env node
/**
 * Legacy Load Migration Script
 * 
 * This script identifies and optionally fixes loads in Firestore that are missing
 * the driverId field. Such loads were created before the driver assignment feature
 * was properly implemented and won't appear on driver dashboards.
 * 
 * Usage:
 *   1. Dry run (list problematic loads): node scripts/migrate_legacy_loads.js
 *   2. Interactive fix: node scripts/migrate_legacy_loads.js --fix
 *   3. Auto-fix with default driver: node scripts/migrate_legacy_loads.js --fix --default-driver=<driverId>
 * 
 * Prerequisites:
 *   - Node.js installed
 *   - Firebase Admin SDK configured
 *   - Service account key file (usually in project root or set via GOOGLE_APPLICATION_CREDENTIALS)
 * 
 * Setup:
 *   npm install firebase-admin
 */

const admin = require('firebase-admin');
const readline = require('readline');

// Initialize Firebase Admin SDK
// You'll need to configure this with your service account credentials
let serviceAccount;
try {
  // Try to load service account from file
  serviceAccount = require('../serviceAccountKey.json');
} catch (e) {
  console.log('⚠️  Service account key not found. Set GOOGLE_APPLICATION_CREDENTIALS environment variable.');
  console.log('   Or place serviceAccountKey.json in the project root.');
  console.log('   Download it from: Firebase Console > Project Settings > Service Accounts');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Parse command line arguments
const args = process.argv.slice(2);
const isDryRun = !args.includes('--fix');
const defaultDriverArg = args.find(arg => arg.startsWith('--default-driver='));
const defaultDriverId = defaultDriverArg ? defaultDriverArg.split('=')[1] : null;

async function getDriversList() {
  const driversSnapshot = await db.collection('drivers').get();
  const drivers = [];
  driversSnapshot.forEach(doc => {
    const data = doc.data();
    drivers.push({
      id: doc.id,
      name: data.name || 'Unknown',
      truckNumber: data.truckNumber || 'N/A',
      isActive: data.isActive !== false
    });
  });
  return drivers;
}

async function findLegacyLoads() {
  console.log('🔍 Scanning for loads with missing or empty driverId...\n');
  
  const loadsSnapshot = await db.collection('loads').get();
  const legacyLoads = [];
  
  loadsSnapshot.forEach(doc => {
    const data = doc.data();
    // Check if driverId is missing or empty
    if (!data.driverId || data.driverId.trim() === '') {
      legacyLoads.push({
        id: doc.id,
        data: data,
        loadNumber: data.loadNumber || 'N/A',
        status: data.status || 'unknown',
        createdAt: data.createdAt || null,
        driverName: data.driverName || null
      });
    }
  });
  
  return legacyLoads;
}

async function fixLoad(loadId, driverId, driverName) {
  const loadRef = db.collection('loads').doc(loadId);
  const updateData = { driverId };
  
  // If driverName is provided and not already set, add it
  if (driverName) {
    updateData.driverName = driverName;
  }
  
  await loadRef.update(updateData);
  console.log(`✅ Updated load ${loadId} with driverId: ${driverId}`);
}

async function interactiveFix(legacyLoads, drivers) {
  console.log('\n📝 Interactive Load Assignment\n');
  console.log('Available Drivers:');
  drivers.forEach((driver, index) => {
    const status = driver.isActive ? '✓ Active' : '✗ Inactive';
    console.log(`  ${index + 1}. ${driver.name} (${driver.truckNumber}) - ${status} [ID: ${driver.id}]`);
  });
  console.log(`  0. Skip this load`);
  console.log(`  -1. Exit\n`);
  
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });
  
  const question = (query) => new Promise(resolve => rl.question(query, resolve));
  
  for (const load of legacyLoads) {
    console.log(`\nLoad: ${load.loadNumber} (${load.status})`);
    if (load.driverName) {
      console.log(`  Original driver name: ${load.driverName}`);
    }
    console.log(`  Created: ${load.createdAt ? new Date(load.createdAt).toLocaleDateString() : 'Unknown'}`);
    
    const answer = await question('Select driver number (or 0 to skip, -1 to exit): ');
    const choice = parseInt(answer);
    
    if (choice === -1) {
      console.log('\n👋 Exiting...');
      break;
    } else if (choice === 0) {
      console.log('⏭️  Skipped');
      continue;
    } else if (choice > 0 && choice <= drivers.length) {
      const selectedDriver = drivers[choice - 1];
      await fixLoad(load.id, selectedDriver.id, selectedDriver.name);
    } else {
      console.log('❌ Invalid choice, skipping...');
    }
  }
  
  rl.close();
}

async function main() {
  console.log('🚚 Legacy Load Migration Tool\n');
  console.log(`Mode: ${isDryRun ? '🔍 DRY RUN (no changes)' : '🔧 FIX MODE (will update database)'}\n`);
  
  // Find legacy loads
  const legacyLoads = await findLegacyLoads();
  
  if (legacyLoads.length === 0) {
    console.log('✅ No legacy loads found! All loads have valid driverId fields.');
    process.exit(0);
  }
  
  console.log(`Found ${legacyLoads.length} load(s) with missing driverId:\n`);
  legacyLoads.forEach(load => {
    console.log(`  - ${load.loadNumber} (${load.status}) [ID: ${load.id}]`);
    if (load.driverName) {
      console.log(`    Driver name in record: ${load.driverName}`);
    }
  });
  
  if (isDryRun) {
    console.log('\n💡 To fix these loads, run with --fix flag:');
    console.log('   node scripts/migrate_legacy_loads.js --fix');
    console.log('\n💡 To auto-assign to a default driver:');
    console.log('   node scripts/migrate_legacy_loads.js --fix --default-driver=<driverId>');
    process.exit(0);
  }
  
  // Get list of drivers
  const drivers = await getDriversList();
  
  if (drivers.length === 0) {
    console.log('\n❌ No drivers found in the system. Please add drivers first.');
    process.exit(1);
  }
  
  // Fix mode
  if (defaultDriverId) {
    // Auto-fix with default driver
    const defaultDriver = drivers.find(d => d.id === defaultDriverId);
    if (!defaultDriver) {
      console.log(`\n❌ Driver with ID ${defaultDriverId} not found.`);
      process.exit(1);
    }
    
    console.log(`\n🔧 Assigning all legacy loads to: ${defaultDriver.name} (${defaultDriver.truckNumber})\n`);
    for (const load of legacyLoads) {
      await fixLoad(load.id, defaultDriver.id, defaultDriver.name);
    }
    console.log(`\n✅ Successfully updated ${legacyLoads.length} load(s).`);
  } else {
    // Interactive mode
    await interactiveFix(legacyLoads, drivers);
  }
  
  console.log('\n✨ Migration complete!');
  process.exit(0);
}

// Run the script
main().catch(error => {
  console.error('❌ Error:', error);
  process.exit(1);
});
