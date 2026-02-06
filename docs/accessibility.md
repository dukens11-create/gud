# Accessibility Guide

Making GUD Express accessible to all users, including those with disabilities.

## Overview

This guide covers:
- Accessibility features in the app
- How to use accessibility tools
- Testing accessibility
- Best practices for developers

---

## Implemented Features

### Screen Reader Support

The app includes semantic labels for screen readers like TalkBack (Android) and VoiceOver (iOS).

**Key screens with accessibility:**
- Login screen
- Admin home dashboard
- Driver home screen
- Load detail screens
- Settings screens

### Text Scaling

- Supports system-level text scaling
- Readable at sizes from 100% to 200%
- Dynamic type for iOS
- Font scaling for Android

### Color Contrast

- All text meets WCAG AA standards (4.5:1 contrast)
- Important actions have AAA contrast (7:1)
- Color is not the only visual indicator

### Touch Targets

- All interactive elements are at least 44x44 points
- Adequate spacing between touch targets
- Clear focus indicators

### Keyboard Navigation

- Logical tab order
- Visible focus indicators
- Keyboard shortcuts where appropriate

---

## Using the App with Accessibility Features

### For VoiceOver Users (iOS)

**Enable VoiceOver:**
1. Settings > Accessibility > VoiceOver
2. Turn on VoiceOver
3. Triple-click home/side button to toggle

**App Navigation:**
- Swipe right: Next element
- Swipe left: Previous element
- Double tap: Activate element
- Three-finger swipe: Scroll

**Key gestures in GUD Express:**
- Load list: Swipe through load cards
- Map view: Explore map elements
- Forms: Navigate between fields

### For TalkBack Users (Android)

**Enable TalkBack:**
1. Settings > Accessibility > TalkBack
2. Turn on TalkBack
3. Volume keys shortcut to toggle

**App Navigation:**
- Swipe right: Next element
- Swipe left: Previous element
- Double tap: Activate
- Two-finger scroll: Scroll content

### For Voice Control Users

**iOS Voice Control:**
- "Tap [item name]" to activate
- "Show numbers" to see numbered grid
- "Scroll down/up" to navigate

**Android Voice Access:**
- Similar commands to iOS
- "Open GUD Express"
- "Tap sign in"

### For Switch Control Users

- Single switch scanning supported
- Configurable scanning speed
- Point scanning available

---

## Accessibility Testing

### Manual Testing

**Screen Reader Testing:**
1. Enable VoiceOver/TalkBack
2. Navigate entire app without looking at screen
3. Verify all elements are announced
4. Check labels are descriptive
5. Test all interactive elements

**Keyboard Testing:**
1. Connect keyboard to device
2. Navigate using Tab key
3. Verify focus order is logical
4. Test all actions with Enter/Space
5. Check focus indicators are visible

**Text Scaling Testing:**
1. Increase text size to 200%
2. Verify all text is readable
3. Check no text is cut off
4. Test all screens
5. Verify layout doesn't break

**Color Testing:**
1. Test in grayscale mode
2. Use color blindness simulators
3. Verify information isn't color-only
4. Check contrast ratios

### Automated Testing

**Using Accessibility Scanner (Android):**
1. Install Accessibility Scanner from Play Store
2. Enable in Accessibility settings
3. Open GUD Express
4. Tap scanner button
5. Review suggestions

**Using Xcode Accessibility Inspector (iOS):**
1. Open Xcode
2. Window > Accessibility Inspector
3. Connect device
4. Select GUD Express
5. Run audit
6. Review warnings

---

## Developer Guidelines

### Adding Semantics

**Flutter Semantics Widget:**

```dart
// Add semantic label to icon button
Semantics(
  label: 'Create new load',
  button: true,
  child: IconButton(
    icon: Icon(Icons.add),
    onPressed: _createLoad,
  ),
)

// Mark header as heading
Semantics(
  header: true,
  child: Text('Dashboard', style: headerStyle),
)

// Group related elements
Semantics(
  label: 'Load LOAD-042, status: In Transit',
  child: LoadCard(load: load),
)

// Provide value for progress indicators
Semantics(
  value: '${(progress * 100).toInt()}% complete',
  child: LinearProgressIndicator(value: progress),
)
```

### Accessible Buttons

```dart
// Always provide tooltip or semantic label
IconButton(
  icon: Icon(Icons.delete),
  onPressed: _delete,
  tooltip: 'Delete load',  // Announced by screen readers
)

// Or use Semantics
Semantics(
  label: 'Delete load',
  button: true,
  child: IconButton(
    icon: Icon(Icons.delete),
    onPressed: _delete,
  ),
)

// For text buttons, text is automatically semantic
ElevatedButton(
  onPressed: _submit,
  child: Text('Submit'),  // Label is "Submit"
)
```

### Accessible Images

```dart
// Provide semantic label for images
Semantics(
  label: 'Proof of delivery photo showing signature',
  image: true,
  child: Image.network(pod.imageUrl),
)

// Decorative images can be excluded
Semantics(
  excludeSemantics: true,
  child: Image.asset('assets/decoration.png'),
)
```

### Form Accessibility

```dart
// Label form fields
TextFormField(
  decoration: InputDecoration(
    labelText: 'Load Number',  // Announced by screen readers
    hintText: 'e.g., LOAD-001',
  ),
  validator: (value) => value?.isEmpty ?? true 
      ? 'Load number is required' 
      : null,
)

// Group related fields
Semantics(
  label: 'Pickup information',
  child: Column(
    children: [
      TextFormField(/* address */),
      TextFormField(/* city */),
      TextFormField(/* zip */),
    ],
  ),
)
```

### Navigation Accessibility

```dart
// Announce screen changes
void _navigateToDetail() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => Semantics(
        label: 'Load detail screen',
        child: LoadDetailScreen(load: load),
      ),
    ),
  );
}

// Use descriptive AppBar titles
AppBar(
  title: Text('Edit Load'),  // Announced when screen opens
)
```

### Status Updates

```dart
// Announce dynamic updates
void _updateStatus(String newStatus) {
  setState(() {
    _status = newStatus;
  });
  
  // Announce update to screen reader
  SemanticsService.announce(
    'Load status updated to $newStatus',
    TextDirection.ltr,
  );
}

// Show snackbar for visual users too
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Status updated')),
);
```

### Lists and Cards

```dart
// Make list items semantic
ListView.builder(
  itemCount: loads.length,
  itemBuilder: (context, index) {
    final load = loads[index];
    return Semantics(
      label: 'Load ${load.number}, '
             'Driver ${load.driverName}, '
             'Status ${load.status}',
      button: true,
      onTap: () => _openLoadDetail(load),
      child: LoadCard(load: load),
    );
  },
)
```

---

## Accessibility Checklist

### Screen Reader Support
- [ ] All interactive elements have labels
- [ ] Images have descriptions (or marked decorative)
- [ ] Headings are properly marked
- [ ] Lists are semantic
- [ ] Dynamic content changes are announced
- [ ] Error messages are announced
- [ ] Form fields have labels
- [ ] Buttons describe their action

### Keyboard Support
- [ ] All features accessible via keyboard
- [ ] Tab order is logical
- [ ] Focus indicators are visible
- [ ] No keyboard traps
- [ ] Shortcuts don't conflict with system

### Visual Accessibility
- [ ] Text contrast meets WCAG AA (4.5:1)
- [ ] Important text meets AAA (7:1)
- [ ] Text scales to 200% without breaking
- [ ] Color isn't only indicator
- [ ] Focus indicators are visible
- [ ] Touch targets are 44x44+ points

### Content Accessibility
- [ ] Language is clear and simple
- [ ] Instructions are concise
- [ ] Error messages are helpful
- [ ] Success feedback is provided
- [ ] Timeouts can be extended

### Testing
- [ ] Tested with VoiceOver
- [ ] Tested with TalkBack
- [ ] Tested with Accessibility Scanner
- [ ] Tested with keyboard
- [ ] Tested at 200% text size
- [ ] Tested in grayscale
- [ ] Tested with color blindness simulator

---

## Common Issues and Fixes

### Issue: Button Not Announced

**Problem:**
```dart
GestureDetector(
  onTap: _action,
  child: Icon(Icons.add),
)
```

**Fix:**
```dart
Semantics(
  label: 'Add item',
  button: true,
  child: GestureDetector(
    onTap: _action,
    child: Icon(Icons.add),
  ),
)

// Or better, use proper button widget
IconButton(
  icon: Icon(Icons.add),
  onPressed: _action,
  tooltip: 'Add item',
)
```

### Issue: Image Has No Description

**Problem:**
```dart
Image.network(url)
```

**Fix:**
```dart
Semantics(
  label: 'Proof of delivery photo',
  image: true,
  child: Image.network(url),
)
```

### Issue: Dynamic Content Not Announced

**Problem:**
```dart
setState(() {
  _count++;
});
```

**Fix:**
```dart
setState(() {
  _count++;
});
SemanticsService.announce(
  'Count is now $_count',
  TextDirection.ltr,
);
```

### Issue: Poor Color Contrast

**Problem:**
```dart
Text(
  'Warning',
  style: TextStyle(color: Colors.grey),  // Poor contrast
)
```

**Fix:**
```dart
Text(
  'Warning',
  style: TextStyle(
    color: Colors.red[900],  // Better contrast
    fontWeight: FontWeight.bold,
  ),
)
```

---

## Resources

### Guidelines
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Material Design Accessibility](https://material.io/design/usability/accessibility.html)
- [iOS Human Interface Guidelines - Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Android Accessibility](https://developer.android.com/guide/topics/ui/accessibility)

### Tools
- [Accessibility Scanner (Android)](https://play.google.com/store/apps/details?id=com.google.android.apps.accessibility.auditor)
- [Color Contrast Analyzer](https://www.tpgi.com/color-contrast-checker/)
- [Colorblind Simulator](https://www.color-blindness.com/coblis-color-blindness-simulator/)
- [WAVE Web Accessibility Tool](https://wave.webaim.org/)

### Flutter Resources
- [Flutter Accessibility](https://flutter.dev/docs/development/accessibility-and-localization/accessibility)
- [Semantics Widget](https://api.flutter.dev/flutter/widgets/Semantics-class.html)
- [SemanticsService](https://api.flutter.dev/flutter/semantics/SemanticsService-class.html)

### Support
For accessibility questions:
- **Email:** accessibility@gudexpress.com
- **Slack:** #gud-accessibility

---

## Legal Requirements

### ADA Compliance (United States)
- Mobile apps should be accessible
- Equivalent experience for all users
- Regular accessibility audits

### Section 508
- Federal government accessibility standards
- Required for government contractors
- WCAG 2.0 Level AA compliance

### European Accessibility Act
- Effective June 2025
- Apps must meet accessibility requirements
- Regular monitoring and reporting

---

## Continuous Improvement

### Feedback Collection
- Add accessibility feedback form
- Monitor user reviews for accessibility mentions
- Conduct user testing with disabled users

### Regular Audits
- Monthly: Automated testing
- Quarterly: Manual testing
- Annually: Third-party audit
- Ongoing: User feedback

### Team Training
- Accessibility awareness training
- Screen reader usage training
- Testing best practices
- WCAG guidelines training

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.0 | 2024-02 | Enhanced semantic labels, added accessibility testing |
| 1.0 | 2024-01 | Initial accessibility features |
