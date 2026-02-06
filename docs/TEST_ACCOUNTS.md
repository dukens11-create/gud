# Test Accounts for GUD Express

**Last Updated:** February 6, 2026  
**Version:** 1.0

This document provides test account credentials and instructions for app store reviewers and internal testing.

---

## ⚠️ IMPORTANT: For App Store Reviewers

These test accounts are provided specifically for app review purposes. They contain pre-populated sample data to demonstrate all features of GUD Express.

**Credentials are case-sensitive. Please copy/paste to avoid typos.**

---

## Test Account Credentials

### Admin Test Account

**Purpose:** Full administrative access to demonstrate all admin features

**Credentials:**
- **Email:** admin@gudexpress-test.com
- **Password:** TestAdmin123!
- **Role:** Administrator

**Access Level:**
- Full access to all features
- Can view all loads and drivers
- Can create, edit, and delete loads
- Can manage driver accounts
- Can generate reports and export data
- Can view all statistics

**Pre-loaded Data:**
- 5 sample loads (various statuses)
- 3 driver accounts
- Sample POD photos
- Historical data for reporting
- Earnings and expense records

---

### Driver Test Account

**Purpose:** Demonstrate driver-specific features and workflows

**Credentials:**
- **Email:** driver@gudexpress-test.com
- **Password:** TestDriver123!
- **Role:** Driver

**Access Level:**
- View assigned loads only
- Start and complete trips
- Upload proof of delivery
- Track personal earnings
- View trip history
- Record expenses

**Pre-loaded Data:**
- 2 assigned loads (pending)
- 3 completed loads (with PODs)
- Earnings history
- Expense records
- Sample delivery photos

---

### Secondary Driver Account (Additional Testing)

**Purpose:** For testing driver assignment and multi-driver scenarios

**Credentials:**
- **Email:** driver2@gudexpress-test.com
- **Password:** TestDriver123!
- **Role:** Driver

**Access Level:** Same as primary driver account

**Pre-loaded Data:**
- 1 assigned load (in progress)
- 2 completed loads
- Different earnings amounts
- Expense history

---

## Test Data Overview

### Sample Loads

The admin account has access to the following sample loads:

**Load 1: Pending Load**
- Status: Pending
- Pickup: Chicago, IL
- Delivery: Detroit, MI
- Assigned to: Test Driver
- Rate: $1,200
- Purpose: Test load assignment and trip start

**Load 2: In Progress Load**
- Status: In Progress
- Pickup: New York, NY
- Delivery: Boston, MA
- Assigned to: Driver 2
- Rate: $800
- Purpose: Test trip tracking and location sharing

**Load 3: Delivered Load**
- Status: Delivered
- Pickup: Los Angeles, CA
- Delivery: San Francisco, CA
- Assigned to: Test Driver
- Rate: $650
- POD: Photo uploaded
- Purpose: Test completed workflow and POD viewing

**Load 4: Cancelled Load**
- Status: Cancelled
- Pickup: Houston, TX
- Delivery: Austin, TX
- Reason: Customer cancellation
- Purpose: Test cancelled load handling

**Load 5: Available Load**
- Status: Available (unassigned)
- Pickup: Miami, FL
- Delivery: Orlando, FL
- Rate: $400
- Purpose: Test load assignment workflow

### Sample Drivers

**Driver 1: John Doe (driver@gudexpress-test.com)**
- Truck Number: TRK-001
- Status: Active
- Loads Completed: 3
- Total Earnings: $2,650

**Driver 2: Jane Smith (driver2@gudexpress-test.com)**
- Truck Number: TRK-002
- Status: Active
- Loads Completed: 2
- Total Earnings: $1,600

**Driver 3: Mike Johnson**
- Truck Number: TRK-003
- Status: Active
- Loads Completed: 5
- Total Earnings: $4,200

### Sample POD Photos

- 3 professional delivery photos showing:
  - Loading dock with delivered goods
  - Package at delivery location
  - Warehouse with timestamp

All photos are properly sized and demonstrate the POD feature.

---

## Testing Instructions for Reviewers

### Testing Admin Features (10-15 minutes)

**Step 1: Login as Admin**
1. Open GUD Express app
2. Enter email: `admin@gudexpress-test.com`
3. Enter password: `TestAdmin123!`
4. Tap "Sign In"

**Step 2: View Dashboard**
- You should see the admin dashboard
- 5 loads displayed with various statuses
- Search bar at the top
- Filter options available

**Step 3: View Load Details**
- Tap on any load from the list
- View complete load information:
  - Pickup and delivery addresses
  - Assigned driver
  - Rate and payment info
  - Status
- View POD photo (for delivered loads)

**Step 4: Create a New Load**
- Tap "+" or "Add Load" button
- Fill in load details:
  - Customer: "Test Customer"
  - Pickup: "Seattle, WA"
  - Delivery: "Portland, OR"
  - Rate: $500
  - Assign to: "Test Driver"
- Tap "Save" or "Create Load"
- New load should appear in list

**Step 5: View Drivers**
- Navigate to "Drivers" tab or menu
- View list of 3 drivers
- Tap on a driver to see details
- View driver's load history and earnings

**Step 6: View Statistics**
- Navigate to "Statistics" or "Reports"
- View dashboard with:
  - Total loads
  - Completed deliveries
  - Total revenue
  - Active drivers

**Step 7: Search and Filter**
- Use search bar to search for "Chicago"
- Apply filter for "Pending" status
- Results should update immediately

---

### Testing Driver Features (10-15 minutes)

**Step 1: Logout and Login as Driver**
1. Logout from admin account
2. Enter email: `driver@gudexpress-test.com`
3. Enter password: `TestDriver123!`
4. Tap "Sign In"

**Step 2: View Assigned Loads**
- You should see the driver dashboard
- 2 pending loads assigned to you
- Your total earnings displayed

**Step 3: View Load Details**
- Tap on a pending load
- View pickup and delivery information
- Note the "Start Trip" button

**Step 4: Start a Trip**
- Tap "Start Trip" on a pending load
- **Location Permission:** If prompted, tap "Allow While Using App"
- Trip should start
- Timer begins counting
- Status changes to "In Progress"

**Step 5: Share Location** (Optional Feature)
- During trip, tap "Share Location"
- Location should be shared with admin
- Map may show current location

**Step 6: Complete Trip and Upload POD**
- Tap "Complete Trip" button
- You'll be prompted to upload POD
- Tap "Take Photo" or "Choose from Library"
- **Camera Permission:** If prompted, tap "Allow"
- Take a photo (any photo is fine for testing)
- Add delivery note: "Delivered successfully"
- Tap "Upload POD" or "Complete Delivery"
- Load status changes to "Delivered"

**Step 7: View Earnings**
- Navigate to "Earnings" or "Statistics"
- View your total earnings
- See breakdown by load
- View paid vs unpaid loads

**Step 8: View History**
- Navigate to "History" or completed loads
- View 3 previously completed loads
- Each has POD photo attached
- Shows delivery dates and amounts

**Step 9: Record Expense** (If implemented)
- Navigate to "Expenses"
- Tap "Add Expense"
- Enter:
  - Type: Fuel
  - Amount: $150
  - Note: "Fuel for trip"
- Tap "Save"
- Expense appears in list

---

## Location Services Testing

**Location Permissions:**

**iOS:**
- First location request: "Allow While Using App" or "Allow Once"
- Location is only accessed during active trips
- Never tracked in background when app is closed
- No location access for admin users

**Android:**
- First location request: "Allow" or "While using the app"
- Location is only accessed during active trips
- Never tracked in background when app is closed
- No location access for admin users

**When Location is Requested:**
- ✅ Driver starts a trip
- ✅ Driver manually shares location
- ❌ When app is in background
- ❌ When no active trip
- ❌ For admin users

**Privacy Note:**
Drivers have full control over location sharing. Location is used solely for:
- Trip tracking during active deliveries
- Mileage calculation
- Delivery verification

---

## Camera and Photo Testing

**Camera Permissions:**

**iOS:**
- First camera request: "Allow" or "Don't Allow"
- Only requested when user taps "Take Photo"
- Also requests photo library access for uploading existing photos

**Android:**
- First camera request: "Allow" or "Deny"
- Only requested when user taps camera button
- Separate permission for photo library access

**When Camera is Requested:**
- ✅ Driver uploads POD photo
- ✅ Driver uploads expense receipt
- ❌ On app launch
- ❌ When viewing loads
- ❌ For admin users (they only view photos)

**Privacy Note:**
Camera access is used solely for:
- Proof of delivery photo capture
- Expense receipt documentation
- All photos are business-related only

---

## Known Test Data Limitations

**Please Note:**
1. **Test Data Only:** All data is for demonstration purposes
2. **Email Notifications:** May not work in test environment
3. **Push Notifications:** May be limited in test builds
4. **Real-time Sync:** Fully functional with Firebase
5. **Offline Mode:** Can be tested by turning off internet
6. **Payment Processing:** Not integrated (display only)

**Expected Behavior:**
- All core features are fully functional
- Test data is reset periodically
- No real customer or driver data
- All addresses and names are fictional

---

## Troubleshooting Test Accounts

### Issue: Cannot Login

**Solution:**
- Verify email is exactly: `admin@gudexpress-test.com` (no spaces)
- Password is case-sensitive: `TestAdmin123!`
- Check internet connection
- Try copying and pasting credentials

### Issue: No Loads Showing

**Solution:**
- Ensure logged in as admin (not driver)
- Pull down to refresh
- Check filter settings (ensure not filtering out all loads)
- Wait a moment for data to load from Firebase

### Issue: Cannot Start Trip

**Solution:**
- Ensure logged in as driver (not admin)
- Load must be "Pending" status
- Check that load is assigned to current driver
- Grant location permission if prompted

### Issue: Camera Not Opening

**Solution:**
- Grant camera permission in device settings
- iOS: Settings > Privacy > Camera > GUD Express
- Android: Settings > Apps > GUD Express > Permissions
- Try restarting the app

### Issue: POD Photo Not Uploading

**Solution:**
- Check internet connection
- Ensure photo is not too large (max 10MB)
- Grant storage permission if prompted
- Try a smaller photo

---

## Firebase Backend

**Test Environment:**
- **Database:** Firebase Firestore (production instance)
- **Authentication:** Firebase Auth
- **Storage:** Firebase Cloud Storage
- **Real-time:** All updates are real-time via Firestore listeners

**Data Persistence:**
- Test data is persistent
- Changes you make during testing will remain
- Data is reset monthly
- Other reviewers may see your test actions

**No Impact on Production:**
- Test accounts are isolated
- No real user data
- Separate from production users

---

## Additional Test Scenarios

### Scenario 1: Complete Load Workflow (Admin + Driver)

**As Admin:**
1. Login as admin
2. Create new load
3. Assign to "Test Driver"
4. Note the load details

**As Driver:**
1. Logout and login as driver
2. View newly assigned load
3. Start trip (allow location)
4. Complete trip
5. Upload POD photo
6. Add delivery note

**As Admin:**
1. Logout and login as admin
2. View completed load
3. See uploaded POD photo
4. Verify delivery note

### Scenario 2: Offline Functionality

1. Login as driver
2. Turn off WiFi and cellular data
3. Try to view loads (should work with cached data)
4. Start a trip (should queue)
5. Turn internet back on
6. Watch queued action sync

### Scenario 3: Search and Filter

1. Login as admin
2. Use search for "Chicago"
3. Filter by "Delivered" status
4. Clear filters
5. Search for driver name

---

## Security Notes

**Password Requirements:**
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number
- Special characters allowed

**Session Management:**
- Sessions persist until logout
- Automatic logout after 30 days of inactivity
- Secure token-based authentication

**Data Encryption:**
- All data transmitted over HTTPS
- Passwords stored encrypted in Firebase
- Photos stored securely in Cloud Storage

---

## Contact for Review Issues

If you encounter any issues during review:

**Email:** support@gudexpress.com  
**Subject:** "App Review - [Issue Description]"

**Provide:**
- Platform (iOS/Android)
- Device model and OS version
- Test account used
- Description of issue
- Screenshots if possible

**Response Time:** Within 24 hours (typically much faster)

---

## Post-Review

After approval, these test accounts will remain active for:
- Future app updates
- Screenshot updates
- Feature demonstrations
- Support team training

Test data will be refreshed monthly to maintain realistic scenarios.

---

## Thank You

Thank you for taking the time to review GUD Express. We've worked hard to create a professional, useful app for the trucking industry, and we appreciate your thorough review.

If you have any questions or need clarification on any features, please don't hesitate to contact us.

**The GUD Express Team**

---

**Document Version:** 1.0  
**Last Updated:** February 6, 2026  
**Prepared By:** GUD Express Team  
**For:** App Store Review Process
