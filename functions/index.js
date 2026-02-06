const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// 1. Auto-notify on load status changes
exports.notifyLoadStatusChange = functions.firestore
  .document('loads/{loadId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    const loadId = context.params.loadId;
    if (newData.status === oldData.status) return null;
    
    console.log(`Load ${loadId} status changed: ${oldData.status} -> ${newData.status}`);
    const notifications = [];
    
    if (newData.driverId) {
      const driverDoc = await admin.firestore().collection('users').doc(newData.driverId).get();
      const driverData = driverDoc.data();
      if (driverData?.fcmToken) {
        notifications.push(admin.messaging().send({
          notification: { title: 'Load Status Updated', body: `Load ${newData.loadNumber} is now ${newData.status}` },
          data: { type: 'status_change', loadId, status: newData.status, loadNumber: newData.loadNumber },
          token: driverData.fcmToken
        }));
      }
    }
    
    if (notifications.length > 0) await Promise.all(notifications);
    return null;
  });

// 2. Notify all drivers of new loads
exports.notifyNewLoad = functions.firestore
  .document('loads/{loadId}')
  .onCreate(async (snap, context) => {
    const loadData = snap.data();
    const driversSnapshot = await admin.firestore().collection('users').where('role', '==', 'driver').get();
    const notifications = driversSnapshot.docs
      .filter(doc => doc.data().fcmToken)
      .map(doc => admin.messaging().send({
        notification: { title: 'New Load Available', body: `${loadData.loadNumber}: ${loadData.pickupCity} to ${loadData.deliveryCity}` },
        data: { type: 'new_load', loadId: context.params.loadId, loadNumber: loadData.loadNumber },
        token: doc.data().fcmToken
      }));
    if (notifications.length > 0) await Promise.all(notifications);
    return null;
  });

// 3. Auto-calculate driver earnings on delivery
exports.calculateEarnings = functions.firestore
  .document('loads/{loadId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    if (newData.status === 'delivered' && oldData.status !== 'delivered' && newData.driverId) {
      const driverDoc = await admin.firestore().collection('drivers').doc(newData.driverId).get();
      const currentEarnings = driverDoc.data()?.totalEarnings || 0;
      await admin.firestore().collection('drivers').doc(newData.driverId).update({
        totalEarnings: currentEarnings + newData.rate,
        completedLoads: admin.firestore.FieldValue.increment(1)
      });
    }
    return null;
  });

// 4. Validate load data on creation
exports.validateLoad = functions.firestore
  .document('loads/{loadId}')
  .onCreate(async (snap) => {
    const data = snap.data();
    const errors = [];
    if (!data.loadNumber) errors.push('Load number required');
    if (!data.rate || data.rate <= 0) errors.push('Valid rate required');
    await snap.ref.update({ validationStatus: errors.length > 0 ? 'failed' : 'passed', validationErrors: errors });
    return null;
  });

// 5. Auto-delete old location data (30 days)
exports.cleanupOldLocationData = functions.pubsub.schedule('every 24 hours').onRun(async () => {
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
  const snapshot = await admin.firestore().collectionGroup('locationHistory').where('timestamp', '<', thirtyDaysAgo).limit(500).get();
  const batch = admin.firestore().batch();
  snapshot.forEach(doc => batch.delete(doc.ref));
  await batch.commit();
  return { deleted: snapshot.size };
});

// 6. Daily reminders for overdue loads
exports.sendOverdueLoadReminders = functions.pubsub.schedule('every day 09:00').timeZone('America/New_York').onRun(async () => {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const snapshot = await admin.firestore().collection('loads').where('status', 'in', ['assigned', 'in_transit']).where('deliveryDate', '<', today).get();
  const notifications = [];
  for (const doc of snapshot.docs) {
    const data = doc.data();
    if (data.driverId) {
      const driver = await admin.firestore().collection('users').doc(data.driverId).get();
      if (driver.data()?.fcmToken) {
        notifications.push(admin.messaging().send({
          notification: { title: 'Overdue Load', body: `Load ${data.loadNumber} is overdue` },
          token: driver.data().fcmToken
        }));
      }
    }
  }
  if (notifications.length > 0) await Promise.all(notifications);
  return { sent: notifications.length };
});
