# Expense Tracking Guide

## Overview

The GUD Express app includes comprehensive expense tracking for both administrators and drivers. This guide explains how to use the expense management features.

---

## For Administrators

### Accessing Expense Management

1. Login as an admin
2. From the admin home screen, tap the **Receipt icon** (📄) floating action button
3. This opens the Expense Management screen

### Viewing Expenses

The Expenses screen shows:
- **Category filters**: Filter expenses by category (fuel, maintenance, tolls, insurance, other)
- **Total expenses**: Running total of all expenses
- **Expense list**: All expenses sorted by date (most recent first)

Each expense card displays:
- Category icon and color
- Description
- Category name
- Date
- Amount

### Adding a New Expense

1. From the Expenses screen, tap the **+ (Add)** button
2. Fill in the expense details:
   - **Amount**: Enter the expense amount (required, must be > 0)
   - **Category**: Select from dropdown (fuel, maintenance, tolls, insurance, other)
   - **Description**: Enter a description of the expense (required)
   - **Date**: Select the date of the expense
   - **Driver**: Optionally assign to a specific driver
3. Tap **Add Expense** to save

### Viewing Expense Details

1. Tap on any expense in the list
2. A dialog shows full details:
   - Amount
   - Category
   - Description
   - Date
   - Driver ID (if assigned)
   - Load ID (if assigned)

### Deleting an Expense

1. Tap on an expense to view details
2. Tap the **Delete** button
3. Confirm deletion in the dialog

---

## For Drivers

### Accessing My Expenses

1. Login as a driver
2. From the driver home screen, tap the **Receipt icon** (📄) in the app bar
3. This opens the My Expenses screen

### Viewing Your Expenses

The Driver Expenses screen shows:
- **Total expenses**: Your total personal expenses
- **Category breakdown**: Expenses grouped by category
- **Recent expenses**: List of all your expenses sorted by date

### Understanding Net Earnings

1. From the driver home screen, tap the **Money icon** ($) in the app bar
2. The earnings screen now shows:
   - **Gross Earnings**: Total from completed loads
   - **Total Expenses**: Sum of all your expenses
   - **Net Earnings**: Gross earnings minus expenses
3. Tap **View My Expenses** to see expense details

---

## Expense Categories

The app supports these expense categories:

| Category | Icon | Common Uses |
|----------|------|-------------|
| **Fuel** | ⛽ | Gas, diesel, fuel cards |
| **Maintenance** | 🔧 | Repairs, oil changes, tire replacements |
| **Tolls** | 🛣️ | Highway tolls, bridge fees |
| **Insurance** | 🛡️ | Vehicle insurance, cargo insurance |
| **Other** | 💵 | Parking, meals, supplies |

---

## Best Practices

### For Administrators

1. **Regular Review**: Review expenses weekly to track spending trends
2. **Category Consistency**: Ensure expenses are categorized correctly
3. **Driver Assignment**: Always assign driver-specific expenses to the correct driver
4. **Documentation**: Encourage receipt uploads (future feature)

### For Drivers

1. **Track Everything**: Log all trip-related expenses
2. **Timely Entry**: Enter expenses as they occur
3. **Accurate Descriptions**: Be specific in expense descriptions
4. **Category Selection**: Choose the most appropriate category
5. **Monitor Net Earnings**: Regularly check your net earnings to understand profitability

---

## Data Storage

All expense data is stored securely in Firebase Firestore with the following structure:

```
expenses/{expenseId}
├── amount: number
├── category: string
├── description: string
├── date: timestamp
├── driverId: string (optional)
├── loadId: string (optional)
├── receiptUrl: string (optional)
├── createdBy: string
└── createdAt: timestamp
```

---

## Future Enhancements

Planned features for expense tracking:
- 📷 Receipt image upload and storage
- 📊 Expense analytics and trends
- 📧 Export expense reports to PDF/CSV
- 💳 Receipt OCR for automatic data entry
- 🔔 Budget alerts and notifications
- 🏷️ Custom expense categories
- 📅 Recurring expense templates

---

## Security

- Drivers can only view their own expenses
- Admins can view all expenses
- Only admins can delete expenses
- All data is encrypted in transit and at rest
- Access is controlled via Firebase security rules

---

## Troubleshooting

### Cannot see expenses
- Ensure you're logged in with the correct account
- Check that expenses have been created for your driver ID

### Cannot add expense
- Verify all required fields are filled
- Ensure amount is greater than 0
- Check your internet connection

### Expense not updating
- Pull down to refresh the list
- Check Firestore security rules are deployed
- Verify your authentication token is valid

---

## Support

For issues or questions about expense tracking:
1. Check this guide first
2. Review the Statistics Dashboard for data verification
3. Contact your system administrator
4. Check Firebase Console for data integrity

---

**Last Updated**: 2026-02-02
