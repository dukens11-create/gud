# Statistics Dashboard Guide

## Overview

The GUD Express Statistics Dashboard provides comprehensive analytics and insights into your trucking operations. This guide explains how to use and interpret the dashboard data.

---

## Accessing the Dashboard

**Admin Only Feature**

1. Login as an administrator
2. From the admin home screen, tap the **Bar Chart icon** (📊) floating action button
3. This opens the Statistics Dashboard

---

## Dashboard Layout

The dashboard consists of several sections:

### 1. Period Selector

At the top of the screen, choose your analysis period:
- **Week**: Last 7 days
- **Month**: Current calendar month
- **Quarter**: Current fiscal quarter
- **Year**: Current calendar year
- **Custom**: Select specific date range

The selected date range is displayed below the selector.

### 2. Key Metrics Cards

#### Financial Metrics

**Total Revenue**
- Sum of all load rates in the selected period
- Includes loads with status: delivered, completed
- Color: Green 💚
- Icon: Dollar sign

**Total Expenses**
- Sum of all expenses in the selected period
- Includes all expense categories
- Color: Red ❤️
- Icon: Money off

**Net Profit** (Large Card)
- Calculated as: Revenue - Expenses
- This is your actual profit for the period
- Color: Green (profit) or Red (loss)
- Icon: Trending up

#### Operational Metrics

**Total Loads**
- Count of all loads in the period
- Includes loads of all statuses
- Color: Blue 💙
- Icon: Truck

**Delivered Loads**
- Count of successfully delivered loads
- Statuses: delivered, completed
- Color: Purple 💜
- Icon: Checkmarks

**Average Rate**
- Mean rate across all loads
- Formula: Total Revenue / Total Loads
- Color: Orange 🧡
- Icon: Calculator

**Rate Per Mile**
- Revenue efficiency metric
- Formula: Total Revenue / Total Miles
- Color: Teal 🩵
- Icon: Timeline

**Total Miles**
- Sum of all miles driven
- Helps track vehicle usage
- Color: Indigo 💙
- Icon: Route

### 3. Driver Performance Section

If viewing all drivers (not filtered), the dashboard shows individual driver statistics:

For each driver, you'll see:
- **Driver Name**
- **Revenue**: Total revenue generated
- **Loads**: Total loads assigned (delivered count)

This helps identify:
- Top performing drivers
- Underutilized drivers
- Revenue distribution across team

---

## Using the Dashboard

### Viewing Current Month

1. Tap **Month** chip
2. View metrics for the current calendar month
3. Scroll down to see driver performance

### Comparing Quarters

1. Tap **Quarter** chip
2. Review quarterly performance
3. Use this for quarterly reports

### Custom Date Range Analysis

1. Tap **Custom** chip
2. A date range picker appears
3. Select start and end dates
4. Tap **OK** to apply
5. Dashboard updates with custom range data

### Understanding Profitability

**Net Profit Card** is your most important metric:
- **Green**: You're profitable in this period
- **Red**: Expenses exceed revenue

Example:
```
Total Revenue: $15,000
Total Expenses: $8,500
Net Profit: $6,500 (43.3% margin)
```

### Monitoring Efficiency

**Rate Per Mile** indicates pricing efficiency:
- Higher is better
- Industry average: $1.50 - $2.50 per mile
- Low rates may indicate inefficient routes or underpricing

Example:
```
Total Revenue: $10,000
Total Miles: 5,000
Rate/Mile: $2.00 ✅ Good
```

---

## Key Performance Indicators (KPIs)

### Financial Health
- **Net Profit Margin**: (Net Profit / Revenue) × 100
  - Healthy: > 20%
  - Acceptable: 10-20%
  - Concerning: < 10%

### Operational Efficiency
- **Delivery Rate**: (Delivered / Total Loads) × 100
  - Excellent: > 95%
  - Good: 90-95%
  - Needs Improvement: < 90%

### Driver Performance
- **Average Revenue per Driver**: Total Revenue / Number of Drivers
- **Average Loads per Driver**: Total Loads / Number of Drivers

---

## Common Analysis Scenarios

### Weekly Operations Review

1. Select **Week** period
2. Check:
   - Are we on track for monthly targets?
   - Which drivers need more loads?
   - Are expenses normal for this period?

### Monthly Financial Close

1. Select **Month** period
2. Review:
   - Total revenue vs. target
   - Expense categories (check Expense Management)
   - Net profit margin
   - Driver performance rankings

### Quarterly Business Review

1. Select **Quarter** period
2. Analyze:
   - Quarter-over-quarter growth
   - Seasonal trends
   - Top performing drivers
   - Major expense areas

### Year-End Reports

1. Select **Year** period
2. Generate:
   - Annual revenue report
   - Total expenses by category
   - Driver performance reviews
   - Growth metrics

### Custom Analysis

Use **Custom** period for:
- Comparing specific time periods
- Analyzing holiday seasons
- Pre/post rate change comparison
- Driver onboarding impact

---

## Data Calculations

### Statistics are calculated in real-time from:

**Loads Collection**
- All loads with `createdAt` in date range
- Revenue from `rate` field
- Miles from `miles` field
- Status from `status` field

**Expenses Collection**
- All expenses with `date` in date range
- Amounts from `amount` field
- Categories from `category` field

**Drivers Collection**
- Active drivers
- Load assignments
- Revenue attribution

---

## Best Practices

### Daily Monitoring
1. Check dashboard each morning
2. Review previous day's deliveries
3. Monitor any unusual expense spikes

### Weekly Review
1. Every Monday, review previous week
2. Identify trends
3. Address any efficiency drops

### Monthly Analysis
1. First day of month, review previous month
2. Calculate month-over-month growth
3. Adjust strategies based on data

### Share with Stakeholders
1. Export key metrics (future feature)
2. Discuss with team in meetings
3. Use data to drive decisions

---

## Understanding Edge Cases

### No Data Displayed
- No loads/expenses in selected period
- All metrics will show 0

### Zero Rate Per Mile
- No miles recorded on loads
- Enter actual miles to see this metric

### Negative Net Profit
- Expenses exceed revenue
- Review expense management
- Consider rate adjustments

---

## Future Enhancements

Planned statistics features:
- 📈 Interactive charts and graphs
- 📊 Trend lines and forecasting
- 📧 Automated email reports
- 📄 PDF export functionality
- 📱 Push notifications for KPI alerts
- 🎯 Goal setting and tracking
- 📉 Expense category breakdowns with charts
- 🔄 Comparison with previous periods
- 💹 Revenue forecasting
- 📊 Driver leaderboards

---

## Troubleshooting

### Statistics not updating
- Pull down to refresh
- Check internet connection
- Verify Firestore rules are deployed

### Incorrect calculations
- Verify load statuses are correct
- Check expense entries for accuracy
- Ensure dates are set correctly

### Missing driver stats
- Verify driver has assigned loads
- Check driver ID matches in loads
- Ensure driver document exists

---

## Data Integrity

To ensure accurate statistics:

1. **Accurate Load Entry**
   - Enter correct rates
   - Record actual miles
   - Update statuses promptly

2. **Proper Expense Tracking**
   - Log expenses immediately
   - Use correct categories
   - Assign to right driver/load

3. **Consistent Data Practices**
   - Follow naming conventions
   - Use standard status values
   - Regular data audits

---

## Support

For dashboard issues:
1. Verify you have admin role
2. Check Firebase Console for data
3. Review Firestore security rules
4. Contact system administrator

---

**Last Updated**: 2026-02-02
