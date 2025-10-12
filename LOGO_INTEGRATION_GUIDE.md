# Logo Integration Guide for Synapse

## Overview
This guide explains how to add your logo to the Synapse app as the app icon, which appears on the home screen and throughout iOS.

## Required Image Sizes

Apple requires multiple sizes of your app icon for different devices and contexts. The standard App Icon set includes:

### iOS App Icon Sizes (All Required)

| Size | Usage | Pixels |
|------|-------|--------|
| 1024×1024 | App Store | 1024×1024 px |
| 180×180 | iPhone @3x | 180×180 px |
| 120×120 | iPhone @2x | 120×120 px |
| 167×167 | iPad Pro @2x | 167×167 px |
| 152×152 | iPad @2x | 152×152 px |
| 76×76 | iPad @1x | 76×76 px |
| 60×60 | iPhone @1x (Settings) | 60×60 px |
| 40×40 | Spotlight @1x | 40×40 px |
| 29×29 | Settings @1x | 29×29 px |
| 80×80 | Spotlight @2x | 80×80 px |
| 58×58 | Settings @2x | 58×58 px |
| 87×87 | Settings @3x | 87×87 px |
| 120×120 | Spotlight @2x | 120×120 px |

## Logo Design Requirements

### Apple's App Icon Guidelines:

1. **No Transparency**
   - App icons cannot have transparent backgrounds
   - Fill entire square with color or design

2. **No Rounded Corners**
   - iOS automatically applies rounded corners
   - Provide square images only
   - iOS will round them automatically

3. **Simple & Recognizable**
   - Should work at small sizes (29×29)
   - Avoid fine details that disappear when scaled
   - High contrast for visibility

4. **Consistent Across Sizes**
   - Same design for all sizes
   - Don't add/remove elements at different scales

5. **File Format**
   - PNG format required
   - RGB color space (not CMYK)
   - No alpha channel

## How to Prepare Your Logo

### Option 1: Using Preview (macOS Built-in)

1. **Open your logo in Preview**
2. **For each required size:**
   - Tools → Adjust Size
   - Set width and height (e.g., 1024×1024)
   - Resolution: 72 pixels/inch
   - Ensure "Scale proportionally" is checked
   - Click OK
   - File → Export → Format: PNG → Save

3. **Repeat for all sizes**
   - Save each with descriptive name:
     - `icon-1024.png`
     - `icon-180.png`
     - `icon-120.png`
     - etc.

### Option 2: Using Online Tools (Easiest)

**AppIconMaker.co** (Free)
1. Upload your 1024×1024 logo
2. Click "Generate"
3. Download zip with all sizes
4. Automatically named correctly

**MakeAppIcon.com** (Free)
1. Upload your logo (min 1024×1024)
2. Select iOS
3. Download all sizes

**AppIcon.co** (Free)
1. Drag and drop 1024×1024 image
2. Get all required sizes instantly
3. Includes iOS, Android, and web icons

### Option 3: Using Figma (Free, Professional)

1. Create 1024×1024 artboard
2. Design or import your logo
3. Create export presets for each size:
   - Select layer → Export settings
   - Add sizes: 1024, 180, 120, etc.
   - Format: PNG
   - Click "Export"

## Adding Logo to Xcode Project

### Step 1: Locate App Icon Asset

1. Open Xcode
2. Open `Synapse.xcodeproj`
3. In Project Navigator (left sidebar), find:
   ```
   Synapse/
   └── Assets.xcassets/
       └── AppIcon.appiconset/
   ```
4. Click on `AppIcon`

### Step 2: Add Your Logo Images

You'll see a grid with empty slots for different sizes:

1. **Drag and Drop Method:**
   - Drag each icon size from Finder
   - Drop into corresponding slot in Xcode
   - Xcode matches by size automatically

2. **Manual Method:**
   - Click on empty slot
   - Navigate to your icon file
   - Select and click "Open"

### Step 3: Fill All Required Slots

Make sure you fill these specific slots in Xcode:

- **iPhone App iOS 14+ (60pt @3x)** → 180×180
- **iPhone App iOS 14+ (60pt @2x)** → 120×120
- **iPad App iOS 14+ (83.5pt @2x)** → 167×167
- **iPad App iOS 14+ (76pt @2x)** → 152×152
- **iPad App iOS 14+ (76pt @1x)** → 76×76
- **App Store iOS 14+ (1024pt @1x)** → 1024×1024
- **iPhone Settings iOS 14+ (29pt @3x)** → 87×87
- **iPhone Settings iOS 14+ (29pt @2x)** → 58×58
- **iPad Settings iOS 14+ (29pt @2x)** → 58×58
- **iPhone Spotlight iOS 14+ (40pt @3x)** → 120×120
- **iPhone Spotlight iOS 14+ (40pt @2x)** → 80×80
- **iPad Spotlight iOS 14+ (40pt @2x)** → 80×80

### Step 4: Verify Installation

1. **Check for Warnings:**
   - Look for yellow warnings in Xcode
   - Common issues:
     - Wrong size
     - Has transparency
     - Wrong color space

2. **Build and Run:**
   ```bash
   # In Xcode, press �Cmd + R
   # or use terminal:
   xcodebuild -scheme Synapse -destination 'platform=iOS Simulator,name=iPhone 16'
   ```

3. **Check Home Screen:**
   - After app launches, press Home button
   - Your icon should appear on simulator home screen
   - Verify it looks good at this size

## Alternative: Using Asset Catalog

If you only have a 1024×1024 image and want Xcode to handle resizing:

### Step 1: Configure Asset Catalog

1. Click on `AppIcon` in Assets.xcassets
2. Open Attributes Inspector (right sidebar)
3. Check these boxes:
   - ☑ iPhone
   - ☑ iPad
   - ☑ iOS Marketing (1024×1024)

### Step 2: Use Single Image

**Warning:** This method works but may not be optimal for smaller sizes.

1. Right-click on `AppIcon.appiconset` folder in Finder
2. Show in Finder
3. Add your 1024×1024 image named `icon-1024.png`
4. Edit `Contents.json` to reference this image for all sizes

**Better approach:** Use online tools to generate all sizes properly.

## Updating Logo After Submission

If you need to change your logo after app is published:

1. Follow same steps above with new logo
2. Increment version number in Xcode:
   - Select project in Navigator
   - Target → General
   - Bump version (e.g., 1.0 → 1.1)
3. Submit new version to App Store

**Note:** Icon changes require app review, typically 1-2 days.

## Common Issues & Solutions

### Issue 1: "Alpha channel found"
**Solution:**
- Logo has transparency
- Open in Preview → Export → Uncheck "Alpha"
- Or use online tool to remove transparency

### Issue 2: "Wrong color space"
**Solution:**
- Logo is in CMYK instead of RGB
- Open in Preview → Tools → Assign Profile → sRGB
- Export again

### Issue 3: Icon looks blurry
**Solution:**
- Original image is too small
- Use vector logo if available
- Scale up to 1024×1024 in design tool (Figma, Illustrator)
- Don't upscale PNG in Preview (creates blur)

### Issue 4: Icon not showing in simulator
**Solution:**
- Clean build folder: Shift + Cmd + K
- Delete app from simulator
- Rebuild and run
- Sometimes requires simulator restart

### Issue 5: Different icon in App Store vs Device
**Solution:**
- Make sure 1024×1024 "App Store" slot is filled
- This is the icon shown in App Store listings
- Device icons come from smaller sizes

## What to Send Me

When you're ready to add your logo, please provide:

### Option A: Single High-Res Logo
- **Size:** At least 1024×1024 pixels
- **Format:** PNG, JPG, or vector (SVG, AI, PDF)
- **Background:** If transparent, tell me preferred background color

I'll generate all required sizes for you.

### Option B: Pre-Generated Icon Set
- All sizes listed above
- Named clearly (e.g., `icon-1024.png`, `icon-180.png`)
- As a zip file

I'll add them directly to Xcode.

## Logo Design Tips

If you're still designing your logo:

1. **Keep It Simple**
   - Single object or letter works best
   - Avoid complex illustrations

2. **Use Bold Colors**
   - High contrast for visibility
   - Stand out on home screen
   - Test on both light and dark backgrounds

3. **Avoid Text**
   - Small text is unreadable at 29×29
   - If text needed, make it large and bold
   - Consider icon + wordmark separately

4. **Test at Small Size**
   - Zoom out to see how 29×29 looks
   - Can you still recognize it?

5. **Look at Competitors**
   - Check similar apps in App Store
   - See what works in your category
   - Stand out but fit the category aesthetic

## Example: Brain Icon for Synapse

If using the brain emoji/icon as logo:

1. **Find high-res brain icon:**
   - flaticon.com (attribution required for free)
   - iconfinder.com
   - thenounproject.com

2. **Add background:**
   - Green (#10b981 - your accent color)
   - Or gradient green to blue
   - Or keep white/minimalist

3. **Generate sizes**
4. **Add to Xcode**

Want me to help design a simple brain icon in the meantime?

## Quick Start Steps

1. **Prepare your 1024×1024 logo**
   - Square format
   - No transparency
   - PNG file

2. **Generate all sizes**
   - Use makeappicon.com
   - Upload your 1024×1024
   - Download zip

3. **Add to Xcode:**
   ```
   Open Synapse.xcodeproj
   → Assets.xcassets
   → AppIcon
   → Drag all icons to their slots
   ```

4. **Build and test:**
   ```bash
   Cmd + R in Xcode
   Check home screen icon
   ```

5. **Commit changes:**
   ```bash
   git add Assets.xcassets/AppIcon.appiconset/
   git commit -m "Add app icon"
   ```

## Need Help?

Let me know if you need assistance with:
- Resizing your logo to required sizes
- Removing transparency from logo
- Converting color space
- Adding background to logo
- Creating simple brain icon as placeholder
- Troubleshooting Xcode icon issues
- Designing a new logo from scratch

Just send me your logo file and I'll handle the technical parts!
