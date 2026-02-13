const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

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
    const loadId = context.params.loadId;
    
    // Log all status changes for debugging
    if (newData.status !== oldData.status) {
      console.log(`📦 Load ${loadId} status changed: ${oldData.status} -> ${newData.status}`);
    }
    
    // Only proceed if status changed to delivered
    if (newData.status !== 'delivered' || oldData.status === 'delivered') {
      return null;
    }
    
    console.log(`💰 Calculating earnings for load ${loadId}`);
    console.log(`   Load Number: ${newData.loadNumber || 'N/A'}`);
    console.log(`   Driver ID: ${newData.driverId || 'N/A'}`);
    console.log(`   Rate: $${newData.rate || 0}`);
    
    // Validate required fields
    if (!newData.driverId) {
      console.error(`❌ Error: Load ${loadId} has no driverId - cannot update driver stats`);
      return null;
    }
    
    if (!newData.rate || newData.rate <= 0) {
      console.warn(`⚠️  Warning: Load ${loadId} has invalid rate: ${newData.rate}`);
      // Still increment completed loads even if rate is 0
    }
    
    try {
      // Get driver document
      const driverRef = admin.firestore().collection('drivers').doc(newData.driverId);
      const driverDoc = await driverRef.get();
      
      if (!driverDoc.exists) {
        console.error(`❌ Error: Driver ${newData.driverId} not found in drivers collection`);
        console.error(`   Load ${loadId} marked as delivered but driver stats cannot be updated`);
        console.error(`   Possible issue: driverId does not match driver document ID`);
        return null;
      }
      
      const driverData = driverDoc.data();
      console.log(`   Driver Name: ${driverData.name || 'Unknown'}`);
      console.log(`   Current Total Earnings: $${driverData.totalEarnings || 0}`);
      console.log(`   Current Completed Loads: ${driverData.completedLoads || 0}`);
      
      const currentEarnings = driverData.totalEarnings || 0;
      const loadRate = newData.rate || 0;
      const newEarnings = currentEarnings + loadRate;
      
      // Update driver statistics
      await driverRef.update({
        totalEarnings: newEarnings,
        completedLoads: admin.firestore.FieldValue.increment(1)
      });
      
      console.log(`✅ Driver stats updated successfully`);
      console.log(`   New Total Earnings: $${newEarnings}`);
      console.log(`   Completed Loads: ${(driverData.completedLoads || 0) + 1}`);
      
      return { success: true, driverId: newData.driverId, earnings: loadRate };
      
    } catch (error) {
      console.error(`❌ Error updating driver stats for load ${loadId}:`, error);
      console.error(`   Driver ID: ${newData.driverId}`);
      console.error(`   Error code: ${error.code || 'unknown'}`);
      console.error(`   Error message: ${error.message || 'unknown'}`);
      
      // Don't throw - we don't want to fail the entire function
      // The load is already marked as delivered, which is the most important part
      return { success: false, error: error.message };
    }
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

// 7. Daily document expiration check
exports.checkDocumentExpirations = functions.pubsub
  .schedule('every day 08:00')
  .timeZone('America/New_York')
  .onRun(async () => {
    console.log('🔍 Checking for expiring documents...');
    const now = new Date();
    const thirtyDaysFromNow = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
    
    let alertsCreated = 0;
    let notificationsSent = 0;

    // Check driver documents
    const driversSnapshot = await admin.firestore().collection('drivers').get();
    
    for (const driverDoc of driversSnapshot.docs) {
      const driverId = driverDoc.id;
      const driverData = driverDoc.data();
      
      // Check driver license expiration
      if (driverData.licenseExpiry) {
        const licenseExpiry = driverData.licenseExpiry.toDate();
        if (licenseExpiry > now && licenseExpiry < thirtyDaysFromNow) {
          const daysRemaining = Math.floor((licenseExpiry - now) / (1000 * 60 * 60 * 24));
          
          // Check if alert already exists
          const existingAlert = await admin.firestore()
            .collection('expiration_alerts')
            .where('driverId', '==', driverId)
            .where('type', '==', 'driver_license')
            .where('status', 'in', ['pending', 'sent'])
            .get();
          
          if (existingAlert.empty) {
            // Create new alert
            await admin.firestore().collection('expiration_alerts').add({
              driverId: driverId,
              type: 'driver_license',
              expiryDate: admin.firestore.Timestamp.fromDate(licenseExpiry),
              status: 'sent',
              daysRemaining: daysRemaining,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              sentAt: admin.firestore.FieldValue.serverTimestamp()
            });
            alertsCreated++;
            
            // Send notification
            const userSnapshot = await admin.firestore()
              .collection('users')
              .where('driverId', '==', driverId)
              .limit(1)
              .get();
            
            if (!userSnapshot.empty) {
              const userData = userSnapshot.docs[0].data();
              if (userData.fcmToken) {
                await admin.messaging().send({
                  notification: {
                    title: '📄 Driver License Expiring Soon',
                    body: `Your driver license expires in ${daysRemaining} days`
                  },
                  data: {
                    type: 'expiration_alert',
                    alertType: 'driver_license',
                    daysRemaining: daysRemaining.toString()
                  },
                  token: userData.fcmToken
                });
                notificationsSent++;
              }
            }
          }
        }
      }
      
      // Check driver documents (medical cards, etc.)
      const documentsSnapshot = await admin.firestore()
        .collection('drivers')
        .doc(driverId)
        .collection('documents')
        .where('status', '==', 'valid')
        .get();
      
      for (const docSnapshot of documentsSnapshot.docs) {
        const docData = docSnapshot.data();
        const expiryDate = docData.expiryDate.toDate();
        
        if (expiryDate > now && expiryDate < thirtyDaysFromNow) {
          const daysRemaining = Math.floor((expiryDate - now) / (1000 * 60 * 60 * 24));
          
          // Check if alert already exists
          const existingAlert = await admin.firestore()
            .collection('expiration_alerts')
            .where('documentId', '==', docSnapshot.id)
            .where('status', 'in', ['pending', 'sent'])
            .get();
          
          if (existingAlert.empty) {
            // Map document type to alert type
            let alertType = 'other';
            if (docData.type === 'medical_card') alertType = 'medical_card';
            else if (docData.type === 'license') alertType = 'driver_license';
            else if (docData.type === 'certification') alertType = 'certification';
            
            // Create new alert
            await admin.firestore().collection('expiration_alerts').add({
              driverId: driverId,
              documentId: docSnapshot.id,
              type: alertType,
              expiryDate: admin.firestore.Timestamp.fromDate(expiryDate),
              status: 'sent',
              daysRemaining: daysRemaining,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              sentAt: admin.firestore.FieldValue.serverTimestamp()
            });
            alertsCreated++;
            
            // Send notification
            const userSnapshot = await admin.firestore()
              .collection('users')
              .where('driverId', '==', driverId)
              .limit(1)
              .get();
            
            if (!userSnapshot.empty) {
              const userData = userSnapshot.docs[0].data();
              if (userData.fcmToken) {
                const docTypeDisplayName = docData.type === 'medical_card' 
                  ? 'DOT Medical Card'
                  : docData.type === 'license'
                  ? 'Driver License'
                  : docData.type === 'certification'
                  ? 'Certification'
                  : 'Document';
                
                await admin.messaging().send({
                  notification: {
                    title: `📄 ${docTypeDisplayName} Expiring Soon`,
                    body: `Your ${docTypeDisplayName.toLowerCase()} expires in ${daysRemaining} days`
                  },
                  data: {
                    type: 'expiration_alert',
                    alertType: alertType,
                    daysRemaining: daysRemaining.toString()
                  },
                  token: userData.fcmToken
                });
                notificationsSent++;
              }
            }
          }
        }
      }
    }
    
    // Check truck documents
    const trucksSnapshot = await admin.firestore().collection('trucks').get();
    
    for (const truckDoc of trucksSnapshot.docs) {
      const truckNumber = truckDoc.id;
      
      const documentsSnapshot = await admin.firestore()
        .collection('trucks')
        .doc(truckNumber)
        .collection('documents')
        .where('status', '==', 'valid')
        .get();
      
      for (const docSnapshot of documentsSnapshot.docs) {
        const docData = docSnapshot.data();
        const expiryDate = docData.expiryDate.toDate();
        
        if (expiryDate > now && expiryDate < thirtyDaysFromNow) {
          const daysRemaining = Math.floor((expiryDate - now) / (1000 * 60 * 60 * 24));
          
          // Check if alert already exists
          const existingAlert = await admin.firestore()
            .collection('expiration_alerts')
            .where('documentId', '==', docSnapshot.id)
            .where('truckNumber', '==', truckNumber)
            .where('status', 'in', ['pending', 'sent'])
            .get();
          
          if (existingAlert.empty) {
            // Map document type to alert type
            let alertType = 'other';
            if (docData.type === 'registration') alertType = 'truck_registration';
            else if (docData.type === 'insurance') alertType = 'truck_insurance';
            
            // Get driver assigned to this truck
            const driverSnapshot = await admin.firestore()
              .collection('drivers')
              .where('truckNumber', '==', truckNumber)
              .limit(1)
              .get();
            
            const driverId = !driverSnapshot.empty ? driverSnapshot.docs[0].id : null;
            
            // Create new alert
            await admin.firestore().collection('expiration_alerts').add({
              driverId: driverId,
              documentId: docSnapshot.id,
              truckNumber: truckNumber,
              type: alertType,
              expiryDate: admin.firestore.Timestamp.fromDate(expiryDate),
              status: 'sent',
              daysRemaining: daysRemaining,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              sentAt: admin.firestore.FieldValue.serverTimestamp()
            });
            alertsCreated++;
            
            // Send notification to driver and admins
            if (driverId) {
              const userSnapshot = await admin.firestore()
                .collection('users')
                .where('driverId', '==', driverId)
                .limit(1)
                .get();
              
              if (!userSnapshot.empty) {
                const userData = userSnapshot.docs[0].data();
                if (userData.fcmToken) {
                  const docTypeDisplayName = docData.type === 'registration'
                    ? 'Truck Registration'
                    : docData.type === 'insurance'
                    ? 'Truck Insurance'
                    : 'Truck Document';
                  
                  await admin.messaging().send({
                    notification: {
                      title: `🚛 ${docTypeDisplayName} Expiring Soon`,
                      body: `${docTypeDisplayName} for truck ${truckNumber} expires in ${daysRemaining} days`
                    },
                    data: {
                      type: 'expiration_alert',
                      alertType: alertType,
                      truckNumber: truckNumber,
                      daysRemaining: daysRemaining.toString()
                    },
                    token: userData.fcmToken
                  });
                  notificationsSent++;
                }
              }
            }
            
            // Notify admins
            const adminSnapshot = await admin.firestore()
              .collection('users')
              .where('role', '==', 'admin')
              .get();
            
            for (const adminDoc of adminSnapshot.docs) {
              const adminData = adminDoc.data();
              if (adminData.fcmToken) {
                const docTypeDisplayName = docData.type === 'registration'
                  ? 'Truck Registration'
                  : docData.type === 'insurance'
                  ? 'Truck Insurance'
                  : 'Truck Document';
                
                await admin.messaging().send({
                  notification: {
                    title: `🚛 ${docTypeDisplayName} Expiring Soon`,
                    body: `${docTypeDisplayName} for truck ${truckNumber} expires in ${daysRemaining} days`
                  },
                  data: {
                    type: 'expiration_alert',
                    alertType: alertType,
                    truckNumber: truckNumber,
                    daysRemaining: daysRemaining.toString()
                  },
                  token: adminData.fcmToken
                });
                notificationsSent++;
              }
            }
          }
        }
      }
    }
    
    console.log(`✅ Document expiration check completed: ${alertsCreated} alerts created, ${notificationsSent} notifications sent`);
    return { alertsCreated, notificationsSent };
  });

// 8. Update days remaining for active alerts (runs daily)
exports.updateAlertDaysRemaining = functions.pubsub
  .schedule('every day 00:00')
  .timeZone('America/New_York')
  .onRun(async () => {
    console.log('🔄 Updating days remaining for active alerts...');
    
    const now = new Date();
    const alertsSnapshot = await admin.firestore()
      .collection('expiration_alerts')
      .where('status', 'in', ['pending', 'sent'])
      .get();
    
    const batch = admin.firestore().batch();
    let updated = 0;
    
    for (const alertDoc of alertsSnapshot.docs) {
      const alertData = alertDoc.data();
      const expiryDate = alertData.expiryDate.toDate();
      const daysRemaining = Math.floor((expiryDate - now) / (1000 * 60 * 60 * 24));
      
      batch.update(alertDoc.ref, { daysRemaining: daysRemaining });
      updated++;
    }
    
    await batch.commit();
    console.log(`✅ Updated ${updated} alerts`);
    return { updated };
  });

// ========== EMAIL NOTIFICATION FUNCTIONS ==========

// Configure email transporter using environment variables
// Set these in Firebase Functions config:
// firebase functions:config:set email.user="your-email@gmail.com" email.pass="your-app-password"
// OR use SMTP service like SendGrid, Mailgun, etc.
function getEmailTransporter() {
  const config = functions.config();
  
  // If using Gmail (for development/testing)
  // For production, use a professional email service like SendGrid or Mailgun
  if (config.email && config.email.user && config.email.pass) {
    return nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: config.email.user,
        pass: config.email.pass, // Use app password, not regular password
      },
    });
  }
  
  // Alternative: Use SendGrid SMTP
  // if (config.sendgrid && config.sendgrid.apikey) {
  //   return nodemailer.createTransport({
  //     host: 'smtp.sendgrid.net',
  //     port: 587,
  //     auth: {
  //       user: 'apikey',
  //       pass: config.sendgrid.apikey,
  //     },
  //   });
  // }
  
  // Fallback: Log-only transporter for testing
  console.warn('⚠️ Email transporter not configured. Email will be logged but not sent.');
  console.warn('Configure email with: firebase functions:config:set email.user="your-email" email.pass="your-password"');
  return null;
}

// Helper function to send email
async function sendEmail(to, subject, htmlContent) {
  const transporter = getEmailTransporter();
  
  if (!transporter) {
    console.log('📧 [TEST MODE] Email would be sent to:', to);
    console.log('📧 [TEST MODE] Subject:', subject);
    console.log('📧 [TEST MODE] Content:', htmlContent);
    return { success: false, mode: 'test' };
  }
  
  try {
    const config = functions.config();
    const fromEmail = config.email?.from || config.email?.user || 'noreply@gudexpress.com';
    
    const info = await transporter.sendMail({
      from: `"GUD Express" <${fromEmail}>`,
      to: to,
      subject: subject,
      html: htmlContent,
    });
    
    console.log('✅ Email sent successfully:', info.messageId);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('❌ Error sending email:', error);
    return { success: false, error: error.message };
  }
}

// Helper function to generate load assignment email HTML
function generateLoadEmailHtml(loadData, driverData, isReassignment = false) {
  const title = isReassignment ? 'Load Assignment Update' : 'New Load Assignment';
  const greeting = `Hi ${driverData.name || 'Driver'},`;
  const intro = isReassignment 
    ? 'You have been assigned to an existing load. Here are the details:' 
    : 'You have been assigned a new load. Here are the details:';
  
  return `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <h2 style="color: #2563eb;">${title}</h2>
      <p>${greeting}</p>
      <p>${intro}</p>
      
      <div style="background-color: #f3f4f6; padding: 20px; border-radius: 8px; margin: 20px 0;">
        <p><strong>Load Number:</strong> ${loadData.loadNumber}</p>
        <p><strong>Driver:</strong> ${loadData.driverName || driverData.name}</p>
        <p><strong>Rate:</strong> $${loadData.rate.toFixed(2)}</p>
        ${loadData.miles != null ? `<p><strong>Estimated Miles:</strong> ${Number(loadData.miles).toFixed(1)}</p>` : ''}
        ${isReassignment ? `<p><strong>Status:</strong> ${loadData.status}</p>` : ''}
      </div>
      
      <div style="margin: 20px 0;">
        <h3 style="color: #059669;">📍 Pickup</h3>
        <p>${loadData.pickupAddress}</p>
      </div>
      
      <div style="margin: 20px 0;">
        <h3 style="color: #dc2626;">📍 Delivery</h3>
        <p>${loadData.deliveryAddress}</p>
      </div>
      
      ${loadData.notes ? `
      <div style="background-color: #fef3c7; padding: 15px; border-left: 4px solid #f59e0b; margin: 20px 0;">
        <p><strong>Notes:</strong></p>
        <p>${loadData.notes}</p>
      </div>
      ` : ''}
      
      <p style="margin-top: 30px;">Please check the GUD Express app for more details and to update your status.</p>
      
      <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 30px 0;">
      <p style="color: #6b7280; font-size: 12px;">
        This is an automated notification from GUD Express. Please do not reply to this email.
      </p>
    </div>
  `;
}

// 9. Send email notification when load is created with driver assignment
exports.sendLoadAssignmentEmail = functions.firestore
  .document('loads/{loadId}')
  .onCreate(async (snap, context) => {
    const loadData = snap.data();
    const loadId = context.params.loadId;
    
    console.log(`📧 Load created: ${loadId}, checking for driver assignment...`);
    
    // Only send email if a driver is assigned
    if (!loadData.driverId) {
      console.log('ℹ️ No driver assigned, skipping email notification');
      return null;
    }
    
    try {
      // Get driver information
      const driverDoc = await admin.firestore().collection('drivers').doc(loadData.driverId).get();
      
      if (!driverDoc.exists) {
        console.warn(`⚠️ Driver ${loadData.driverId} not found`);
        return null;
      }
      
      const driverData = driverDoc.data();
      const driverEmail = driverData.email;
      
      if (!driverEmail) {
        console.warn(`⚠️ Driver ${loadData.driverId} has no email address`);
        return null;
      }
      
      // Generate email content
      const subject = `🚚 New Load Assignment: ${loadData.loadNumber}`;
      const htmlContent = generateLoadEmailHtml(loadData, driverData, false);
      
      const result = await sendEmail(driverEmail, subject, htmlContent);
      
      if (result.success) {
        console.log(`✅ Load assignment email sent to ${driverEmail} for load ${loadData.loadNumber}`);
      } else if (result.mode === 'test') {
        console.log(`📧 Test mode: Email notification logged for ${driverEmail}`);
      } else {
        console.error(`❌ Failed to send email: ${result.error}`);
      }
      
      return result;
    } catch (error) {
      console.error('❌ Error in sendLoadAssignmentEmail:', error);
      return null;
    }
  });

// 10. Send email notification when driver is reassigned on load update
exports.sendLoadReassignmentEmail = functions.firestore
  .document('loads/{loadId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    const loadId = context.params.loadId;
    
    // Check if driverId changed
    if (newData.driverId === oldData.driverId) {
      return null;
    }
    
    console.log(`📧 Driver reassignment detected for load ${loadId}`);
    
    // If there's a new driver assigned, send them an email
    if (newData.driverId) {
      try {
        // Get driver information
        const driverDoc = await admin.firestore().collection('drivers').doc(newData.driverId).get();
        
        if (!driverDoc.exists) {
          console.warn(`⚠️ Driver ${newData.driverId} not found`);
          return null;
        }
        
        const driverData = driverDoc.data();
        const driverEmail = driverData.email;
        
        if (!driverEmail) {
          console.warn(`⚠️ Driver ${newData.driverId} has no email address`);
          return null;
        }
        
        // Generate email content
        const subject = `🚚 Load Assignment Update: ${newData.loadNumber}`;
        const htmlContent = generateLoadEmailHtml(newData, driverData, true);
        
        const result = await sendEmail(driverEmail, subject, htmlContent);
        
        if (result.success) {
          console.log(`✅ Load reassignment email sent to ${driverEmail} for load ${newData.loadNumber}`);
        } else if (result.mode === 'test') {
          console.log(`📧 Test mode: Email notification logged for ${driverEmail}`);
        } else {
          console.error(`❌ Failed to send email: ${result.error}`);
        }
        
        return result;
      } catch (error) {
        console.error('❌ Error in sendLoadReassignmentEmail:', error);
        return null;
      }
    }
    
    return null;
  });

