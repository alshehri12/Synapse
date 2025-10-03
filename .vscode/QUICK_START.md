# 🚀 Quick Start: Run Synapse from VS Code

## Fastest Way to Run

### Method 1: Using Keyboard Shortcut
1. Press `Cmd+Shift+B` (Build)
2. Then run task "Launch App on Simulator"

### Method 2: One-Click Run
1. Press `Cmd+Shift+P`
2. Type "Tasks: Run Task"
3. Select **"Full Build and Run"**
4. ✅ App builds and launches automatically!

### Method 3: Step by Step
```bash
# Step 1: Boot simulator
Cmd+Shift+P → "Tasks: Run Task" → "Boot Simulator"

# Step 2: Build project
Cmd+Shift+B

# Step 3: Launch app
Cmd+Shift+P → "Tasks: Run Task" → "Launch App on Simulator"
```

## 🎯 Common Tasks Shortcuts

| What You Want | How To Do It |
|---------------|--------------|
| Build project | `Cmd+Shift+B` |
| Run on simulator | Task: "Full Build and Run" |
| Clean build | Task: "Clean Build Folder" |
| Open Xcode | Task: "Open in Xcode" |
| See simulators | Task: "List Available Simulators" |

## 💡 Pro Tips

1. **Split View**: Edit Swift files in VS Code, keep Simulator open on the side
2. **Hot Reload**: After changes, just run "Build and Run" again
3. **Logs**: Check Debug Console (`Cmd+Shift+Y`) for build output
4. **Quick Open**: Press `Cmd+P` and type filename to quickly navigate

## 🛠️ If Something Goes Wrong

**Simulator won't boot?**
```bash
# Open simulator manually
open -a Simulator
```

**Build fails?**
```bash
# Clean and rebuild
Cmd+Shift+P → "Clean Build Folder" → then → "Build Synapse"
```

**App won't install?**
```bash
# Check app was built
find ~/Library/Developer/Xcode/DerivedData -name "Synapse.app"
```

## 📱 Current Configuration

- **Simulator**: iPhone 16 Pro
- **iOS Version**: 18.1
- **Build Config**: Debug
- **Bundle ID**: Abdulrahman.Synapse

Ready to code! 🎉
