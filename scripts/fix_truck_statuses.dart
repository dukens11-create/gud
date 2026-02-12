#!/usr/bin/env dart

/// Script to fix trucks with invalid status values
/// 
/// This script scans all trucks in Firestore and updates any trucks
/// with null, empty, or invalid status values to 'available'.
/// 
/// Usage:
///   dart scripts/fix_truck_statuses.dart
/// 
/// Note: This script requires Firebase Admin SDK or appropriate permissions.
/// In production, this can be run as a Cloud Function or from an admin context.

import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> fixTruckStatuses() async {
  final db = FirebaseFirestore.instance;
  
  print('🔍 Scanning for trucks with invalid status...');
  
  final trucksSnapshot = await db.collection('trucks').get();
  int fixed = 0;
  int total = trucksSnapshot.docs.length;
  
  print('📊 Found $total truck(s) total');
  
  for (var doc in trucksSnapshot.docs) {
    final data = doc.data();
    final status = data['status'] as String?;
    final truckNumber = data['truckNumber'] ?? 'UNKNOWN';
    
    // Define valid statuses
    const validStatuses = ['available', 'in_use', 'maintenance', 'inactive'];
    
    // Fix if status is null, empty, or invalid
    if (status == null || status.isEmpty || !validStatuses.contains(status)) {
      print('📝 Fixing truck $truckNumber - current status: "${status ?? 'null'}"');
      
      await doc.reference.update({
        'status': 'available',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      fixed++;
    }
  }
  
  print('');
  print('✅ Fixed $fixed truck(s) out of $total total');
  print('✅ ${total - fixed} truck(s) already had valid status');
}

void main() async {
  try {
    print('🚚 GUD Truck Status Fix Script');
    print('================================');
    print('');
    
    await fixTruckStatuses();
    
    print('');
    print('🎉 Migration completed successfully!');
  } catch (e) {
    print('');
    print('❌ Error: $e');
    print('');
    print('Note: This script requires proper Firebase configuration.');
    print('Make sure you have initialized Firebase before running this script.');
  }
}
