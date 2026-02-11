#!/usr/bin/env dart
// Migration script to add driverName to existing loads
// 
// This script updates all existing load documents in Firestore by:
// 1. Fetching all loads that don't have a driverName field
// 2. Looking up the driver's name using their driverId
// 3. Adding the driverName to the load document
//
// Usage:
//   dart tools/migrate_driver_names.dart
//
// Note: This script requires Firebase Admin SDK credentials to be configured.
// Set up Firebase Admin SDK following: https://firebase.google.com/docs/admin/setup

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  print('🚀 Starting driver name migration...\n');

  try {
    // Initialize Firebase
    // Note: In production, you would configure this with service account credentials
    await Firebase.initializeApp();
    final firestore = FirebaseFirestore.instance;

    // Step 1: Get all loads
    print('📦 Fetching all loads from Firestore...');
    final loadsSnapshot = await firestore.collection('loads').get();
    print('   Found ${loadsSnapshot.docs.length} total loads\n');

    // Step 2: Filter loads without driverName
    final loadsToUpdate = loadsSnapshot.docs.where((doc) {
      final data = doc.data();
      return data['driverName'] == null || (data['driverName'] as String).isEmpty;
    }).toList();

    print('📋 Found ${loadsToUpdate.length} loads without driver names\n');

    if (loadsToUpdate.isEmpty) {
      print('✅ All loads already have driver names. Migration not needed.');
      return;
    }

    // Step 3: Get all drivers for lookup
    print('👥 Fetching driver information...');
    final driversSnapshot = await firestore.collection('drivers').get();
    final driverMap = <String, String>{};
    
    for (var doc in driversSnapshot.docs) {
      final data = doc.data();
      final name = data['name'] as String?;
      if (name != null && name.isNotEmpty) {
        driverMap[doc.id] = name;
      }
    }
    print('   Loaded ${driverMap.length} drivers\n');

    // Step 4: Update loads with driver names
    print('🔄 Updating loads with driver names...');
    int successCount = 0;
    int skippedCount = 0;
    int errorCount = 0;

    for (var doc in loadsToUpdate) {
      try {
        final data = doc.data();
        final driverId = data['driverId'] as String?;
        
        if (driverId == null || driverId.isEmpty) {
          print('   ⚠️  Load ${doc.id}: No driverId found, skipping');
          skippedCount++;
          continue;
        }

        final driverName = driverMap[driverId];
        
        if (driverName == null) {
          print('   ⚠️  Load ${doc.id}: Driver $driverId not found, skipping');
          skippedCount++;
          continue;
        }

        // Update the load with driver name
        await doc.reference.update({'driverName': driverName});
        print('   ✓ Load ${doc.id}: Updated with driver name "$driverName"');
        successCount++;
      } catch (e) {
        print('   ❌ Load ${doc.id}: Error updating - $e');
        errorCount++;
      }
    }

    // Step 5: Print summary
    print('\n' + '=' * 60);
    print('Migration Summary:');
    print('=' * 60);
    print('✅ Successfully updated: $successCount loads');
    print('⚠️  Skipped: $skippedCount loads');
    print('❌ Errors: $errorCount loads');
    print('📊 Total processed: ${loadsToUpdate.length} loads');
    print('=' * 60);

    if (successCount > 0) {
      print('\n✅ Migration completed successfully!');
      print('   All loads now have driver names populated.');
    } else {
      print('\n⚠️  No loads were updated. Please check the logs above.');
    }
  } catch (e, stackTrace) {
    print('\n❌ Fatal error during migration:');
    print('   Error: $e');
    print('   Stack trace: $stackTrace');
    exit(1);
  }
}
