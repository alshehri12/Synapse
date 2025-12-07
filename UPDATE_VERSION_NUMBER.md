# 📦 How to Update App Version Number for App Store

## ❌ Current Error:

```
Invalid Pre-Release Train. The train version '1.1' is closed for new build submissions
CFBundleShortVersionString [1.1] must contain a higher version than previously approved version [1.1]
```

## ✅ Solution: Increase Version Number

You need to change the version from **1.1** to **1.2** (or higher).

---

## 🎯 Step-by-Step Instructions (2 minutes)

### **Step 1: Open Xcode Project**

1. Open **Synapse.xcodeproj** in Xcode
2. Make sure you're viewing the project (not a file)

### **Step 2: Update Version Number**

1. In the left sidebar, click on **Synapse** (the blue app icon at the very top)

2. Make sure the **Synapse** target is selected (in the TARGETS section)

3. Go to the **General** tab (top of the window)

4. Find the **Identity** section (near the top)

5. You'll see two fields:
   ```
   Version: 1.1          ← Change this to 1.2
   Build: [some number]  ← You can also increment this (optional)
   ```

6. **Change Version from `1.1` to `1.2`**

7. **Optional but recommended:** Change Build number too (e.g., from 1 to 2, or whatever the next number is)

### **Step 3: Save**

- Press **Cmd + S** to save
- Or just click outside the field

### **Step 4: Archive Again**

1. **Product** menu → **Clean Build Folder** (Cmd + Shift + K)
2. **Product** menu → **Archive**
3. Wait for archive to complete
4. In Organizer → **Distribute App**
5. Follow the upload process

---

## 📊 Version Number Explanation

### **Version (CFBundleShortVersionString)**
- What users see in the App Store
- Format: Major.Minor.Patch (e.g., 1.2.0 or just 1.2)
- Must be **higher** than previous version
- Examples:
  - 1.1 → 1.2 ✅ (next minor update)
  - 1.1 → 2.0 ✅ (major update)
  - 1.1 → 1.1.1 ✅ (patch/bug fix)

### **Build (CFBundleVersion)**
- Internal build number
- Not visible to users
- Can be any increasing number
- Examples:
  - 1, 2, 3, 4...
  - 2024120701, 2024120702... (date-based)

---

## 🎯 Recommended Version Numbers

Since you're adding:
- Bug fixes (private ideas, leave pod)
- New features (password reset, better emails)
- UI improvements

### **Option 1: Minor Update (Recommended)**
```
Version: 1.2
Build: [increment by 1]
```
Use this if: You have new features + bug fixes

### **Option 2: Patch Update**
```
Version: 1.1.1
Build: [increment by 1]
```
Use this if: Mostly bug fixes, small improvements

### **Option 3: Major Update**
```
Version: 2.0
Build: 1
```
Use this if: Significant changes, major redesign (probably not this time)

---

## ✅ Quick Checklist

Before archiving:
- [ ] Version number is higher than 1.1 (e.g., 1.2)
- [ ] Build number is incremented
- [ ] Project saved (Cmd + S)
- [ ] Clean build folder (Cmd + Shift + K)

During archive:
- [ ] Archive completes successfully
- [ ] No build errors
- [ ] Organizer shows new archive

During upload:
- [ ] Select correct team
- [ ] Validate before uploading (recommended)
- [ ] Upload to App Store Connect

---

## 🆘 If Still Getting Version Error

### Check App Store Connect:

1. Go to https://appstoreconnect.apple.com
2. Select your Synapse app
3. Look at the current version
4. Your new version **must be higher** than what's shown there

### Common Issues:

**Issue:** "Version 1.2 already exists"
**Fix:** Use 1.3 or 2.0

**Issue:** "Build number already used"
**Fix:** Increment the build number to something not used before

**Issue:** "Version format invalid"
**Fix:** Use format X.X or X.X.X (no letters, no spaces)

---

## 📝 After Successful Upload

1. ✅ Archive uploaded successfully
2. ✅ Build appears in App Store Connect (may take 5-10 minutes)
3. ✅ Build processing completes
4. ✅ Add to existing version or create new version
5. ✅ Fill in "What's New" text (use the App Store update text I provided)
6. ✅ Submit for review

---

## 🎉 Summary

**What to do RIGHT NOW:**

1. Open Xcode
2. Click Synapse (blue icon) in left sidebar
3. General tab → Identity section
4. Change **Version: 1.1** to **Version: 1.2**
5. Save (Cmd + S)
6. Product → Clean Build Folder
7. Product → Archive
8. Upload to App Store

**That's it!** The version error will be fixed! 🚀
