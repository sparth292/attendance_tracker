# FCM Testing Guide

## 📱 **Testing Firebase Cloud Messaging**

### **Prerequisites**
- ✅ Flutter app runs without crashes
- ✅ FCM service initialized (mock or real)
- ✅ Local notifications working
- ✅ Faculty home screen displays lectures

---

## 🧪 **Testing Scenarios**

### **1. Basic App Startup**
**Expected Logs:**
```
🔔 [MAIN] Firebase initialized successfully
🔔 [MAIN] FCM service initialized
🔔 [FCM] Firebase initialized successfully
🔔 [FCM] FCM Token: [your_token]
🔔 [FCM] Token sent to backend successfully
📚 [LECTURE] Loading lectures for faculty: FAC002
🎯 [UI] _buildLectureCard called
🎯 [UI] _currentLecture set to: [lecture_data]
```

**Test Steps:**
1. Run `flutter run`
2. Check console logs for above messages
3. Verify app doesn't crash at splash screen

---

### **2. FCM Token Generation**
**Expected Logs:**
```
🔔 [FCM] Getting FCM token...
🔔 [FCM] FCM Token: abc123def456
🔔 [FCM] Token saved locally
🔔 [FCM] Token sent to backend successfully
```

**Test Steps:**
1. App starts → Token generated automatically
2. Check logs for token generation
3. Verify token is saved to SharedPreferences

---

### **3. "Assign this lec" Flow**
**Expected Logs:**
```
🎯 [UI] _buildLectureCard called
🎯 [UI] Showing lecture: [course_name]
📋 [SUBSTITUTION] Creating substitution request...
📋 [SUBSTITUTION] Course: [course_name]
📋 [SUBSTITUTION] Room: [room_number]
📋 [SUBSTITUTION] Faculty: [faculty_id]
📡 [SUBSTITUTION] API Response Status: 200
✅ [SUBSTITUTION] Substitution request created
✅ [SUBSTITUTION] Substitution ID: 123
```

**Test Steps:**
1. Go to Faculty Home Screen
2. Click "Assign this lec" button
3. Faculty selection modal appears
4. Click "Send to All" button
5. Check logs for substitution request creation

---

### **4. Notification Reception (Foreground)**
**Expected Logs:**
```
🔔 [FCM] Foreground message received: [message_id]
🔔 [FCM] Title: Lecture Substitution Request
🔔 [FCM] Body: FAC002 needs a substitute
🔔 [FCM] Data: {substitution_id: "123", title: "Lecture Substitution Request"}
🔔 [FCM] Showing local notification...
🔔 [FCM] Local notification shown successfully
```

**Test Steps:**
1. Keep app in foreground
2. Send test notification via API/Console
3. Verify local notification appears
4. Check console logs

---

### **5. Notification Reception (Background)**
**Expected Logs:**
```
🔔 [FCM] Background message received: [message_id]
🔔 [FCM] Background message title: Lecture Substitution Request
🔔 [FCM] Background message body: FAC002 needs a substitute
🔔 [FCM] Background message data: {substitution_id: "123"}
```

**Test Steps:**
1. Put app in background (home button)
2. Send test notification via API/Console
3. Check system notification appears
4. Tap notification to open app

---

### **6. Notification Reception (Terminated)**
**Expected Logs:**
```
🔔 [FCM] App opened from terminated state: [message_id]
🔔 [FCM] App opened from terminated state
🔔 [FACULTY_HOME] Received FCM message
🔔 [FACULTY_HOME] Navigating to substitution requests screen...
```

**Test Steps:**
1. Force close app (swipe away)
2. Send test notification via API/Console
3. Check system notification appears
4. Tap notification to open app
5. Verify navigation to substitution requests screen

---

## 🛠️ **Manual Testing via API**

### **Send Test Notification**
```bash
curl -X POST http://13.235.16.3:5000/api/test-notification \
  -H "Content-Type: application/json" \
  -d '{
    "token": "YOUR_FCM_TOKEN",
    "title": "Test Notification",
    "body": "This is a test notification",
    "substitution_id": "123"
  }'
```

### **Create Substitution Request**
```bash
curl -X POST http://13.235.16.3:5000/api/substitution/request \
  -H "Content-Type: application/json" \
  -d '{
    "timetable_id": 10,
    "original_faculty_id": "FAC002",
    "date": "2026-04-07"
  }'
```

### **Respond to Substitution Request**
```bash
curl -X POST http://13.235.16.3:5000/api/substitution/respond \
  -H "Content-Type: application/json" \
  -d '{
    "substitution_id": 123,
    "faculty_id": "FAC001",
    "action": "ACCEPT"
  }'
```

---

## 🔍 **Debugging Commands**

### **Check FCM Token**
```bash
adb shell dumpsys notification | grep "package:com.example.attendance_tracker"
```

### **View App Logs**
```bash
adb logcat | grep "flutter:"
```

### **Clear App Data**
```bash
adb shell pm clear com.example.attendance_tracker
```

---

## 📋 **Test Checklist**

### **App Startup**
- [ ] App starts without crash
- [ ] Firebase initializes successfully
- [ ] FCM service initializes
- [ ] FCM token generated
- [ ] Token sent to backend
- [ ] Faculty data loads
- [ ] Lectures display correctly

### **FCM Functionality**
- [ ] Token generation works
- [ ] Local notifications appear in foreground
- [ ] System notifications appear in background
- [ ] Notifications work when app terminated
- [ ] Navigation works on notification tap

### **Substitution Flow**
- [ ] "Assign this lec" button works
- [ ] Faculty selection modal appears
- [ ] "Send to All" creates substitution request
- [ ] Backend API responds correctly
- [ ] All faculty receive notifications
- [ ] Navigation to substitution requests works

### **Error Handling**
- [ ] No Firebase configuration handled gracefully
- [ ] Network errors handled gracefully
- [ ] Permission denied handled gracefully
- [ ] Invalid data handled gracefully

---

## 🎯 **Success Criteria**

### **Complete Success:**
- All test scenarios pass
- No app crashes
- All notifications work in all app states
- Substitution flow works end-to-end
- Navigation works correctly

### **Partial Success:**
- App starts but some features don't work
- Notifications work in some states but not all
- Substitution request created but notifications not received

### **Needs Attention:**
- App crashes on startup
- Firebase initialization fails
- Notifications don't appear
- Substitution flow broken
- Navigation doesn't work

---

## 📝 **Test Results Log**

### **Test Date:** 2026-04-07
### **Tester:** [Your Name]
### **Environment:** Android Emulator/Physical Device

#### **Test 1: App Startup**
- **Status:** ✅ PASS / ❌ FAIL
- **Notes:** [Your observations]

#### **Test 2: FCM Token**
- **Status:** ✅ PASS / ❌ FAIL
- **Token:** [Generated token]
- **Notes:** [Your observations]

#### **Test 3: Substitution Flow**
- **Status:** ✅ PASS / ❌ FAIL
- **Substitution ID:** [Generated ID]
- **Notes:** [Your observations]

#### **Test 4: Notification Reception**
- **Status:** ✅ PASS / ❌ FAIL
- **States Tested:** Foreground, Background, Terminated
- **Notes:** [Your observations]

---

## 🚀 **Production Deployment**

### **Before Production:**
1. ✅ Set up Firebase project
2. ✅ Add `google-services.json` to `android/app/`
3. ✅ Update main.dart to use real FCM service
4. ✅ Remove mock FCM service
5. ✅ Test all scenarios thoroughly
6. ✅ Remove debug logs (optional)

### **Production Checklist:**
- [ ] Firebase project created
- [ ] google-services.json added
- [ ] Real FCM service enabled
- [ ] All tests passing
- [ ] Debug logs removed
- [ ] App ready for production

---

**Last Updated:** 2026-04-07
**Version:** 1.0.0
