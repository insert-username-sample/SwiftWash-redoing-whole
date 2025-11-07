# SwiftWash Mobile App - Testing Instructions
## Maps & Address Saving Functionality

### **Overview**
This document provides detailed testing instructions for the main SwiftWash Mobile user app, specifically focusing on Google Maps integration and address saving functionality.

### **Prerequisites**
- ✅ SwiftWash Mobile app installed on test device
- ✅ Google Maps API keys configured in `.env` file
- ✅ Firebase project `swiftwash-v0-1` properly configured
- ✅ Test device with location services enabled
- ✅ Active internet connection

### **Environment Configuration**
Before testing, ensure your `.env` file contains:
```env
# Google Maps API Keys (Platform-specific)
GOOGLE_MAPS_API_KEY_ANDROID=your_actual_android_maps_key
GOOGLE_MAPS_API_KEY_IOS=your_actual_ios_maps_key

# UPI Payment Configuration
UPI_HANDLE=your_test_upi_id@oksbi
MERCHANT_NAME=SwiftWash Laundry
CURRENCY=INR
```

## **🗺️ Maps Integration Testing**

### **Test Case 1: Address Search & Selection**
**Objective**: Verify Google Maps Places API integration for address search

**Steps**:
1. Navigate to "Add Address" screen in the app
2. Tap on the search bar for address input
3. Enter a partial address (e.g., "123 MG Road")
4. Verify autocomplete suggestions appear
5. Select a suggestion from the dropdown
6. Verify map updates to show selected location
7. Confirm red pin marker appears on map

**Expected Results**:
- ✅ Autocomplete suggestions load within 2 seconds
- ✅ Map animates smoothly to selected location
- ✅ Red pin marker displays accurately
- ✅ Address fields auto-populate from selection

**Troubleshooting**:
- If no suggestions appear: Check Google Places API key restrictions
- If map doesn't load: Verify Maps SDK API key configuration
- If poor performance: Check network connectivity

### **Test Case 2: Manual Pin Placement**
**Objective**: Test manual location selection on map

**Steps**:
1. Navigate to address creation screen
2. Long-press on map to place pin manually
3. Verify pin placement accuracy
4. Confirm address geocoding works
5. Save address and verify coordinates are stored

**Expected Results**:
- ✅ Pin placement responds to touch within 100ms
- ✅ Geocoding API returns accurate address
- ✅ Coordinates save correctly to Firestore
- ✅ Map marker updates in real-time

### **Test Case 3: Address Saving to Firestore**
**Objective**: Verify address data persistence

**Steps**:
1. Complete address creation with map selection
2. Fill all required fields (name, phone, address details)
3. Save address to Firestore
4. Navigate back and verify address appears in list
5. Check Firestore console for data accuracy

**Expected Results**:
- ✅ Address saves successfully without errors
- ✅ All fields persist correctly in Firestore
- ✅ Real-time updates reflect in address list
- ✅ Latitude/longitude coordinates are accurate

## **📍 Address Management Testing**

### **Test Case 4: Address List Display**
**Objective**: Verify saved addresses load and display correctly

**Steps**:
1. Navigate to "My Addresses" or address selection screen
2. Verify StreamBuilder loads addresses from Firestore
3. Check each address displays correct information
4. Verify map preview shows for each address

**Expected Results**:
- ✅ Addresses load within 1 second
- ✅ All address fields display correctly
- ✅ Map preview renders for each address
- ✅ No duplicate addresses appear

### **Test Case 5: Address Editing**
**Objective**: Test address modification functionality

**Steps**:
1. Select an existing address from the list
2. Modify address details (name, phone, location)
3. Update location using map if needed
4. Save changes
5. Verify updates reflect in Firestore

**Expected Results**:
- ✅ Edit mode activates correctly
- ✅ Map integration works for location updates
- ✅ Changes save successfully
- ✅ Real-time updates appear in UI

### **Test Case 6: Address Deletion**
**Objective**: Verify address removal functionality

**Steps**:
1. Select an address from the list
2. Tap delete button
3. Confirm deletion in dialog
4. Verify address removes from list
5. Check Firestore for data removal

**Expected Results**:
- ✅ Deletion confirmation dialog appears
- ✅ Address removes from UI immediately
- ✅ Firestore document deletes successfully
- ✅ No orphaned data remains

## **🔍 Order Flow Integration Testing**

### **Test Case 7: Address Selection in Order Flow**
**Objective**: Test address selection during order placement

**Steps**:
1. Start new order (Ironing/Laundry/Swift)
2. Navigate to Step 3 (Address Selection)
3. Select a saved address from the list
4. Verify address details populate correctly
5. Complete order flow

**Expected Results**:
- ✅ Address selection works smoothly
- ✅ Selected address data transfers to order
- ✅ Map preview displays correctly
- ✅ Order completes with correct address

### **Test Case 8: New Address Creation in Order Flow**
**Objective**: Test adding new address during order placement

**Steps**:
1. Start new order and reach address selection
2. Tap "Add New Address" button
3. Use Google Maps to search and select location
4. Fill address details
5. Save and verify selection in order

**Expected Results**:
- ✅ New address creation works seamlessly
- ✅ Maps integration functions properly
- ✅ Address saves and selects automatically
- ✅ Order flow continues without interruption

## **🚨 Error Handling & Edge Cases**

### **Test Case 9: Network Connectivity Issues**
**Objective**: Test behavior during network failures

**Steps**:
1. Disable network connectivity on test device
2. Attempt to use maps functionality
3. Attempt to save/load addresses
4. Re-enable network and retry operations

**Expected Results**:
- ✅ Graceful error messages display
- ✅ App doesn't crash on network failures
- ✅ Operations retry successfully when online
- ✅ User feedback is clear and helpful

### **Test Case 10: Location Services Disabled**
**Objective**: Test behavior when location services are off

**Steps**:
1. Disable location services on test device
2. Attempt to use map features
3. Attempt address-related operations
4. Re-enable location services

**Expected Results**:
- ✅ Clear prompt to enable location services
- ✅ App handles disabled location gracefully
- ✅ Full functionality restored when enabled
- ✅ No data loss during disabled state

### **Test Case 11: Invalid Address Data**
**Objective**: Test handling of malformed address data

**Steps**:
1. Manually corrupt address data in Firestore (test environment)
2. Attempt to load addresses in app
3. Verify error handling
4. Restore valid data

**Expected Results**:
- ✅ App handles corrupted data gracefully
- ✅ No crashes occur with invalid data
- ✅ User can continue using other features
- ✅ Clear error logging for debugging

## **📊 Performance Testing**

### **Test Case 12: Map Loading Performance**
**Objective**: Verify acceptable map loading times

**Steps**:
1. Navigate to address selection screen
2. Measure time for map to load
3. Measure time for address search
4. Test with various network conditions

**Expected Results**:
- ✅ Map loads within 2 seconds on 4G
- ✅ Map loads within 5 seconds on 3G
- ✅ Address search responds within 1 second
- ✅ Smooth animations and transitions

### **Test Case 13: Memory Usage**
**Objective**: Verify app doesn't leak memory during map usage

**Steps**:
1. Monitor memory usage before map operations
2. Perform multiple map operations (search, pan, zoom)
3. Navigate away from map screens
4. Monitor memory usage after operations

**Expected Results**:
- ✅ Memory usage stable during map operations
- ✅ No memory leaks detected
- ✅ Memory releases properly when leaving map screens
- ✅ App remains responsive throughout

## **🔧 Troubleshooting Guide**

### **Common Issues & Solutions**

#### **Issue 1: Maps not loading**
**Symptoms**: Blank screen or error message when accessing maps
**Solutions**:
1. Verify Google Maps API keys are correctly set in `.env`
2. Check API key restrictions in Google Cloud Console
3. Ensure Maps SDK for Android/iOS is enabled
4. Verify internet connectivity

#### **Issue 2: Address search not working**
**Symptoms**: No autocomplete suggestions appear
**Solutions**:
1. Verify Places API is enabled in Google Cloud Console
2. Check API key has Places API permissions
3. Verify billing is enabled on Google Cloud project
4. Check network connectivity and try again

#### **Issue 3: Addresses not saving**
**Symptoms**: Address creation appears to work but doesn't persist
**Solutions**:
1. Check Firestore security rules allow address creation
2. Verify user is authenticated
3. Check Firebase project configuration
4. Review Firestore console for error logs

#### **Issue 4: Poor map performance**
**Symptoms**: Slow loading, laggy interactions
**Solutions**:
1. Check network speed and connectivity
2. Verify device meets minimum requirements
3. Clear app cache and data
4. Update Google Play Services (Android)

## **📝 Test Reporting Template**

Use this template for test reporting:

```markdown
# Test Report: [Date]

## Test Environment
- Device: [Device model]
- OS Version: [iOS/Android version]
- App Version: [App version]
- Network: [WiFi/Cellular]

## Test Results Summary
- ✅ Passed: [Number] tests
- ❌ Failed: [Number] tests
- ⚠️ Blocked: [Number] tests

## Detailed Results

### Test Case 1: [Name]
- Status: [Pass/Fail/Blocked]
- Steps Completed: [1-5]
- Actual Results: [Description]
- Expected Results: [Description]
- Screenshots: [Attach if relevant]

## Issues Found
1. [Issue description]
   - Severity: [High/Medium/Low]
   - Steps to reproduce: [1, 2, 3]
   - Workaround: [If available]

## Recommendations
- [Suggested improvements or fixes]
```

## **🎯 Success Criteria**

**All critical functionality must work:**
- ✅ Address search and selection
- ✅ Map interaction and pin placement
- ✅ Address saving and loading
- ✅ Integration with order flow

**Performance requirements:**
- ✅ Map loads within 3 seconds
- ✅ Address operations complete within 2 seconds
- ✅ No memory leaks during extended use

**Error handling:**
- ✅ Graceful degradation on network issues
- ✅ Clear error messages for users
- ✅ Proper logging for debugging

## **🚀 Next Steps**

After completing these tests:
1. Document any issues found with screenshots
2. Report critical bugs to development team
3. Verify fixes in subsequent test cycles
4. Update test cases based on new features

---

**Note**: This testing guide focuses specifically on maps and address functionality as requested. For complete app testing, refer to the full test suite documentation.
