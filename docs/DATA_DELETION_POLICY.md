# Data Deletion Policy for GUD Express

**Effective Date:** February 2024  
**Last Updated:** February 6, 2026

This Data Deletion Policy explains how users of the GUD Express mobile application can request deletion of their personal data, what data will be deleted, and the timeframes involved.

## 1. Overview

At GUD Express, we respect your right to privacy and control over your personal data. This policy outlines the process for requesting data deletion in compliance with:
- General Data Protection Regulation (GDPR)
- California Consumer Privacy Act (CCPA)
- Other applicable data protection laws

## 2. Who Can Request Data Deletion

### 2.1 Eligible Requesters

The following individuals may request data deletion:
- **Account Holders:** Any user with an active or inactive GUD Express account
- **Former Employees:** Drivers or staff no longer associated with the company
- **Legal Guardians:** Representatives of deceased or incapacitated users (with proper documentation)
- **Authorized Representatives:** Individuals with power of attorney or legal authorization

### 2.2 Verification Required

To protect your privacy and prevent unauthorized deletion:
- Identity verification is required for all requests
- We may request additional documentation
- Verification typically takes 1-3 business days

## 3. How to Request Data Deletion

### 3.1 In-App Deletion (Recommended)

**For Active Accounts:**
1. Log in to your GUD Express account
2. Navigate to Settings > Account
3. Select "Delete My Account"
4. Confirm your email address
5. Select what data to delete (see options below)
6. Enter your password to confirm
7. Submit deletion request

**Processing Time:** 1-30 days depending on data volume

### 3.2 Email Request

**For All Users (Active or Inactive):**

Send an email to: **datadeletion@gudexpress.com** or **privacy@gudexpress.com**

**Required Information:**
- Full name associated with the account
- Email address used for registration
- Phone number (if provided during registration)
- Reason for deletion (optional)
- Specify what data you want deleted (see Section 4)

**Subject Line:** "Data Deletion Request - [Your Email]"

**Example Email:**
```
Subject: Data Deletion Request - john.doe@example.com

Dear GUD Express Data Privacy Team,

I am requesting deletion of my personal data associated with my GUD Express account.

Account Details:
- Name: John Doe
- Email: john.doe@example.com
- Phone: (555) 123-4567
- Role: Driver

I would like to delete: [Complete Account Deletion / Specific Data - see options]

Please confirm receipt of this request and provide a timeline for completion.

Thank you,
John Doe
```

### 3.3 Phone Request

Call our support line: **(555) GUD-EXPRESS**
- Available: Monday-Friday, 9 AM - 5 PM EST
- Identity verification required
- Confirmation email will be sent

### 3.4 Mailing Address

**Written Request:**
```
GUD Express - Data Privacy Team
[Company Address]
[City, State ZIP]
```

Include:
- Your contact information
- Account details
- Signed authorization
- Copy of government-issued ID (optional, for faster processing)

## 4. What Data Gets Deleted

### 4.1 Complete Account Deletion

When you request complete account deletion, the following data will be permanently deleted:

**Account Information:**
- Email address
- Phone number
- Password and authentication credentials
- Profile information
- User preferences and settings

**Driver-Specific Data:**
- Truck number/assignment
- License information (non-regulatory)
- Performance metrics
- Ratings and feedback

**Activity Data:**
- App usage statistics
- Search history
- Preferences and customizations
- Device tokens and identifiers

**Photos and Media:**
- Proof of delivery photos (after retention period)
- Uploaded receipts and documents
- Profile pictures

**Communication Data:**
- In-app messages and notifications
- Support ticket history
- Feedback and comments

### 4.2 Partial Data Deletion Options

You may request deletion of specific data categories:

**Option 1: Account Data Only**
- Personal profile information
- Login credentials
- Device information
- Keep: Load history, financial records (for compliance)

**Option 2: Photos and Media**
- All uploaded photos
- Documents and receipts
- Keep: Account and load information

**Option 3: Location Data**
- GPS history and coordinates
- Route information
- Location sharing records
- Keep: Account, loads, and photos

**Option 4: Financial Data**
- Earnings records (after retention period)
- Expense reports
- Keep: Account and operational data

### 4.3 Data That May Be Retained

Certain data must be retained for legal, regulatory, or operational reasons:

**Regulatory Requirements (7 years):**
- Transaction records
- Financial statements and invoices
- Tax-related information
- DOT compliance records
- Safety inspection records

**Legal Obligations (varies):**
- Records subject to litigation hold
- Government audit requirements
- Dispute resolution records
- Compliance with subpoenas or court orders

**Legitimate Business Interests (30-90 days):**
- Fraud prevention records
- Security incident logs
- Backup data (until next purge cycle)
- Aggregated/anonymized analytics

**De-identified Data:**
- Anonymized usage statistics
- Aggregate performance metrics
- Research and development data
- Data with no personal identifiers

## 5. Deletion Timeframe

### 5.1 Standard Processing Timeline

**Phase 1: Request Receipt & Verification (1-3 business days)**
- Acknowledge receipt of request
- Verify identity and authorization
- Determine data scope and retention requirements

**Phase 2: Data Deletion (7-14 business days)**
- Delete data from primary systems
- Remove from active databases
- Delete from cloud storage (Firebase)
- Clear cached data

**Phase 3: Backup Deletion (30 days)**
- Purge from backup systems
- Remove from disaster recovery archives
- Delete from log files
- Final verification

**Total Time: 30-45 days maximum** (unless legal holds apply)

### 5.2 Expedited Processing

Expedited deletion (7-14 days) may be available:
- For active security concerns
- Identity theft situations
- With valid legal orders
- At our discretion

Request expedited processing by noting "URGENT" in your email subject line.

### 5.3 Delayed Processing

Deletion may be delayed if:
- Account is subject to legal hold
- Ongoing investigation or dispute
- Regulatory audit in progress
- Technical issues (we'll notify you)

We will notify you of any delays and provide:
- Reason for delay
- Expected resolution date
- Alternative options (if available)

## 6. Data Retention Requirements

### 6.1 Minimum Retention Periods

Some data must be retained even after deletion request:

**Financial Records: 7 years**
- Required by IRS and state tax laws
- Invoices and payment records
- Expense reports and reimbursements

**Transportation Records: 3-7 years**
- DOT compliance requirements
- Safety records and inspections
- Accident reports and investigations
- Driver qualification files

**Legal Holds: Indefinite**
- Litigation or investigation records
- Subpoenaed information
- Regulatory enforcement actions

**Security Logs: 1 year**
- Fraud prevention
- Breach investigation
- Abuse prevention

### 6.2 Retention After Deletion

After account deletion:
- Personal identifiers removed within 30 days
- Financial records retained per legal requirements
- Transaction history anonymized
- Aggregated analytics maintained (no personal data)

## 7. Backup Deletion Procedures

### 7.1 Backup Systems

Your data exists in multiple locations:

**Primary Systems:**
- Firebase Authentication
- Cloud Firestore database
- Firebase Cloud Storage
- Analytics platforms

**Backup Systems:**
- Automated daily backups (Firebase)
- Disaster recovery archives (30-day retention)
- Offline backup storage (monthly snapshots)
- Log files and audit trails

### 7.2 Backup Deletion Process

**Automated Backups:**
- Deleted data is overwritten in next backup cycle
- Typically within 30 days
- Old backups are automatically purged after 30 days

**Archive Backups:**
- Monthly archives retained for 90 days
- Deleted data removed in next purge cycle
- Cannot selectively delete from archives

**Disaster Recovery:**
- Replicated across Firebase regions
- Synchronized deletion across all regions
- May take up to 30 days for complete propagation

### 7.3 Verification

After deletion:
- Confirmation email sent to you
- Deletion certificate provided (upon request)
- Audit log entry created
- Cannot be reversed

## 8. Effect of Data Deletion

### 8.1 Immediate Effects

Once deletion is processed:

**Account Access:**
- Cannot log in to the app
- All sessions terminated
- Authentication credentials removed
- Account email marked as deleted

**App Functionality:**
- No access to loads or history
- Cannot upload new data
- Cannot view earnings or reports
- Push notifications stopped

**Admins Can No Longer See:**
- Your personal information
- Your profile details
- Your contact information
- Your app activity

**Admins Can Still See (anonymized):**
- Historical load assignments (Driver ID only)
- Completed deliveries (no name)
- Financial summaries (for accounting)

### 8.2 Cannot Be Undone

**Important:** Data deletion is permanent and irreversible.

- Deleted data cannot be recovered
- New account required to use service again
- Previous data will not be restored
- Must re-upload any needed documents

### 8.3 Re-Registration

After deletion, you may create a new account:
- Must use different email or wait 30 days to reuse
- Starts as completely new user
- No connection to previous account
- No historical data will be imported

## 9. Exceptions and Special Cases

### 9.1 Active Employees

If you are a current driver or employee:
- May need employer authorization
- Company data policies may apply
- Contact your administrator first
- Some data may be company property

### 9.2 Pending Transactions

If you have pending loads or payments:
- Deletion may be delayed until completion
- Must resolve outstanding issues first
- Option to delete after resolution
- Typically 30-day delay

### 9.3 Legal Disputes

If involved in:
- Litigation or arbitration
- Insurance claims
- Regulatory investigations
- Safety incidents

Data deletion will be suspended until resolved.

### 9.4 Third-Party Requests

If a third party (employer, customer, law enforcement) requires your data:
- We'll notify you when legally permitted
- May need to retain data longer
- Will delete after legal hold expires

## 10. Your Rights After Deletion

### 10.1 Confirmation

You have the right to:
- Receive confirmation of deletion
- Request deletion certificate
- Verify data has been removed
- Report incomplete deletion

### 10.2 Complaints

If you believe:
- Data was not fully deleted
- Deletion took too long
- Request was improperly denied
- Your rights were violated

**Contact:**
- Data Privacy Officer: dpo@gudexpress.com
- File a complaint with data protection authorities
- Seek legal recourse as applicable

### 10.3 Data Protection Authorities

**United States:**
- Federal Trade Commission (FTC)
- State Attorney General (for state laws)

**European Union:**
- Your national data protection authority
- EU Data Protection Board

**Other Jurisdictions:**
- Local data protection regulator

## 11. Changes to This Policy

This Data Deletion Policy may be updated to reflect:
- Changes in laws or regulations
- Updates to our data practices
- Improvements to the deletion process

**Notification of Changes:**
- Posted on our website and in the app
- Email notification to users
- "Last Updated" date changed

## 12. Contact Information

For data deletion requests or questions:

**Primary Contact:**  
Email: datadeletion@gudexpress.com  
Subject: "Data Deletion Request"

**Alternative Contact:**  
Email: privacy@gudexpress.com

**General Support:**  
Email: support@gudexpress.com  
Phone: (555) GUD-EXPRESS

**Data Protection Officer:**  
Email: dpo@gudexpress.com

**Mailing Address:**  
GUD Express - Data Privacy Team  
[Company Address]  
[City, State ZIP]  
[Country]

**Response Time:**  
- Acknowledgment: Within 3 business days
- Completion: Within 30-45 days
- Updates provided throughout process

## 13. Important Reminders

**Before Requesting Deletion:**
- Download any data you want to keep
- Export reports and invoices
- Save important documents
- Note that deletion is permanent

**Download Your Data:**
- Use the "Export Data" feature in app settings
- Or request data export via email
- Receive data in machine-readable format (JSON/CSV)
- Processing time: 7-14 days

**Alternatives to Deletion:**
- Deactivate account temporarily
- Remove specific data only
- Update privacy settings
- Opt out of marketing communications

---

**Document Version:** 1.0  
**Last Reviewed:** February 6, 2026  
**Next Review:** August 2026  
**Effective Date:** February 2024
