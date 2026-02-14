import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/payment.dart';
import '../models/load.dart';

/// Payment service for managing driver compensation.
/// 
/// Drivers receive 85% of the load revenue for each delivery.
/// Payment records are created automatically when loads are marked as delivered.
/// 
/// **Security**: All methods verify user authentication before executing queries.
/// Throws [FirebaseAuthException] if user is not authenticated.
///
/// ============================================================================
/// FIRESTORE COMPOSITE INDEX REQUIREMENTS
/// ============================================================================
/// 
/// The following composite indexes are REQUIRED for payment queries to work.
/// Add these to firestore.indexes.json and deploy with:
/// `firebase deploy --only firestore:indexes`
///
/// **REQUIRED INDEXES:**
/// 
/// 1. streamDriverPayments(driverId) - Stream all payments for a driver
///    - Collection: payments
///    - Fields:
///      * driverId (Ascending)
///      * createdAt (Descending)
///
/// 2. getPendingPayments(driverId) - Get unpaid payments for a driver
///    - Collection: payments
///    - Fields:
///      * driverId (Ascending)
///      * status (Ascending)
///      * createdAt (Descending)
///
/// 3. getTotalPaidAmount(driverId, startDate, endDate) - Calculate paid amount with date range
///    - Collection: payments
///    - Fields:
///      * driverId (Ascending)
///      * status (Ascending)
///      * paymentDate (Descending)
///
/// 4. getUnpaidLoads(driverId) - Get delivered but unpaid loads
///    - Collection: loads
///    - Fields:
///      * driverId (Ascending)
///      * paymentStatus (Ascending)
///      * status (Ascending)
///
/// ============================================================================
class PaymentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Commission rate for drivers (85% of load rate)
  static const double DRIVER_COMMISSION_RATE = 0.85;
  
  /// Verify user is authenticated before executing Firestore operations
  /// 
  /// Throws [FirebaseAuthException] with code 'unauthenticated' if user is not signed in
  void _requireAuth() {
    if (_auth.currentUser == null) {
      throw FirebaseAuthException(
        code: 'unauthenticated',
        message: 'User must be signed in to access payment data',
      );
    }
  }

  /// Calculate driver payment amount (85% of load rate)
  /// 
  /// Parameters:
  /// - [loadRate]: The total rate for the load
  /// 
  /// Returns: Driver's payment amount (85% of load rate)
  double calculateDriverPayment(double loadRate) {
    return loadRate * DRIVER_COMMISSION_RATE;
  }

  /// Create a payment record when a load is delivered
  /// 
  /// Parameters:
  /// - [driverId]: Driver's user ID
  /// - [loadId]: Load's document ID
  /// - [loadRate]: Total rate for the load
  /// - [notes]: Optional notes about the payment
  /// 
  /// Returns: Payment document ID
  /// 
  /// Throws [FirebaseAuthException] if user is not authenticated
  Future<String> createPayment({
    required String driverId,
    required String loadId,
    required double loadRate,
    String? notes,
  }) async {
    _requireAuth();
    
    final currentUser = _auth.currentUser!;
    final amount = calculateDriverPayment(loadRate);
    
    print('💰 Creating payment for driver $driverId');
    print('   Load ID: $loadId');
    print('   Load Rate: \$$loadRate');
    print('   Driver Payment (85%): \$$amount');
    
    try {
      final docRef = await _db.collection('payments').add({
        'driverId': driverId,
        'loadId': loadId,
        'amount': amount,
        'loadRate': loadRate,
        'status': 'pending',
        'paymentDate': null,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': currentUser.uid,
        if (notes != null) 'notes': notes,
      });
      
      print('✅ Payment created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating payment: $e');
      rethrow;
    }
  }

  /// Mark a payment as paid
  /// 
  /// Parameters:
  /// - [paymentId]: Payment document ID
  /// 
  /// Throws [FirebaseAuthException] if user is not authenticated
  Future<void> markAsPaid(String paymentId) async {
    _requireAuth();
    
    print('✅ Marking payment as paid: $paymentId');
    
    try {
      await _db.collection('payments').doc(paymentId).update({
        'status': 'paid',
        'paymentDate': FieldValue.serverTimestamp(),
      });
      
      print('✅ Payment marked as paid');
    } catch (e) {
      print('❌ Error marking payment as paid: $e');
      rethrow;
    }
  }

  /// Stream all payments for a driver with real-time updates
  /// 
  /// Returns payments ordered by creation time (newest first)
  /// 
  /// **Required Firestore Composite Index:**
  /// - Collection: payments
  /// - Fields:
  ///   * driverId (Ascending)
  ///   * createdAt (Descending)
  /// 
  /// Parameters:
  /// - [driverId]: Driver's user ID
  Stream<List<Payment>> streamDriverPayments(String driverId) {
    _requireAuth();
    
    print('🔍 Streaming payments for driver: $driverId');
    print('   Collection: payments');
    print('   Where: driverId == $driverId');
    print('   OrderBy: createdAt DESC');
    print('   ✅ Requires composite index: driverId ASC + createdAt DESC');
    
    return _db
        .collection('payments')
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          print('📊 Received ${snapshot.docs.length} payment documents');
          return snapshot.docs.map((doc) => Payment.fromDoc(doc)).toList();
        });
  }

  /// Get all pending (unpaid) payments for a driver
  /// 
  /// **Required Firestore Composite Index:**
  /// - Collection: payments
  /// - Fields:
  ///   * driverId (Ascending)
  ///   * status (Ascending)
  ///   * createdAt (Descending)
  /// 
  /// Parameters:
  /// - [driverId]: Driver's user ID
  Future<List<Payment>> getPendingPayments(String driverId) async {
    _requireAuth();
    
    print('🔍 Getting pending payments for driver: $driverId');
    print('   Collection: payments');
    print('   Where: driverId == $driverId AND status == pending');
    print('   OrderBy: createdAt DESC');
    print('   ✅ Requires composite index: driverId ASC + status ASC + createdAt DESC');
    
    try {
      final snapshot = await _db
          .collection('payments')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();
      
      print('📊 Found ${snapshot.docs.length} pending payments');
      return snapshot.docs.map((doc) => Payment.fromDoc(doc)).toList();
    } catch (e) {
      print('❌ Error getting pending payments: $e');
      rethrow;
    }
  }

  /// Get total amount paid to driver (with optional date range)
  /// 
  /// **Required Firestore Composite Index:**
  /// - Collection: payments
  /// - Fields:
  ///   * driverId (Ascending)
  ///   * status (Ascending)
  ///   * paymentDate (Descending)
  /// 
  /// Parameters:
  /// - [driverId]: Driver's user ID
  /// - [startDate]: Optional start date for date range filter
  /// - [endDate]: Optional end date for date range filter
  Future<double> getTotalPaidAmount(
    String driverId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _requireAuth();
    
    print('🔍 Calculating total paid amount for driver: $driverId');
    print('   Collection: payments');
    print('   Where: driverId == $driverId AND status == paid');
    if (startDate != null) print('   Where: paymentDate >= $startDate');
    if (endDate != null) print('   Where: paymentDate <= $endDate');
    print('   ✅ Requires composite index: driverId ASC + status ASC + paymentDate DESC');
    
    try {
      Query query = _db
          .collection('payments')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'paid');
      
      if (startDate != null) {
        query = query.where('paymentDate', 
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('paymentDate', 
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      
      final snapshot = await query.get();
      
      final total = snapshot.docs.fold<double>(
        0.0, 
        (sum, doc) => sum + ((doc.data() as Map<String, dynamic>)['amount'] ?? 0).toDouble()
      );
      
      print('📊 Total paid amount: \$$total (${snapshot.docs.length} payments)');
      return total;
    } catch (e) {
      print('❌ Error calculating total paid amount: $e');
      rethrow;
    }
  }

  /// Get total pending payment amount for driver
  /// 
  /// Parameters:
  /// - [driverId]: Driver's user ID
  Future<double> getTotalPendingAmount(String driverId) async {
    _requireAuth();
    
    print('🔍 Calculating total pending amount for driver: $driverId');
    
    try {
      final snapshot = await _db
          .collection('payments')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      final total = snapshot.docs.fold<double>(
        0.0,
        (sum, doc) => sum + ((doc.data() as Map<String, dynamic>)['amount'] ?? 0).toDouble()
      );
      
      print('📊 Total pending amount: \$$total (${snapshot.docs.length} payments)');
      return total;
    } catch (e) {
      print('❌ Error calculating total pending amount: $e');
      rethrow;
    }
  }

  /// Get all delivered loads that haven't been paid yet
  /// 
  /// **Required Firestore Composite Index:**
  /// - Collection: loads
  /// - Fields:
  ///   * driverId (Ascending)
  ///   * paymentStatus (Ascending)
  ///   * status (Ascending)
  /// 
  /// Parameters:
  /// - [driverId]: Driver's user ID
  Future<List<LoadModel>> getUnpaidLoads(String driverId) async {
    _requireAuth();
    
    print('🔍 Getting unpaid loads for driver: $driverId');
    print('   Collection: loads');
    print('   Where: driverId == $driverId');
    print('   Where: paymentStatus == unpaid');
    print('   Where: status == delivered OR status == completed');
    print('   ✅ Requires composite index: driverId ASC + paymentStatus ASC + status ASC');
    
    try {
      final snapshot = await _db
          .collection('loads')
          .where('driverId', isEqualTo: driverId)
          .where('paymentStatus', isEqualTo: 'unpaid')
          .where('status', whereIn: ['delivered', 'completed'])
          .get();
      
      print('📊 Found ${snapshot.docs.length} unpaid loads');
      return snapshot.docs.map((doc) => LoadModel.fromDoc(doc)).toList();
    } catch (e) {
      print('❌ Error getting unpaid loads: $e');
      rethrow;
    }
  }

  /// Create payments for multiple loads at once
  /// 
  /// Parameters:
  /// - [loadIds]: List of load document IDs
  /// 
  /// Returns: List of created payment IDs
  Future<List<String>> batchCreatePayments(List<String> loadIds) async {
    _requireAuth();
    
    print('🔄 Batch creating payments for ${loadIds.length} loads');
    
    final paymentIds = <String>[];
    final currentUser = _auth.currentUser!;
    
    try {
      // Fetch all loads
      final loadDocs = await Future.wait(
        loadIds.map((id) => _db.collection('loads').doc(id).get())
      );
      
      // Create payments using batch write for atomicity
      final batch = _db.batch();
      
      for (final loadDoc in loadDocs) {
        if (!loadDoc.exists) {
          print('⚠️  Load not found: ${loadDoc.id}');
          continue;
        }
        
        final loadData = loadDoc.data() as Map<String, dynamic>;
        final driverId = loadData['driverId'] as String;
        final loadRate = (loadData['rate'] ?? 0).toDouble();
        final amount = calculateDriverPayment(loadRate);
        
        // Check if payment already exists
        final existingPayment = await _db
            .collection('payments')
            .where('loadId', isEqualTo: loadDoc.id)
            .limit(1)
            .get();
        
        if (existingPayment.docs.isNotEmpty) {
          print('⚠️  Payment already exists for load: ${loadDoc.id}');
          continue;
        }
        
        // Create payment document
        final paymentRef = _db.collection('payments').doc();
        batch.set(paymentRef, {
          'driverId': driverId,
          'loadId': loadDoc.id,
          'amount': amount,
          'loadRate': loadRate,
          'status': 'pending',
          'paymentDate': null,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': currentUser.uid,
        });
        
        // Update load with payment reference
        batch.update(loadDoc.reference, {
          'paymentId': paymentRef.id,
          'paymentStatus': 'unpaid',
        });
        
        paymentIds.add(paymentRef.id);
        print('   ✓ Queued payment for load ${loadDoc.id}: \$$amount');
      }
      
      // Commit all changes atomically
      await batch.commit();
      
      print('✅ Batch created ${paymentIds.length} payments');
      return paymentIds;
    } catch (e) {
      print('❌ Error batch creating payments: $e');
      rethrow;
    }
  }
}
