# Mental Health Assessment Feature

## Overview

A new mental health assessment feature has been added to the Women Safety section. This feature helps women evaluate their mental health status and provides personalized guidance and support resources.

## Features

### 1. **Comprehensive Assessment**

- 21-question survey covering various aspects of mental health
- Questions include:
  - Education and social exposure
  - Abuse experiences (physical/sexual)
  - Academic performance
  - Freedom and communication
  - Family and relationship dynamics
  - Medical symptoms and behavioral patterns

### 2. **Dropdown Form Interface**

- User-friendly dropdown selections
- All questions in Bengali language
- Each question has 3 options (e.g., "না", "হ্যাঁ", etc.)
- Form validation ensures all questions are answered

### 3. **AI-Powered Analysis**

- Uses machine learning model (PyTorch)
- Server endpoint: `/predict/depression`
- Returns:
  - Risk prediction
  - Probability percentage
  - Risk level (Low/Medium/High)

### 4. **Personalized Guidance**

#### For At-Risk Users:

- **Mental Health Improvement Tips:**
  1. Seek professional help
  2. Share feelings with trusted people
  3. Build healthy habits (exercise, sleep, nutrition)
  4. Practice hobbies and interests

- **Emergency Contact Numbers:**
  - National Mental Health Institute: 02-9011639
  - Kan Pete Roi (Suicide Prevention): 09638989898
  - Moner Bondhu Helpline: 01779554392

#### For Healthy Users:

- Inspirational messages
- Positive affirmations
- Encouragement to maintain good mental health
- Reminder that support is always available

## Implementation Details

### Files Created

1. **`lib/services/mental_health_service.dart`**
   - Service class for API communication
   - Handles assessment submission
   - Server health check

2. **`lib/models/mental_health_assessment.dart`**
   - Data model for assessment
   - 21 fields matching server requirements
   - Bengali questions with options
   - JSON serialization

3. **Updated `lib/women_safety_page.dart`**
   - New section: "মানসিক স্বাস্থ্য মূল্যায়ন"
   - Form with dropdown fields
   - Result display with conditional guidance
   - Reset functionality

### Server Integration

The feature uses the existing server at:

```
https://orthotropous-keisha-ungeodetically.ngrok-free.dev
```

**Important:** Update the `baseUrl` in `mental_health_service.dart` if your server URL changes.

### Server Files Required

- ✅ `depression_model.pth` - PyTorch model
- ✅ `feature_columns.pkl` - Feature names
- ✅ `scaler.pkl` - StandardScaler for normalization

All files are already present in the `server/` directory.

## Usage

1. **Navigate to Women Safety Page**
   - Open the app
   - Go to "নারী ও শিশু সুরক্ষা" section

2. **Complete Assessment**
   - Find "মানসিক স্বাস্থ্য মূল্যায়ন" section
   - Answer all 21 questions using dropdowns
   - Click "মূল্যায়ন জমা দিন" button

3. **View Results**
   - See risk assessment with visual indicators
   - Read personalized guidance
   - Access emergency contacts if needed

4. **Retake Assessment**
   - Click "নতুন মূল্যায়ন করুন" to reset and start over

## Testing

### Prerequisites

1. Ensure server is running:

   ```bash
   cd server
   python server.py
   ```

2. Verify server health:

   ```bash
   curl https://your-server-url/health
   ```

3. Expected response:
   ```json
   {
     "status": "healthy",
     "plant_model_loaded": true,
     "depression_model_loaded": true,
     "device": "cpu"
   }
   ```

### Test Cases

1. ✅ Fill all 21 questions and submit
2. ✅ Verify validation (try submitting incomplete form)
3. ✅ Check "High Risk" scenario response
4. ✅ Check "Low Risk" scenario response
5. ✅ Test reset functionality

## Color Scheme

- Primary Color: Purple (`#6A1B9A`)
- Success/Healthy: Green (`#2E7D32`)
- Warning/At-Risk: Red (`#D32F2F`)

## Accessibility

- All text in Bengali for better understanding
- Clear visual indicators (icons and colors)
- Simple dropdown interface
- Error messages in Bengali

## Privacy & Security

- No data is stored on the server
- Assessment results are temporary
- No personal identifying information required
- Confidential guidance provided

## Future Enhancements

- [ ] Add assessment history tracking
- [ ] Include more detailed recommendations
- [ ] Add scheduling for counseling appointments
- [ ] Multilingual support (English option)
- [ ] Export results as PDF

## Support

If users need immediate help, the app provides:

- National Mental Health Institute
- Suicide Prevention Hotline
- Mental Health Counseling Services

---

**Note:** This is a screening tool, not a diagnostic instrument. Users showing high risk should be encouraged to seek professional mental health support.
