# Payment Dashboard User Guide

## Overview

The Payment Dashboard is a comprehensive tool for tracking driver compensation and payment status. It provides role-based views for both drivers and administrators.

## Table of Contents
- [Accessing the Dashboard](#accessing-the-dashboard)
- [Dashboard Components](#dashboard-components)
- [Filtering and Searching](#filtering-and-searching)
- [Admin Features](#admin-features)
- [Understanding Payment Data](#understanding-payment-data)
- [Troubleshooting](#troubleshooting)

---

## Accessing the Dashboard

### For Drivers

1. **Log in** to the app with your driver credentials
2. Look for the **💳 Payment icon** in the top app bar (to the right of notifications)
3. Tap the icon to view your payment history

**What You'll See:**
- Only your own payments
- Summary of your total pending and paid amounts
- List of all your payments with details

### For Admins

1. **Log in** to the app with admin credentials
2. Tap the **☰ menu icon** (hamburger menu) in the top left
3. Select **Payment Dashboard** from the drawer menu

**What You'll See:**
- All payments across all drivers
- Additional filtering options by driver
- Ability to mark payments as paid
- Bulk payment actions

---

## Dashboard Components

### 1. Summary Cards (Top Section)

Four cards displaying key metrics:

#### 💰 Total Pending Payments
- Shows sum of all unpaid payments
- Orange color indicates pending status
- Includes count of pending payments

#### ✅ Total Paid Payments
- Shows sum of all completed payments
- Green color indicates paid status
- Includes count of paid payments

#### 📊 Payment Count
- Total number of payment records
- Useful for tracking payment volume

#### 💵 Average Payment
- Average payment amount
- Calculated across all payments (pending + paid)

### 2. Search Bar

Located below summary cards:
- Search by **Load Number** (e.g., "LOAD-001")
- Search by **Payment ID**
- Search by **Driver Name** (admin view)
- Real-time search as you type

### 3. Filter Controls

#### Status Filter Chips
- **All**: Show all payments
- **Pending** 🟠: Show only unpaid payments
- **Paid** 🟢: Show only completed payments

#### Date Range Picker
- Click **Date Range** chip to select custom dates
- Filter payments created or paid within the selected range
- Clear filter by clicking the ❌ icon

#### Driver Filter (Admin Only)
- Click **Driver** chip to select a specific driver
- View payments for that driver only
- Clear by selecting "All Drivers"

### 4. Payment List

Each payment card displays:

**Header:**
- **Amount** (large, green text) - Driver's payment amount
- **Status Badge** (right side) - Pending (orange) or Paid (green)

**Details:**
- 📦 **Load Number** - Associated load reference
- 👤 **Driver Name** - (Admin view only)
- 💵 **Load Rate** - Original load amount (100%)
- 📊 **Commission Rate** - Percentage driver receives (e.g., "85%")
- 📅 **Created Date** - When payment was created
- ✅ **Payment Date** - When payment was completed (if paid)

**Actions (Admin Only):**
- **Mark as Paid** button for pending payments
- Checkbox for bulk selection

---

## Filtering and Searching

### Basic Filtering

**Filter by Status:**
1. Tap any status chip (All, Pending, Paid)
2. List updates immediately
3. Summary cards update to show filtered totals

**Filter by Date:**
1. Tap **Date Range** chip
2. Select start and end dates
3. Tap OK to apply filter
4. Clear by tapping the ❌ icon next to the chip

**Search:**
1. Type in the search bar
2. Results filter as you type
3. Clear search by tapping ❌ in search bar

### Advanced Filtering (Admin)

**Combine Multiple Filters:**
1. Select a status filter (e.g., Pending)
2. Add a date range
3. Select a specific driver
4. Add a search term

All filters work together to narrow results.

**Example Use Cases:**
- Find all pending payments for a specific driver
- View payments made in the last month
- Search for a specific load's payment

---

## Admin Features

### Marking Payments as Paid

**Single Payment:**
1. Find the pending payment in the list
2. Scroll to the bottom of the payment card
3. Tap **Mark as Paid** button
4. Confirmation message appears
5. Payment status updates to "Paid" with timestamp

**Bulk Payments:**
1. Tap multiple payment cards to select them
2. Selected cards show a checkbox ✓
3. A badge appears in the app bar showing selection count
4. Tap the ✓ icon in the app bar
5. All selected payments are marked as paid

**Tips:**
- Use filters to show only pending payments for easier selection
- Verify amounts before marking as paid
- Payment dates are automatically recorded

### Driver Management

**Viewing Driver Payments:**
1. Tap the **Driver** filter chip
2. Select a driver from the list
3. View all payments for that driver
4. Summary cards update to show that driver's totals

**Use Cases:**
- Review a driver's payment history before issuing payment
- Verify driver earnings for a specific period
- Audit individual driver compensation

---

## Understanding Payment Data

### Payment Lifecycle

1. **Load Delivered**: Driver completes and delivers a load
2. **Payment Created**: System automatically creates a pending payment record
3. **Admin Review**: Admin reviews and verifies the payment
4. **Mark as Paid**: Admin marks payment as paid when funds are transferred
5. **Completed**: Payment status changes to "Paid" with date recorded

### Payment Calculation

**Formula:**
```
Driver Payment = Load Rate × Commission Rate
```

**Example:**
- Load Rate: $1,000.00
- Commission Rate: 85%
- Driver Payment: $850.00

**Notes:**
- Commission rate is configurable by admin
- Each payment stores the rate used at creation time
- Historical rates are preserved even if rate changes

### Payment Status

**🟠 Pending:**
- Payment has been calculated
- Waiting for admin to process payment
- Driver has not yet received funds
- Can be marked as paid by admin

**🟢 Paid:**
- Payment has been completed
- Payment date is recorded
- Driver has received compensation
- Cannot be changed (read-only)

### Commission Rates

The system supports configurable commission rates:
- Default: 85% (driver receives 85%, company keeps 15%)
- Can be changed by admin in settings
- Each payment stores the rate used at creation
- Historical payments maintain their original rates

---

## Troubleshooting

### "Firestore Index Required" Error

**Cause**: The payment queries require Firestore composite indexes.

**Solution:**
1. Follow the error message instructions
2. Run: `firebase deploy --only firestore:indexes`
3. Wait 2-5 minutes for indexes to build
4. Refresh the dashboard

**Required Indexes:**
- driverId + createdAt (descending)
- driverId + status + createdAt (descending)
- driverId + status + paymentDate (descending)

### No Payments Displayed

**For Drivers:**
- Ensure you have completed loads
- Check that loads were marked as "delivered"
- Verify your driver ID is correctly associated with loads

**For Admins:**
- Verify Firestore has payment records
- Check Firebase Console → Firestore → payments collection
- Ensure indexes are deployed and enabled

### Permission Denied Errors

**Check Authentication:**
- Ensure you're logged in
- Try logging out and back in
- Verify your account has the correct role (driver/admin)

**Check Firestore Rules:**
- Drivers can only read their own payments
- Admins can read all payments and mark as paid
- See FIRESTORE_RULES.md for details

### Summary Cards Show $0.00

**Possible Causes:**
1. No payments exist in the system
2. All payments are filtered out by current filters
3. Data loading issue

**Solutions:**
1. Clear all filters (status, date, driver, search)
2. Pull down to refresh the data
3. Check Firestore Console for payment records
4. Verify Firebase connection

### Search Not Working

**Tips:**
- Search is case-insensitive
- Try shorter search terms
- Clear other filters that might conflict
- Ensure you're searching for valid data (load IDs that exist)

### Date Range Filter Issues

**Common Issues:**
1. **No results**: Date range might be too narrow
2. **Wrong results**: Verify you selected the correct dates
3. **Filter not clearing**: Tap the ❌ icon next to Date Range chip

**Date Filter Logic:**
- Filters by payment creation date OR payment date (if paid)
- Inclusive of start and end dates
- Time is ignored (whole day included)

---

## Best Practices

### For Drivers

1. **Regular Checks**: Review your payment dashboard weekly
2. **Verify Amounts**: Check that payment amounts match load rates
3. **Track Status**: Monitor pending payments for delays
4. **Date Tracking**: Use date filters to review monthly earnings

### For Admins

1. **Timely Processing**: Review and process pending payments regularly
2. **Verification**: Double-check amounts before marking as paid
3. **Batch Processing**: Use bulk actions for multiple payments
4. **Record Keeping**: Use date filters to generate monthly reports
5. **Driver Communication**: Notify drivers when payments are processed

### Data Management

1. **Refresh Regularly**: Pull down to refresh data
2. **Clear Filters**: Reset filters to see full picture
3. **Export Data**: Consider exporting for external record-keeping (future feature)
4. **Monitor Totals**: Use summary cards to track overall payment status

---

## Screenshots

<!-- Placeholder for future screenshots -->

### Driver View
_Screenshot of driver payment dashboard will be added here_

### Admin View
_Screenshot of admin payment dashboard will be added here_

### Payment Details
_Screenshot of payment card details will be added here_

### Bulk Actions
_Screenshot of bulk payment selection will be added here_

---

## Related Documentation

- **Payment System Guide**: See `PAYMENT_SYSTEM_GUIDE.md` for technical details
- **Firestore Rules**: See `FIRESTORE_RULES.md` for security configuration
- **Quick Reference**: See `QUICK_REFERENCE.md` for quick navigation tips
- **API Documentation**: See payment service source code for developer details

---

## Support

For technical issues or questions:
1. Check this guide first
2. Review error messages carefully
3. Check Firebase Console for data verification
4. Contact your system administrator
5. See Firestore logs for debugging

---

**Last Updated**: 2026-02-14  
**Version**: 1.0.0
