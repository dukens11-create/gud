# Performance Optimization Guide

Guide for optimizing performance in the GUD Express app.

## Overview

This guide covers:
- Current optimizations
- Performance monitoring
- Best practices
- Common performance issues

---

## Implemented Optimizations

### Image Caching

**Package:** `cached_network_image: ^3.3.0`

Images are automatically cached for faster loading:

```dart
import 'package:cached_network_image/cached_network_image.dart';

CachedNetworkImage(
  imageUrl: pod.imageUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
  fadeInDuration: Duration(milliseconds: 300),
  memCacheWidth: 800,  // Resize for memory efficiency
)
```

**Benefits:**
- Images load instantly after first view
- Reduced network usage
- Better user experience
- Automatic cache management

### Lazy Loading Lists

**ListView.builder** for efficient list rendering:

```dart
// Good: Lazy loading
ListView.builder(
  itemCount: loads.length,
  itemBuilder: (context, index) {
    return LoadCard(load: loads[index]);
  },
)

// Bad: Renders all items at once
ListView(
  children: loads.map((load) => LoadCard(load: load)).toList(),
)
```

**Benefits:**
- Only renders visible items
- Smooth scrolling with large lists
- Reduced memory usage
- Better performance on low-end devices

### Database Queries

**Firestore query optimization:**

```dart
// Good: Indexed query with limit
_db.collection('loads')
  .where('status', isEqualTo: 'in_transit')
  .orderBy('createdAt', descending: true)
  .limit(50)
  .snapshots();

// Bad: Fetch all then filter in client
_db.collection('loads')
  .get()
  .then((snapshot) => snapshot.docs
    .where((doc) => doc['status'] == 'in_transit')
    .toList());
```

**Best practices:**
- Use Firestore queries, not client-side filtering
- Add appropriate indexes
- Use pagination for large datasets
- Limit query results
- Use snapshots sparingly

### State Management

**Efficient state updates:**

```dart
// Good: Minimal rebuilds
Consumer<LoadService>(
  builder: (context, service, child) {
    return LoadsList(loads: service.loads);
  },
)

// Bad: Entire tree rebuilds
setState(() {
  _loads = newLoads;
});
```

### Build Method Optimization

**Const constructors where possible:**

```dart
// Good: Const reduces rebuilds
const Text('Hello')
const SizedBox(height: 16)
const Icon(Icons.add)

// Bad: Creates new instance on every build
Text('Hello')
SizedBox(height: 16)
Icon(Icons.add)
```

---

## Performance Monitoring

### Firebase Performance Monitoring

**Setup:**

```dart
import 'package:firebase_performance/firebase_performance.dart';

final performance = FirebasePerformance.instance;

// Track HTTP requests automatically
// Already configured in app

// Custom traces
Future<void> loadData() async {
  final trace = performance.newTrace('load_data');
  await trace.start();
  
  try {
    await _fetchData();
    trace.putAttribute('success', 'true');
  } catch (e) {
    trace.putAttribute('success', 'false');
    trace.putAttribute('error', e.toString());
  } finally {
    await trace.stop();
  }
}
```

**Monitored automatically:**
- App startup time
- Screen rendering
- Network requests
- Crashes and errors

### Flutter DevTools

**Performance profiling:**

```bash
# Launch app with DevTools
flutter run --profile

# In browser: http://localhost:9100/
# Performance tab shows:
# - Frame rendering times
# - UI/GPU thread usage
# - Memory usage
# - Network activity
```

**Key metrics:**
- **Frame time:** Should be < 16ms (60 FPS)
- **Jank:** Frames > 16ms
- **Memory:** Watch for leaks and growth
- **Network:** Track request count and size

### App Performance Metrics

**Target metrics:**
- Cold start: < 3 seconds
- Hot start: < 1 second
- Screen transitions: < 300ms
- List scrolling: 60 FPS
- Image loading: < 500ms (cached)
- Network requests: < 2 seconds

---

## Optimization Techniques

### 1. Reduce Widget Rebuilds

**Use const constructors:**
```dart
class MyWidget extends StatelessWidget {
  const MyWidget({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        const Text('Title'),
        const SizedBox(height: 16),
        const Icon(Icons.star),
      ],
    );
  }
}
```

**Extract widgets:**
```dart
// Bad: Inline builds
build() {
  return Column(
    children: [
      Container(/* complex widget */),
      Container(/* another complex widget */),
    ],
  );
}

// Good: Extracted widgets
build() {
  return Column(
    children: [
      _buildHeader(),
      _buildBody(),
    ],
  );
}

Widget _buildHeader() => HeaderWidget();
Widget _buildBody() => BodyWidget();
```

### 2. Optimize Images

**Resize before upload:**
```dart
import 'package:image/image.dart' as img;

Future<File> resizeImage(File file) async {
  final bytes = await file.readAsBytes();
  final image = img.decodeImage(bytes);
  final resized = img.copyResize(image, width: 1200);
  return File(file.path)..writeAsBytesSync(img.encodeJpg(resized, quality: 85));
}
```

**Use appropriate formats:**
- JPEG for photos (smaller)
- PNG for graphics (quality)
- WebP for best compression

**Lazy load images:**
```dart
ListView.builder(
  itemBuilder: (context, index) {
    return CachedNetworkImage(
      imageUrl: items[index].imageUrl,
      memCacheWidth: 600,  // Limit resolution
    );
  },
)
```

### 3. Database Optimization

**Use pagination:**
```dart
class LoadService {
  static const pageSize = 20;
  DocumentSnapshot? _lastDocument;
  
  Future<List<Load>> getNextPage() async {
    Query query = _db.collection('loads')
      .orderBy('createdAt', descending: true)
      .limit(pageSize);
    
    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }
    
    final snapshot = await query.get();
    if (snapshot.docs.isNotEmpty) {
      _lastDocument = snapshot.docs.last;
    }
    
    return snapshot.docs.map((doc) => Load.fromDoc(doc)).toList();
  }
}
```

**Denormalize data:**
```dart
// Store frequently accessed data together
await _db.collection('loads').doc(loadId).set({
  'loadNumber': 'LOAD-001',
  'driverId': driverId,
  'driverName': driverName,  // Denormalized
  'driverPhone': driverPhone,  // Denormalized
  // ... other fields
});

// Avoids join queries to get driver info
```

**Use indexes:**
```yaml
# firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "loads",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "driverId", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    }
  ]
}
```

### 4. Network Optimization

**Batch requests:**
```dart
// Bad: Multiple requests
for (final loadId in loadIds) {
  await _db.collection('loads').doc(loadId).get();
}

// Good: Single batch
final futures = loadIds.map((id) => 
  _db.collection('loads').doc(id).get()
);
final results = await Future.wait(futures);
```

**Cache responses:**
```dart
class ApiService {
  final _cache = <String, dynamic>{};
  
  Future<dynamic> fetch(String endpoint) async {
    if (_cache.containsKey(endpoint)) {
      return _cache[endpoint];
    }
    
    final response = await http.get(Uri.parse(endpoint));
    _cache[endpoint] = response.body;
    return response.body;
  }
}
```

### 5. Memory Management

**Dispose controllers:**
```dart
class MyScreen extends StatefulWidget {
  @override
  _MyScreenState createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  late TextEditingController _controller;
  StreamSubscription? _subscription;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _subscription = stream.listen(_handler);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _subscription?.cancel();
    super.dispose();
  }
  
  // ...
}
```

**Unsubscribe from streams:**
```dart
// Use StreamBuilder (auto-cancels)
StreamBuilder<List<Load>>(
  stream: _loadService.streamLoads(),
  builder: (context, snapshot) { /* ... */ },
)

// Or manage manually
late StreamSubscription _sub;

@override
void initState() {
  _sub = stream.listen(_handler);
}

@override
void dispose() {
  _sub.cancel();
  super.dispose();
}
```

### 6. Code Splitting

**Lazy load screens:**
```dart
// Load screen code only when needed
Route _createRoute() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) {
      return FutureBuilder(
        future: import('./heavy_screen.dart'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return LoadingScreen();
          return snapshot.data!;
        },
      );
    },
  );
}
```

---

## Common Performance Issues

### Issue 1: Slow List Scrolling

**Symptoms:**
- Stuttering during scroll
- Low frame rate
- UI lag

**Causes:**
- Not using ListView.builder
- Heavy widget builds
- Synchronous operations in build

**Solutions:**
```dart
// Use ListView.builder
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)

// Add cache extent for smoother scrolling
ListView.builder(
  cacheExtent: 500,  // Preload offscreen items
  itemBuilder: (context, index) => ItemWidget(items[index]),
)

// Use RepaintBoundary for complex items
RepaintBoundary(
  child: ComplexItem(item: items[index]),
)
```

### Issue 2: Slow Screen Transitions

**Symptoms:**
- Delay when navigating
- Blank screen flash
- Stuttering animation

**Causes:**
- Heavy initialization in initState
- Large widget trees
- Synchronous data loading

**Solutions:**
```dart
// Preload data
void _navigateToDetail() async {
  // Start loading data
  final future = _loadData();
  
  // Navigate immediately
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DetailScreen(dataFuture: future),
    ),
  );
}

// Use hero animations
Hero(
  tag: 'load-${load.id}',
  child: LoadCard(load: load),
)
```

### Issue 3: Memory Leaks

**Symptoms:**
- App memory increases over time
- Eventually crashes
- Slow performance

**Causes:**
- Not disposing controllers
- Not canceling subscriptions
- Circular references

**Solutions:**
```dart
// Always dispose
@override
void dispose() {
  _controller.dispose();
  _animationController.dispose();
  _subscription.cancel();
  _focusNode.dispose();
  super.dispose();
}

// Use weak references where appropriate
```

### Issue 4: Slow Initial Load

**Symptoms:**
- Long splash screen
- Blank screen on startup
- Poor first impression

**Causes:**
- Heavy initialization
- Synchronous operations
- Large bundle size

**Solutions:**
```dart
// Defer heavy initialization
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Only critical initialization
  await Firebase.initializeApp();
  
  runApp(MyApp());
  
  // Defer non-critical initialization
  Future.microtask(() async {
    await initializeNonCriticalServices();
  });
}

// Show loading state
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _initialized = false;
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  Future<void> _initialize() async {
    await _loadData();
    setState(() => _initialized = true);
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_initialized) return SplashScreen();
    return MainApp();
  }
}
```

---

## Performance Testing

### Benchmark Tests

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Load parsing performance', () {
    final stopwatch = Stopwatch()..start();
    
    for (int i = 0; i < 1000; i++) {
      Load.fromJson(mockJson);
    }
    
    stopwatch.stop();
    print('Parsed 1000 loads in ${stopwatch.elapsedMilliseconds}ms');
    expect(stopwatch.elapsedMilliseconds, lessThan(100));
  });
}
```

### Integration Performance Tests

```dart
testWidgets('List scrolling performance', (tester) async {
  await tester.pumpWidget(MyApp());
  
  // Generate large list
  final loads = List.generate(100, (i) => Load(id: '$i'));
  
  // Measure scroll performance
  final stopwatch = Stopwatch()..start();
  
  await tester.drag(
    find.byType(ListView),
    Offset(0, -5000),
  );
  await tester.pumpAndSettle();
  
  stopwatch.stop();
  expect(stopwatch.elapsedMilliseconds, lessThan(1000));
});
```

---

## Performance Checklist

### App Launch
- [ ] Cold start < 3 seconds
- [ ] Minimal work in main()
- [ ] Splash screen shows immediately
- [ ] Critical data only on startup

### Lists
- [ ] ListView.builder used
- [ ] Pagination implemented
- [ ] Images cached
- [ ] Smooth 60 FPS scrolling

### Images
- [ ] cached_network_image used
- [ ] Images resized appropriately
- [ ] Lazy loading implemented
- [ ] Cache size managed

### Database
- [ ] Queries are indexed
- [ ] Results are limited
- [ ] Pagination used
- [ ] Denormalization where appropriate

### Memory
- [ ] Controllers disposed
- [ ] Subscriptions canceled
- [ ] No circular references
- [ ] Memory usage stable

### Network
- [ ] Requests minimized
- [ ] Responses cached
- [ ] Batch operations used
- [ ] Timeouts configured

---

## Monitoring Dashboard

**Key metrics to track:**

1. **App Performance:**
   - Cold start time
   - Hot start time
   - Screen transition time
   - Frame rendering time

2. **Network:**
   - Request count
   - Request duration
   - Failed requests
   - Data transferred

3. **Database:**
   - Query count
   - Query duration
   - Read/write counts
   - Index usage

4. **Crashes:**
   - Crash-free users %
   - Crash count
   - ANR rate (Android)
   - Common crash patterns

---

## Resources

### Tools
- [Flutter DevTools](https://flutter.dev/docs/development/tools/devtools)
- [Firebase Performance](https://firebase.google.com/docs/perf-mon)
- [Android Profiler](https://developer.android.com/studio/profile/android-profiler)
- [Xcode Instruments](https://help.apple.com/instruments)

### Documentation
- [Flutter Performance](https://flutter.dev/docs/perf)
- [Flutter Performance Best Practices](https://flutter.dev/docs/perf/best-practices)
- [Firestore Best Practices](https://firebase.google.com/docs/firestore/best-practices)

### Support
For performance issues:
- **Email:** performance@gudexpress.com
- **Slack:** #gud-performance

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.0 | 2024-02 | Added image caching, lazy loading optimizations |
| 1.0 | 2024-01 | Initial performance guidelines |
