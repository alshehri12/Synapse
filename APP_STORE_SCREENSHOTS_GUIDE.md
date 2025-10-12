# App Store Screenshots Guide

## Overview
Apple requires specific screenshot sizes for different devices. This guide will help you capture and prepare screenshots for your Synapse app submission.

## Required Screenshot Sizes

### iPhone (Required)
- **6.9" Display (iPhone 16 Pro Max)**: 1320 x 2868 pixels (or 2796 x 1290 for landscape)
- **6.7" Display (iPhone 14 Plus, 15 Plus, 16 Plus)**: 1290 x 2796 pixels
- **6.5" Display (iPhone 11 Pro Max, XS Max)**: 1242 x 2688 pixels
- **5.5" Display (iPhone 8 Plus)**: 1242 x 2208 pixels

### iPad (Optional but Recommended)
- **12.9" Display (iPad Pro)**: 2048 x 2732 pixels
- **11" Display (iPad Pro)**: 1668 x 2388 pixels

## How to Capture Screenshots

### Method 1: Using Xcode Simulator (Recommended)

1. **Launch Xcode**
   - Open `Synapse.xcodeproj`

2. **Select Target Device**
   - Choose simulator: Product → Destination → Select device (e.g., iPhone 16 Pro Max)

3. **Run the App**
   - Press `⌘ + R` to build and run

4. **Navigate to Key Screens**
   - Onboarding screens
   - Authentication/Sign up
   - Main feed with ideas
   - Idea creation screen
   - Project creation screen
   - Profile screen
   - Settings screen

5. **Capture Screenshots**
   - While simulator is active, press `⌘ + S`
   - Screenshots save to Desktop by default
   - File names: `Simulator Screenshot - [Device] - [Date].png`

6. **Repeat for Each Device Size**
   - Switch simulator to different device
   - Capture same screens again

### Method 2: Using Physical Device

1. **Install TestFlight Build** (if you have one)
   - Or run directly from Xcode on connected device

2. **Capture Screenshot on Device**
   - **iPhone with Face ID**: Press Volume Up + Side button
   - **iPhone with Home Button**: Press Home + Side button

3. **Transfer to Mac**
   - AirDrop to Mac
   - Or use Image Capture app

## Screenshot Content Strategy

Apple allows up to **10 screenshots** per device size. Choose 5-8 of the most important screens.

### Recommended Screenshots (in order):

1. **Hero/Splash Screen** (optional but eye-catching)
   - Onboarding first screen with brain icon and "Spark Your Ideas" message

2. **Main Feed**
   - Show ideas from multiple users
   - Demonstrates social collaboration aspect
   - Make sure there's diverse, interesting content

3. **Idea Creation**
   - Show the idea creation form
   - Highlights AI categorization and tagging

4. **Project Creation**
   - Show project creation with multiple ideas being connected
   - Demonstrates collaboration features

5. **Profile Screen**
   - Show user profile with stats
   - Ideas and projects tabs visible

6. **Settings/Features**
   - Optional: Show settings or unique features like dark mode support

### Tips for Great Screenshots

1. **Use Real Content**
   - Don't show empty states
   - Fill with realistic, appealing ideas and projects
   - Use proper Arabic and English text based on your target market

2. **Add Text Overlays** (Optional but Recommended)
   - Use tools like Figma, Canva, or Sketch
   - Add short marketing text on top of screenshots:
     - "Transform Ideas into Reality"
     - "Collaborate with Creative Minds"
     - "AI-Powered Organization"
     - "Track Your Projects"

3. **Consistency**
   - Same content/user across all device sizes
   - Same order of screenshots
   - Professional and polished

4. **Localization**
   - If targeting Arabic market, show app in Arabic
   - If targeting English, show in English
   - You can upload different screenshots per language

## Screenshot Organization

Create this folder structure in your repo:

```
Synapse/
├── AppStoreAssets/
│   ├── Screenshots/
│   │   ├── iPhone_6.9/
│   │   │   ├── 01_onboarding.png
│   │   │   ├── 02_main_feed.png
│   │   │   ├── 03_idea_creation.png
│   │   │   ├── 04_project_creation.png
│   │   │   └── 05_profile.png
│   │   ├── iPhone_6.7/
│   │   │   └── (same files)
│   │   ├── iPhone_6.5/
│   │   │   └── (same files)
│   │   └── iPhone_5.5/
│   │       └── (same files)
│   └── Screenshots_Edited/ (if you add text overlays)
```

## Tools for Editing Screenshots

### Free Tools:
1. **Preview** (Built into macOS)
   - Basic editing, cropping, annotations

2. **Canva** (Free tier available)
   - Screenshot mockups
   - Add text overlays
   - Device frames

3. **Figma** (Free for individuals)
   - Professional editing
   - Screenshot templates
   - Export at exact sizes

### Paid Tools:
1. **Sketch** ($99/year)
   - Professional UI design tool
   - App Store screenshot templates

2. **Screenshots.pro** ($29/month)
   - Specialized for App Store screenshots
   - Automatic device framing

## Adding Device Frames (Optional)

Apple allows screenshots with or without device frames. If you want frames:

1. **Use Apple's Templates**
   - Download from: developer.apple.com/app-store/marketing/guidelines/

2. **Use Online Tools**
   - mockuphone.com
   - placeit.net
   - smartmockups.com

## Validation Before Upload

Before uploading to App Store Connect:

1. **Check Sizes**
   - Use Preview → Tools → Adjust Size to verify dimensions

2. **Check File Format**
   - Must be PNG or JPG
   - PNG recommended for better quality

3. **Check File Size**
   - Keep under 500KB per screenshot for faster loading

4. **Check Content**
   - No offensive content
   - No competitor branding
   - No fake functionality
   - Accurate representation of app

## Upload to App Store Connect

1. Go to App Store Connect
2. Select your app
3. Go to app version
4. Scroll to "App Previews and Screenshots"
5. Select device size
6. Drag and drop screenshots (order matters!)
7. Add captions if needed (optional but helpful for accessibility)

## Quick Start Checklist

- [ ] Run app on iPhone 16 Pro Max simulator
- [ ] Capture 5-8 key screens
- [ ] Repeat for iPhone 14 Plus/15 Plus simulator
- [ ] Repeat for iPhone 8 Plus simulator (if supporting iOS 15+)
- [ ] (Optional) Add text overlays to highlight features
- [ ] (Optional) Add device frames for polish
- [ ] Create folder structure: `AppStoreAssets/Screenshots/`
- [ ] Organize screenshots by device size
- [ ] Verify image dimensions and format
- [ ] Upload to App Store Connect in order

## Need Help?

If you want me to help with:
- Creating mockup data for screenshots
- Suggesting specific screens to highlight
- Creating screenshot dimensions guide
- Automating screenshot capture

Just let me know!
