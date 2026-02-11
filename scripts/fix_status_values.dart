import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Script to fix status values in Firestore
/// 
/// This script updates all loads with status 'in-transit' (hyphen) 
/// to 'in_transit' (underscore) to match the app's filter format.
/// 
/// Run this script once to fix existing data:
/// dart run scripts/fix_status_values.dart

Future<void> main() async {
  print('🔧 Starting status value migration...\n');
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  final firestore = FirebaseFirestore.instance;
  
  try {
    // Get all loads with 'in-transit' status (hyphen)
    print('📊 Querying loads with status "in-transit"...');
    final snapshot = await firestore
        .collection('loads')
        .where('status', isEqualTo: 'in-transit')
        .get();
    
    if (snapshot.docs.isEmpty) {
      print('✅ No loads found with "in-transit" status.');
      print('   All status values are already correct!\n');
      return;
    }
    
    print('📝 Found ${snapshot.docs.length} loads to update\n');
    
    // Update each document
    int successCount = 0;
    int errorCount = 0;
    
    for (final doc in snapshot.docs) {
      try {
        await doc.reference.update({'status': 'in_transit'});
        successCount++;
        print('✅ Updated load: ${doc.id} (${doc.data()['loadNumber'] ?? 'N/A'})');
      } catch (e) {
        errorCount++;
        print('❌ Failed to update load ${doc.id}: $e');
      }
    }
    
    print('\n📊 Migration Complete!');
    print('   ✅ Successfully updated: $successCount loads');
    if (errorCount > 0) {
      print('   ❌ Failed: $errorCount loads');
    }
    print('\n🎉 Status values have been fixed!');
    print('   Old value: "in-transit" (hyphen)');
    print('   New value: "in_transit" (underscore)\n');
    
  } catch (e) {
    print('❌ Error during migration: $e');
    rethrow;
  }
}