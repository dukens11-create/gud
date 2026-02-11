# Email Notification Setup Guide

## Overview

The GUD Express application now sends automated email notifications to drivers when they are assigned loads. This feature is implemented using Firebase Cloud Functions and Nodemailer.

## Features

### Automatic Email Notifications
- **Load Assignment**: When an admin creates a new load with a driver assigned, the driver receives an email notification
- **Load Reassignment**: When an admin updates an existing load's driver assignment, the new driver receives an email notification

### Email Content
Each notification email includes:
- Load number
- Driver name
- Pickup address
- Delivery address
- Rate (payment amount)
- Estimated miles (if provided)
- Additional notes (if provided)
- Current status (for reassignments)

## Prerequisites

1. **Driver Email Addresses**: All drivers must have valid email addresses in the `drivers` collection
2. **Email Service Configuration**: Configure an email service (Gmail, SendGrid, or Mailgun)

## Configuration Options

### Option 1: Gmail (Recommended for Testing Only)

**Note**: Gmail has sending limits and is best for development/testing. For production, use a professional email service.

#### Steps:
1. Create a Gmail account or use an existing one
2. Enable 2-factor authentication on your Google account
3. Generate an App Password:
   - Go to https://myaccount.google.com/apppasswords
   - Select "Mail" and your device
   - Copy the generated 16-character password
4. Configure Firebase Functions:
   ```bash
   firebase functions:config:set email.user="your-email@gmail.com"
   firebase functions:config:set email.pass="your-16-char-app-password"
   firebase functions:config:set email.from="your-email@gmail.com"
   ```
5. Deploy the functions:
   ```bash
   firebase deploy --only functions
   ```

### Option 2: SendGrid (Recommended for Production)

SendGrid offers 100 free emails per day and is reliable for production use.

#### Steps:
1. Sign up for SendGrid: https://signup.sendgrid.com/
2. Create an API key:
   - Go to Settings > API Keys
   - Create API Key with "Mail Send" permission
   - Copy the API key
3. Update the email configuration in `functions/index.js`:
   ```javascript
   // Uncomment the SendGrid configuration in getEmailTransporter()
   if (config.sendgrid && config.sendgrid.apikey) {
     return nodemailer.createTransport({
       host: 'smtp.sendgrid.net',
       port: 587,
       auth: {
         user: 'apikey',
         pass: config.sendgrid.apikey,
       },
     });
   }
   ```
4. Configure Firebase Functions:
   ```bash
   firebase functions:config:set sendgrid.apikey="your-sendgrid-api-key"
   firebase functions:config:set email.from="noreply@yourdomain.com"
   ```
5. Deploy the functions:
   ```bash
   firebase deploy --only functions:sendLoadAssignmentEmail,functions:sendLoadReassignmentEmail
   ```

### Option 3: Mailgun

Mailgun offers 5,000 free emails per month for the first 3 months.

#### Steps:
1. Sign up for Mailgun: https://signup.mailgun.com/
2. Add and verify your domain
3. Get your SMTP credentials from the dashboard
4. Update the email configuration in `functions/index.js`:
   ```javascript
   // Add Mailgun configuration in getEmailTransporter()
   if (config.mailgun) {
     return nodemailer.createTransport({
       host: 'smtp.mailgun.org',
       port: 587,
       auth: {
         user: config.mailgun.user,
         pass: config.mailgun.pass,
       },
     });
   }
   ```
5. Configure Firebase Functions:
   ```bash
   firebase functions:config:set mailgun.user="postmaster@your-domain.mailgun.org"
   firebase functions:config:set mailgun.pass="your-mailgun-smtp-password"
   firebase functions:config:set email.from="noreply@yourdomain.com"
   ```
6. Deploy the functions

## Testing the Email Notifications

### Test Mode (No Configuration)
If no email service is configured, the functions will run in test mode:
- Emails will not be sent
- Email content will be logged to Cloud Functions logs
- You can view the logs using: `firebase functions:log`

### With Configuration
1. Add a driver with a valid email address through the admin interface
2. Create a new load and assign it to that driver
3. Check the driver's email inbox for the notification
4. Update the load's driver assignment to test reassignment notifications

## Monitoring and Troubleshooting

### View Function Logs
```bash
firebase functions:log --only sendLoadAssignmentEmail,sendLoadReassignmentEmail
```

### Common Issues

1. **Email not received**:
   - Check spam/junk folder
   - Verify driver has a valid email address in Firestore
   - Check function logs for errors
   - Verify email configuration is correct

2. **Authentication failed**:
   - For Gmail: Ensure you're using an App Password, not your regular password
   - Verify the email credentials are correct
   - Check that 2FA is enabled (required for Gmail App Passwords)

3. **Function not triggered**:
   - Verify functions are deployed: `firebase functions:list`
   - Check Firebase Console > Functions for any deployment errors
   - Ensure the load has a `driverId` field when created/updated

4. **Rate limiting**:
   - Gmail: Limited to 500-2000 emails per day
   - SendGrid Free: 100 emails per day
   - Mailgun Free: 5,000 emails per month (first 3 months)
   - Consider upgrading your plan for higher limits

## Security Best Practices

1. **Never commit credentials**: Keep email passwords and API keys in Firebase Functions config, not in code
2. **Use App Passwords**: For Gmail, always use App Passwords instead of your main password
3. **Restrict API Keys**: Give API keys only the permissions they need (e.g., Mail Send only)
4. **Monitor Usage**: Regularly check your email service dashboard for unusual activity
5. **Set up SPF/DKIM**: Configure proper email authentication to prevent spoofing

## Email Template Customization

The email templates are defined in `functions/index.js`. To customize:

1. Locate the `htmlContent` variable in the respective function
2. Modify the HTML/CSS styling as needed
3. Add or remove fields from the load data
4. Update the branding (logo, colors, etc.)
5. Deploy the updated functions

## Future Enhancements

Potential improvements to consider:
- Email templates using a template engine (e.g., Handlebars)
- Email open tracking
- Delivery status webhooks
- Unsubscribe functionality
- Email preferences per driver
- SMS notifications as an alternative
- Multi-language support

## Support

For issues or questions:
1. Check the Firebase Functions logs
2. Review the email service provider's documentation
3. Verify driver email addresses in Firestore
4. Test with a known working email address

## Related Documentation

- [Firebase Functions Documentation](https://firebase.google.com/docs/functions)
- [Nodemailer Documentation](https://nodemailer.com/)
- [SendGrid Documentation](https://docs.sendgrid.com/)
- [Mailgun Documentation](https://documentation.mailgun.com/)
