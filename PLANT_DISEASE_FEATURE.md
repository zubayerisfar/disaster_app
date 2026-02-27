# Plant Disease Detection Feature

## Overview

Added plant disease detection feature in the Krishok (Farmers) section that allows farmers to detect plant diseases by taking photos with their camera or selecting from gallery.

## Changes Made

### 1. Dependencies Added

- **image_picker**: `^1.1.2` - For camera and gallery access

### 2. New Service Created

**File**: `lib/services/plant_disease_service.dart`

- `PlantDiseaseService.predictDisease()` - Sends image to FastAPI server
- `PlantDiseaseService.checkServerHealth()` - Checks if server is running
- `PlantDiseaseResult` model - Stores prediction results

### 3. UI Components Added

**File**: `lib/krishok_page.dart`

- New section added after weather alert
- `_PlantDiseaseDetectionSection` widget with:
  - Camera button (ক্যামেরা)
  - Gallery button (গ্যালারি)
  - Image preview
  - Loading indicator
  - Result display with Bengali disease name and confidence percentage
  - Error handling

## Features

### User Flow

1. User navigates to Krishok (কৃষক সেবা) page
2. Sees "রোগ শনাক্তকরণ" (Disease Detection) section
3. Can choose to:
   - Take photo with camera (ক্যামেরা)
   - Select from gallery (গ্যালারি)
4. Image is automatically sent to FastAPI server
5. Results displayed in Bengali with confidence percentage

### Server Configuration

- Current ngrok URL: `https://orthotropous-keisha-ungeodetically.ngrok-free.dev`
- Endpoint: `/predict`
- Method: POST
- Accepts: Image file (multipart/form-data)
- Returns: JSON with predicted_class (Bengali), predicted_class_english, and confidence

## How to Update ngrok URL

If your ngrok URL changes, update it in:

```dart
// lib/services/plant_disease_service.dart
static const String baseUrl = 'YOUR_NEW_NGROK_URL';
```

## Testing Checklist

- [ ] Camera permission granted
- [ ] Gallery permission granted
- [ ] Can take photo with camera
- [ ] Can select photo from gallery
- [ ] Image is displayed after selection
- [ ] Loading indicator shows during analysis
- [ ] Results display correctly in Bengali
- [ ] Confidence percentage shows
- [ ] Error messages display properly
- [ ] Server connectivity works

## Permissions Required

Make sure the following permissions are configured:

### Android (android/app/src/main/AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS (ios/Runner/Info.plist)

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to detect plant diseases</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to analyze plant images</string>
```

## Screenshots Locations

The feature appears in the Krishok page between:

- Above: Weather-based crop alert
- Below: Seasonal crop recommendations

## Error Handling

- Network errors are caught and displayed
- Image selection errors are handled
- Server connectivity issues show user-friendly messages in Bengali
