# GUD Express - Application Architecture (Demo Version)

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    GUD Express Demo App                          │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      Presentation Layer                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                   Login Screen                              │ │
│  │           (Demo Login with 2 buttons)                       │ │
│  └──────────────────────┬─────────────────────────────────────┘ │
│                         │                                         │
│              ┌──────────┴──────────┐                             │
│              │                     │                             │
│     ┌────────▼────────┐    ┌──────▼──────────┐                 │
│     │  Admin Screens  │    │  Driver Screens │                 │
│     ├─────────────────┤    ├─────────────────┤                 │
│     │ • Admin Home    │    │ • Driver Home   │                 │
│     │   (Load List)   │    │   (Load List)   │                 │
│     └─────────────────┘    │ • Earnings      │                 │
│                             └─────────────────┘                 │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      Business Logic Layer                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              MockDataService                              │   │
│  ├──────────────────────────────────────────────────────────┤   │
│  │ • getDemoLoads() → Returns List<SimpleLoad>             │   │
│  │   - LOAD-001 ($1,500 - Assigned)                        │   │
│  │   - LOAD-002 ($1,200 - In Transit)                      │   │
│  │   - LOAD-003 ($950 - Delivered)                         │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                         Data Layer                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │ AppUser  │  │  Driver  │  │   Load   │  │   POD    │        │
│  ├──────────┤  ├──────────┤  ├──────────┤  ├──────────┤        │
│  │• uid     │  │• id      │  │• id      │  │• id      │        │
│  │• email   │  │• name    │  │• number  │  │• loadId  │        │
│  │• role    │  │• phone   │  │• driver  │  │• imageUrl│        │
│  │          │  │• truck   │  │• address │  │• notes   │        │
│  │          │  │• userId  │  │• rate    │  │• date    │        │
│  │          │  │          │  │• status  │  │          │        │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘        │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      Firebase Backend                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Firebase   │  │  Firestore   │  │   Storage    │          │
│  │     Auth     │  │   Database   │  │              │          │
│  ├──────────────┤  ├──────────────┤  ├──────────────┤          │
│  │• Email/Pass  │  │• users/      │  │• pods/       │          │
│  │• User UID    │  │• drivers/    │  │  *.jpg       │          │
│  │              │  │• loads/      │  │              │          │
│  │              │  │  • pods/     │  │              │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow Diagrams

### Admin Creates Load Flow

```
┌────────────┐     ┌─────────────┐     ┌──────────────┐     ┌──────────┐
│   Admin    │────▶│ Create Load │────▶│  Firestore   │────▶│  Driver  │
│   Screen   │     │   Screen    │     │   Service    │     │  Screen  │
└────────────┘     └─────────────┘     └──────────────┘     └──────────┘
      │                   │                     │                  │
      │ 1. Click Create   │                     │                  │
      │───────────────────▶                     │                  │
      │                   │ 2. Fill Form        │                  │
      │                   │                     │                  │
      │                   │ 3. Submit           │                  │
      │                   │─────────────────────▶                  │
      │                   │                     │ 4. Save to DB    │
      │                   │                     │                  │
      │                   │ 5. Success          │                  │
      │◀──────────────────│◀─────────────────────                  │
      │                   │                     │ 6. Stream Update │
      │                   │                     │──────────────────▶
      │                   │                     │                  │
```

### Driver Updates Load Status Flow

```
┌────────────┐     ┌─────────────┐     ┌──────────────┐     ┌──────────┐
│   Driver   │────▶│ Load Detail │────▶│  Firestore   │────▶│  Admin   │
│   Screen   │     │   Screen    │     │   Service    │     │  Screen  │
└────────────┘     └─────────────┘     └──────────────┘     └──────────┘
      │                   │                     │                  │
      │ 1. Open Load      │                     │                  │
      │───────────────────▶                     │                  │
      │                   │ 2. Click Status Btn │                  │
      │                   │                     │                  │
      │                   │ 3. Update Status    │                  │
      │                   │─────────────────────▶                  │
      │                   │                     │ 4. Update DB     │
      │                   │                     │                  │
      │                   │ 5. Confirmation     │                  │
      │◀──────────────────│◀─────────────────────                  │
      │                   │                     │ 6. Stream Update │
      │                   │                     │──────────────────▶
      │                   │                     │                  │
```

### Driver Uploads POD Flow

```
┌────────────┐     ┌─────────────┐     ┌──────────────┐     ┌──────────┐
│   Driver   │────▶│ Upload POD  │────▶│   Storage    │────▶│Firestore │
│   Screen   │     │   Screen    │     │   Service    │     │ Service  │
└────────────┘     └─────────────┘     └──────────────┘     └──────────┘
      │                   │                     │                  │
      │ 1. Click Upload   │                     │                  │
      │───────────────────▶                     │                  │
      │                   │ 2. Capture Photo    │                  │
      │                   │                     │                  │
      │                   │ 3. Add Notes        │                  │
      │                   │                     │                  │
      │                   │ 4. Submit           │                  │
      │                   │─────────────────────▶                  │
      │                   │                     │ 5. Upload Image  │
      │                   │                     │                  │
      │                   │                     │ 6. Get URL       │
      │                   │                     │◀─────────────────│
      │                   │                     │                  │
      │                   │                     │ 7. Save POD Doc  │
      │                   │                     │──────────────────▶
      │                   │ 8. Success          │                  │
      │◀──────────────────│◀─────────────────────                  │
      │                   │                     │                  │
```

## State Management

### StreamBuilder Pattern

The application uses Flutter's StreamBuilder for real-time updates:

```dart
StreamBuilder<List<LoadModel>>(
  stream: firestoreService.streamDriverLoads(driverId),
  builder: (context, snapshot) {
    // Automatically rebuilds when data changes
    final loads = snapshot.data ?? [];
    return ListView.builder(...);
  },
)
```

**Benefits:**
- Real-time updates
- Automatic UI refresh
- No manual state management needed
- Clean and reactive

### FutureBuilder Pattern

Used for one-time data fetching:

```dart
FutureBuilder<double>(
  future: firestoreService.calculateDriverEarnings(driverId),
  builder: (context, snapshot) {
    final earnings = snapshot.data ?? 0.0;
    return Text('\$${earnings.toStringAsFixed(2)}');
  },
)
```

## Security Architecture

### Role-Based Access Control (RBAC)

```
┌──────────────────────────────────────────┐
│            User Login                     │
└────────────┬─────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────┐
│      Check Firestore user.role           │
└────────────┬─────────────────────────────┘
             │
        ┌────┴────┐
        │         │
        ▼         ▼
┌──────────┐  ┌──────────┐
│  Admin   │  │  Driver  │
│  Role    │  │  Role    │
└────┬─────┘  └─────┬────┘
     │              │
     ▼              ▼
┌──────────┐  ┌──────────┐
│All Loads │  │Own Loads │
│All Driver│  │Own Data  │
│Full CRUD │  │Limited   │
└──────────┘  └──────────┘
```

### Firestore Security Rules Logic

```
Rule: Can Read Load?
├── Is Admin? → YES
└── Is Load.driverId == User.driverId? → YES
    └── NO → DENY

Rule: Can Update Load?
├── Is Admin? → YES (Any field)
└── Is Load.driverId == User.driverId?
    └── Only status, tripStartTime, tripEndTime → YES
    └── Other fields → DENY
```

## Navigation Flow

```
App Start
    │
    ▼
┌────────────┐
│  Firebase  │
│   Init     │
└─────┬──────┘
      │
      ▼
┌────────────┐
│   Auth     │
│  Wrapper   │
└─────┬──────┘
      │
   ┌──┴──┐
   │     │
   ▼     ▼
┌─────┐ ┌──────────┐
│Login│ │Logged In?│
└─────┘ └────┬─────┘
             │
      ┌──────┴──────┐
      │             │
      ▼             ▼
┌──────────┐  ┌──────────┐
│Admin Home│  │Driver Hom│
└────┬─────┘  └─────┬────┘
     │              │
     ├─Drivers      ├─Load Detail
     ├─Create Load  ├─Upload POD
     └─Load Detail  └─Earnings
```

## Component Relationships

```
┌─────────────────────────────────────────┐
│              App.dart                    │
│  (Material App + Auth Wrapper)          │
└────────────┬────────────────────────────┘
             │
       ┌─────┴─────┐
       │           │
       ▼           ▼
┌──────────┐  ┌──────────┐
│  Admin   │  │  Driver  │
│  Screens │  │  Screens │
└────┬─────┘  └─────┬────┘
     │              │
     ├─Uses         ├─Uses
     │              │
     ▼              ▼
┌─────────────────────────┐
│      Services           │
├─────────────────────────┤
│ • AuthService           │
│ • FirestoreService      │
│ • StorageService        │
└──────────┬──────────────┘
           │
           ├─Uses
           │
           ▼
┌─────────────────────────┐
│      Models             │
├─────────────────────────┤
│ • AppUser               │
│ • Driver                │
│ • Load                  │
│ • POD                   │
└─────────────────────────┘
```

## Error Handling Strategy

```
┌────────────┐
│ UI Action  │
└─────┬──────┘
      │
      ▼
┌────────────┐
│  Service   │
│   Method   │
└─────┬──────┘
      │
      ├─try {
      │   Firebase Operation
      │ }
      ▼
┌────────────┐      ┌────────────┐
│  Success   │      │   Error    │
└─────┬──────┘      └─────┬──────┘
      │                   │
      ▼                   ▼
┌────────────┐      ┌────────────┐
│ Update UI  │      │ catch (e)  │
│ Show       │      │ Show Error │
│ Success    │      │ SnackBar   │
└────────────┘      └────────────┘
```

## Performance Optimization

### Implemented Optimizations

1. **Const Constructors**: 186 usages for widget optimization
2. **Lazy Loading**: StreamBuilder only loads when needed
3. **Image Compression**: POD images compressed to 1920x1080 @ 85%
4. **Indexed Queries**: Firestore queries use orderBy for efficiency
5. **Cached Data**: Firestore automatically caches for offline support

### Pagination Strategy (Future Enhancement)

```dart
// Current: Loads all loads
stream: firestoreService.streamAllLoads()

// Future: Paginated loads
stream: firestoreService.streamLoads(
  limit: 20,
  startAfter: lastDocument,
)
```

## Testing Strategy

### Unit Testing Targets
- Models: `toMap()` and `fromDoc()` methods
- Services: Mock Firebase operations
- Widgets: Widget rendering and interactions

### Integration Testing Targets
- Authentication flow
- Load creation and assignment
- Status updates
- POD upload

### End-to-End Testing Targets
- Complete admin workflow
- Complete driver workflow
- Real-time synchronization
- Security rules enforcement
