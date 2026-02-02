# Firebase Setup Instructions

## 1. Project Creation
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Click on "Add Project".
3. Enter your project name and follow the prompts to create your project.

## 2. Android Configuration
1. Click on "Add app" and select Android.
2. Enter your Android package name (e.g., com.example.myapp).
3. Download the `google-services.json` file provided.
4. Place the `google-services.json` file in the `app/` directory of your Android project.
5. Update your `build.gradle` files:
   - Project-level `build.gradle`:
     ```
grammy-
     classpath 'com.google.gms:google-services:4.3.5' // Google Services plugin
     ```
   - App-level `build.gradle`:
     ```
     apply plugin: 'com.android.application'
     apply plugin: 'com.google.gms.google-services' // Google Services plugin
     ```

## 3. Enabling Services
1. In the Firebase console, go to the "Build" section.
2. Enable the services you want to use (e.g., Firestore, Authentication, etc.).

## 4. Security Rules
1. Navigate to the Firestore or Realtime Database section.
2. Click on "Rules".
3. Modify the rules according to your app's security needs:
   ```
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

## 5. Data Structure Documentation
- Define collections and documents carefully. Here is a simple example:
  - **Users Collection**:
    - userId (document)
      - name: String
      - email: String
      - age: Number

  - **Posts Collection**:
    - postId (document)
      - title: String
      - content: String
      - timestamp: Timestamp

Ensure to adapt the structure based on your app requirements.
