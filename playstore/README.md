# Google Play Store Publishing Files

This folder contains all the necessary files and information for publishing SnapNote Voice on the Google Play Store.

## Files Included

### 1. PRIVACY_POLICY.md / PRIVACY_POLICY.html
- Complete privacy policy document
- HTML version for hosting online
- Markdown version for reference
- **Action Required**: Host the HTML file online and provide URL in Play Console

### 2. APP_DESCRIPTION.txt
- Short description (80 characters)
- Full description (4000 characters)
- Ready to copy-paste into Play Console

### 3. DATA_SAFETY.txt
- Complete data safety form information
- Answers to all Google Play data safety questions
- Use this to fill out the Data Safety section in Play Console

### 4. CONTENT_RATING.txt
- Content rating questionnaire answers
- Recommended rating: Everyone
- Use this to complete content rating in Play Console

### 5. STORE_LISTING_CHECKLIST.md
- Complete checklist for store listing
- Asset requirements and specifications
- Pre-launch and post-launch tasks

## Quick Start Guide

### Step 1: Prepare Assets
1. **App Icon**: Already configured (or update using `assets/app_icon.png`)
2. **Feature Graphic**: Create 1024x500px banner
3. **Screenshots**: Take at least 2 screenshots (1080x1920px recommended)

### Step 2: Host Privacy Policy
1. Upload `PRIVACY_POLICY.html` to your website
2. Note the URL (e.g., `https://yourwebsite.com/privacy-policy.html`)

### Step 3: Fill Play Console
1. **Store Listing**:
   - Copy short description from `APP_DESCRIPTION.txt`
   - Copy full description from `APP_DESCRIPTION.txt`
   - Upload feature graphic
   - Upload screenshots
   - Add privacy policy URL

2. **Content Rating**:
   - Use answers from `CONTENT_RATING.txt`
   - Complete questionnaire

3. **Data Safety**:
   - Use information from `DATA_SAFETY.txt`
   - Fill out data safety form

4. **App Content**:
   - Select "Productivity" category
   - Mark as "Free" app
   - No ads, no in-app purchases

### Step 4: Build and Upload
1. Build release AAB:
   ```bash
   flutter build appbundle --release
   ```

2. Upload to Play Console:
   - Go to Play Console
   - Create new app
   - Upload the AAB file from `build/app/outputs/bundle/release/`

### Step 5: Complete Store Listing
- Fill in all required information
- Upload all assets
- Complete content rating
- Complete data safety form
- Submit for review

## Important Notes

1. **Privacy Policy URL**: Must be accessible online. You can use:
   - GitHub Pages (free)
   - Your own website
   - Any static hosting service

2. **App Signing**: The app is configured to use `key.properties` for signing. Make sure:
   - `android/key.properties` file exists
   - Contains correct keystore information
   - Keystore file is secure and backed up

3. **Testing**: Before publishing:
   - Test on multiple Android devices
   - Test all features (voice, camera, text)
   - Test permissions flow
   - Test in both light and dark mode

4. **First Release**: Consider using:
   - Internal testing track first
   - Then closed beta
   - Then open beta
   - Finally production

## Support

For questions or issues:
- **Email**: minormendcon1997@gmail.com
- **Company**: MINORMEND CONSTRUCTION PRIVATE LIMITED

## Compliance

All files are designed to comply with:
- Google Play Store policies
- GDPR requirements
- CCPA requirements
- Android privacy best practices

