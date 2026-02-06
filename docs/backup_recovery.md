# Database Backup & Recovery Guide

Comprehensive guide for backing up and recovering Firestore data for GUD Express.

## Overview

This guide covers:
- Automated Firestore backups
- Manual backup procedures
- Data export and import
- Disaster recovery procedures
- Testing recovery processes

---

## Firestore Backup Strategy

### Automated Backups

Firebase provides automated managed backups:

**Setup Steps:**

1. **Enable Backup Service**
   ```bash
   # Install Firebase CLI
   npm install -g firebase-tools
   
   # Login to Firebase
   firebase login
   
   # Set current project
   firebase use your-project-id
   ```

2. **Configure Backup Schedule**
   
   Using Firebase Console:
   - Go to: Firestore Database > Backups
   - Click "Set up backups"
   - Choose backup location (same region as database)
   - Set retention period (7-365 days)
   - Enable daily backups

3. **Using gcloud CLI:**
   ```bash
   # Set project
   gcloud config set project your-project-id
   
   # Create backup schedule
   gcloud firestore backups schedules create \
     --database='(default)' \
     --retention=7d \
     --recurrence=daily
   
   # Verify schedule
   gcloud firestore backups schedules list
   ```

### Backup Retention Policy

**Recommended retention:**
- **Daily backups:** 7 days
- **Weekly backups:** 4 weeks
- **Monthly backups:** 12 months
- **Yearly backups:** 5 years (for compliance)

**Cost considerations:**
- Backups incur storage costs
- Balance retention with budget
- Archive old backups to cheaper storage

---

## Manual Backup Procedures

### Export Firestore Data

**Using Firebase CLI:**

```bash
# Export all collections
firebase firestore:export gs://your-bucket-name/backups/$(date +%Y%m%d)

# Export specific collections
firebase firestore:export gs://your-bucket-name/backups/$(date +%Y%m%d) \
  --collections loads,drivers,users

# Export with parallelism for faster backup
firebase firestore:export gs://your-bucket-name/backups/$(date +%Y%m%d) \
  --parallelism=50
```

**Using gcloud CLI:**

```bash
# Export entire database
gcloud firestore export gs://your-bucket-name/backups/$(date +%Y%m%d)

# Export specific collections
gcloud firestore export gs://your-bucket-name/backups/$(date +%Y%m%d) \
  --collection-ids=loads,drivers,users

# Check export status
gcloud firestore operations list
```

### Export to JSON (for small datasets)

**Node.js Script:**

```javascript
const admin = require('firebase-admin');
const fs = require('fs');

admin.initializeApp();
const db = admin.firestore();

async function exportCollection(collectionName) {
  const snapshot = await db.collection(collectionName).get();
  const data = {};
  
  snapshot.forEach(doc => {
    data[doc.id] = doc.data();
  });
  
  fs.writeFileSync(
    `./backups/${collectionName}-${Date.now()}.json`,
    JSON.stringify(data, null, 2)
  );
  
  console.log(`Exported ${collectionName}: ${snapshot.size} documents`);
}

async function exportAll() {
  await exportCollection('users');
  await exportCollection('drivers');
  await exportCollection('loads');
  await exportCollection('pods');
  await exportCollection('expenses');
  await exportCollection('geofences');
  console.log('Export complete!');
}

exportAll().catch(console.error);
```

**Run the script:**
```bash
node export-firestore.js
```

### Scheduled Backups with Cron

**crontab example:**
```bash
# Daily backup at 2 AM
0 2 * * * firebase firestore:export gs://your-bucket/backups/$(date +\%Y\%m\%d)

# Weekly backup on Sunday at 3 AM
0 3 * * 0 firebase firestore:export gs://your-bucket/weekly/$(date +\%Y\%m\%d)
```

---

## Data Import/Restore

### Restore from Backup

**Using Firebase CLI:**

```bash
# Import from exported data
firebase firestore:import gs://your-bucket-name/backups/20240201

# Import specific collections
firebase firestore:import gs://your-bucket-name/backups/20240201 \
  --collections loads,drivers
```

**Using gcloud CLI:**

```bash
# Import entire backup
gcloud firestore import gs://your-bucket-name/backups/20240201

# Import specific collections
gcloud firestore import gs://your-bucket-name/backups/20240201 \
  --collection-ids=loads,drivers
```

### Import from JSON

**Node.js Script:**

```javascript
const admin = require('firebase-admin');
const fs = require('fs');

admin.initializeApp();
const db = admin.firestore();

async function importCollection(collectionName, filePath) {
  const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  const batch = db.batch();
  let count = 0;
  
  Object.entries(data).forEach(([docId, docData]) => {
    const ref = db.collection(collectionName).doc(docId);
    batch.set(ref, docData);
    count++;
    
    // Firestore batch limit is 500 operations
    if (count % 500 === 0) {
      batch.commit();
      batch = db.batch();
    }
  });
  
  if (count % 500 !== 0) {
    await batch.commit();
  }
  
  console.log(`Imported ${collectionName}: ${count} documents`);
}

async function importAll() {
  await importCollection('users', './backups/users-backup.json');
  await importCollection('drivers', './backups/drivers-backup.json');
  await importCollection('loads', './backups/loads-backup.json');
  console.log('Import complete!');
}

importAll().catch(console.error);
```

---

## Cloud Storage Backup

### Backup POD Images

**Sync to different bucket:**

```bash
# Copy all POD images to backup bucket
gsutil -m rsync -r gs://your-bucket/pods gs://backup-bucket/pods-$(date +%Y%m%d)

# Archive old PODs to nearline storage (cheaper)
gsutil -m rsync -r gs://your-bucket/pods gs://archive-bucket/pods-$(date +%Y%m%d)
gsutil rewrite -s nearline gs://archive-bucket/pods-$(date +%Y%m%d)/**
```

**Download all PODs locally:**

```bash
# Download to local directory
gsutil -m cp -r gs://your-bucket/pods ./backups/pods-$(date +%Y%m%d)
```

---

## Disaster Recovery

### Recovery Time Objective (RTO)

**Target:** 4 hours maximum downtime

**Procedure:**

1. **Assess damage** (15 minutes)
   - Identify what data is lost
   - Determine last good backup
   - Estimate recovery time

2. **Prepare new environment** (30 minutes)
   - Create new Firebase project if needed
   - Configure security rules
   - Set up authentication

3. **Restore data** (2-3 hours)
   - Import Firestore backup
   - Restore Cloud Storage files
   - Verify data integrity

4. **Test and validate** (30 minutes)
   - Test app functionality
   - Verify all data restored
   - Check user access

5. **Go live** (15 minutes)
   - Update DNS/redirects if needed
   - Notify users
   - Monitor for issues

### Recovery Point Objective (RPO)

**Target:** Maximum 24 hours of data loss

- Daily backups ensure at most 24 hours of data loss
- For critical operations, increase to hourly backups
- Consider transaction logging for zero-data-loss

---

## Disaster Scenarios

### Scenario 1: Accidental Data Deletion

**Symptoms:**
- Users report missing data
- Collection or documents deleted

**Recovery:**
1. Stop all writes immediately
2. Identify what was deleted
3. Find most recent backup before deletion
4. Import only affected collections
5. Verify restoration
6. Resume normal operations

**Prevention:**
- Use Firestore security rules to prevent accidental deletions
- Implement soft deletes (mark as deleted, don't actually delete)
- Require confirmation for bulk operations

### Scenario 2: Database Corruption

**Symptoms:**
- Inconsistent data
- App errors
- Data integrity issues

**Recovery:**
1. Create snapshot of current state (for forensics)
2. Restore from last known good backup
3. Replay transactions since backup if possible
4. Manually fix any inconsistencies
5. Update app to prevent future corruption

**Prevention:**
- Use Firestore transactions for critical operations
- Validate data before writing
- Regular data integrity checks

### Scenario 3: Ransomware/Security Breach

**Symptoms:**
- Unauthorized access
- Data encryption by attacker
- Firestore rules modified

**Recovery:**
1. **Immediate actions:**
   - Revoke all API keys
   - Change all passwords
   - Block suspicious IPs
   - Disable compromised accounts

2. **Assess damage:**
   - Identify what was accessed/modified
   - Check audit logs
   - Determine breach timeline

3. **Restore from backup:**
   - Use backup from before breach
   - Don't restore compromised data

4. **Security hardening:**
   - Update security rules
   - Enable App Check
   - Implement stricter authentication
   - Add rate limiting

5. **Notification:**
   - Notify affected users
   - Report to authorities if required
   - Prepare incident report

**Prevention:**
- Regular security audits
- Strong authentication (2FA)
- Monitor for suspicious activity
- Keep backups offline/immutable
- Implement least privilege access

### Scenario 4: Regional Outage

**Symptoms:**
- Firebase region unavailable
- Cannot access data
- App not functional

**Recovery:**
1. Check Firebase status page
2. Wait for Google to resolve (if temporary)
3. Or restore to different region:
   - Create new Firebase project in different region
   - Import latest backup
   - Update app configuration
   - Redirect traffic

**Prevention:**
- Use multi-region Firestore (if available)
- Have backup Firebase project ready
- Document region failover procedures
- Test failover process regularly

---

## Testing Recovery Procedures

### Monthly Recovery Drill

**Steps:**

1. **Select backup to test**
   - Choose random backup from last month
   - Verify backup integrity

2. **Create test environment**
   - Create new Firebase test project
   - Configure same security rules

3. **Perform restore**
   - Import backup to test project
   - Time the process
   - Document any issues

4. **Validate data**
   - Check record counts
   - Verify data integrity
   - Test app functionality

5. **Document results**
   - Record time taken
   - Note any problems
   - Update procedures

6. **Cleanup**
   - Delete test project
   - Archive test results

### Annual Full Disaster Recovery Test

**Simulate complete failure:**

1. **Pre-test preparation**
   - Schedule test window
   - Notify team
   - Prepare test environment

2. **Execute test**
   - Simulate total data loss
   - Follow full DR procedures
   - Time each step

3. **Validation**
   - Full app testing
   - User acceptance testing
   - Performance testing

4. **Review**
   - Team debrief
   - Update DR procedures
   - Identify improvements

---

## Backup Monitoring

### Check Backup Status

**Firebase Console:**
- Firestore > Backups
- Verify latest backup date
- Check backup status (Success/Failed)

**gcloud CLI:**
```bash
# List recent backups
gcloud firestore backups list --limit=10

# Get backup details
gcloud firestore backups describe BACKUP_NAME
```

### Automated Monitoring

**Cloud Function to monitor backups:**

```javascript
const functions = require('firebase-functions');
const nodemailer = require('nodemailer');

exports.checkBackupStatus = functions.pubsub
  .schedule('0 8 * * *') // Daily at 8 AM
  .onRun(async (context) => {
    // Check if backup completed successfully
    const lastBackup = await getLastBackupStatus();
    
    if (!lastBackup || lastBackup.status !== 'SUCCESS') {
      await sendAlert({
        subject: 'Firestore Backup Failed',
        body: `Last backup status: ${lastBackup?.status || 'NOT FOUND'}`
      });
    }
    
    return null;
  });
```

### Alerts to Configure

- Backup failure
- Backup older than 25 hours
- Backup size anomalies (too large/small)
- Restore operation initiated
- Storage bucket access errors

---

## Data Export for Compliance

### GDPR/CCPA Data Export

**Export user data:**

```javascript
async function exportUserData(userId) {
  const userData = {
    profile: null,
    loads: [],
    expenses: [],
    locations: []
  };
  
  // Get user profile
  const userDoc = await db.collection('users').doc(userId).get();
  userData.profile = userDoc.data();
  
  // Get user's loads
  const loadsSnapshot = await db.collection('loads')
    .where('driverId', '==', userId)
    .get();
  loadsSnapshot.forEach(doc => {
    userData.loads.push({ id: doc.id, ...doc.data() });
  });
  
  // Get user's expenses
  const expensesSnapshot = await db.collection('expenses')
    .where('driverId', '==', userId)
    .get();
  expensesSnapshot.forEach(doc => {
    userData.expenses.push({ id: doc.id, ...doc.data() });
  });
  
  // Export to JSON
  return JSON.stringify(userData, null, 2);
}
```

### Data Deletion for Compliance

**Delete user data:**

```javascript
async function deleteUserData(userId) {
  const batch = db.batch();
  
  // Delete user profile
  batch.delete(db.collection('users').doc(userId));
  
  // Delete user's loads
  const loads = await db.collection('loads')
    .where('driverId', '==', userId)
    .get();
  loads.forEach(doc => batch.delete(doc.ref));
  
  // Delete user's expenses
  const expenses = await db.collection('expenses')
    .where('driverId', '==', userId)
    .get();
  expenses.forEach(doc => batch.delete(doc.ref));
  
  // Commit batch
  await batch.commit();
  
  // Delete POD images from Storage
  const bucket = admin.storage().bucket();
  await bucket.deleteFiles({
    prefix: `pods/${userId}/`
  });
}
```

---

## Backup Best Practices

### Do's ✅

- **Automate backups** - Manual backups are unreliable
- **Test restores** - Untested backups are useless
- **Multiple locations** - Store backups in different regions
- **Document procedures** - Keep DR documentation current
- **Monitor backups** - Alert on failures
- **Encrypt backups** - Protect sensitive data
- **Version backups** - Keep multiple backup versions
- **Access control** - Limit who can delete backups

### Don'ts ❌

- **Don't** rely on single backup
- **Don't** store backups in same location as production
- **Don't** ignore backup failures
- **Don't** forget to test restores
- **Don't** keep backups forever (manage costs)
- **Don't** give everyone backup access
- **Don't** backup to unencrypted storage

---

## Emergency Contacts

**Backup/Recovery Issues:**
- **Primary:** devops@gudexpress.com
- **Secondary:** tech-lead@gudexpress.com
- **Emergency:** +1-XXX-XXX-XXXX

**Google Cloud Support:**
- Create support case in GCP Console
- Priority based on support plan level

**Firebase Support:**
- firebase.google.com/support
- stackoverflow.com/questions/tagged/firebase

---

## Backup Checklist

### Daily
- [ ] Verify automated backup completed
- [ ] Check backup size (should be consistent)
- [ ] Review any backup errors

### Weekly
- [ ] Test restore from random backup
- [ ] Review backup retention policy
- [ ] Check backup storage costs

### Monthly
- [ ] Full recovery drill
- [ ] Update DR documentation
- [ ] Review and optimize backup strategy
- [ ] Audit backup access logs

### Quarterly
- [ ] Full disaster recovery test
- [ ] Review RTO/RPO targets
- [ ] Update recovery procedures
- [ ] Team training on recovery

### Annually
- [ ] Archive old backups
- [ ] Review backup costs
- [ ] Update contracts/SLAs
- [ ] Audit compliance requirements

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.0 | 2024-02 | Added automated monitoring |
| 1.0 | 2024-01 | Initial backup procedures |
