# VS Code Configuration for Synapse iOS App

This directory contains VS Code configuration files to help you build and run the Synapse iOS app from VS Code.

## 📋 Quick Start

### Option 1: Using Tasks (Recommended)
1. Press `Cmd+Shift+P` to open command palette
2. Type "Tasks: Run Task"
3. Select one of the available tasks:

#### Available Tasks:
- **Build Synapse** - Build the project (default build task: `Cmd+Shift+B`)
- **Full Build and Run** - Build and launch on simulator
- **Boot Simulator** - Start the iPhone 16 Pro simulator
- **Launch App on Simulator** - Install and run the app
- **Clean Build Folder** - Clean the build cache
- **Open in Xcode** - Open project in Xcode
- **List Available Simulators** - Show all available iOS simulators

### Option 2: Command Line
Use the integrated terminal in VS Code:

```bash
# Build the project
xcodebuild -project Synapse.xcodeproj -scheme Synapse -configuration Debug -sdk iphonesimulator

# Boot simulator
xcrun simctl boot "iPhone 16 Pro" && open -a Simulator

# Install app on simulator
xcrun simctl install booted ~/Library/Developer/Xcode/DerivedData/.../Synapse.app

# Launch app
xcrun simctl launch booted Abdulrahman.Synapse
```

### Option 3: Open in Xcode
For full Xcode features (Interface Builder, SwiftUI Previews):
1. Run task: "Open in Xcode"
2. Or from terminal: `open Synapse.xcodeproj`

## 🛠️ Configuration Files

### tasks.json
Contains build and run tasks that can be executed from VS Code command palette.

### launch.json
LLDB debugger configuration for debugging iOS apps (requires CodeLLDB extension).

### settings.json
Swift-specific editor settings including:
- SourceKit-LSP path for code completion
- File associations
- Build artifact exclusions

## 📦 Recommended VS Code Extensions

For the best Swift/iOS development experience in VS Code:

1. **Swift** (sswg.swift-lang) - Official Swift extension with LSP support
2. **CodeLLDB** (vadimcn.vscode-lldb) - LLDB debugger for native code
3. **iOS Common Files** - Syntax highlighting for .plist, .xcconfig files

Install via:
```bash
code --install-extension sswg.swift-lang
code --install-extension vadimcn.vscode-lldb
```

## ⚙️ Simulator Configuration

Current configuration uses:
- **Device**: iPhone 16 Pro
- **iOS Version**: 18.1
- **Configuration**: Debug
- **SDK**: iphonesimulator

To change the simulator:
1. Run task "List Available Simulators" to see options
2. Edit `.vscode/tasks.json`
3. Update the `-destination` parameter in tasks

## 🔍 Troubleshooting

### Build Fails
- Ensure Xcode command line tools are installed: `xcode-select --install`
- Check Xcode version: `xcodebuild -version`
- Clean build folder with "Clean Build Folder" task

### Simulator Issues
- Ensure simulator is available: Run "List Available Simulators" task
- Boot simulator manually: Run "Boot Simulator" task
- Reset simulator: Open Simulator app → Device → Erase All Content and Settings

### SourceKit-LSP Not Working
- Verify path in settings.json matches your Xcode installation
- Restart VS Code
- Check Xcode is set as active developer directory: `sudo xcode-select -s /Applications/Xcode.app`

### App Not Installing
- Find the .app bundle path:
  ```bash
  find ~/Library/Developer/Xcode/DerivedData -name "Synapse.app"
  ```
- Verify bundle identifier: `Abdulrahman.Synapse`

## 📝 Notes

- **SwiftUI Previews**: Not available in VS Code, use Xcode for previews
- **Interface Builder**: .storyboard/.xib files require Xcode
- **Debugging**: Basic LLDB debugging works, but Xcode has better iOS debugging tools
- **Performance**: VS Code is faster for code editing, Xcode is better for UI work

## 🚀 Workflow Recommendation

**Optimal hybrid workflow:**
1. Use VS Code for Swift code editing (faster, better extensions)
2. Use "Open in Xcode" task when you need:
   - SwiftUI Previews
   - Asset catalog editing
   - Advanced debugging
   - Performance profiling

## 🔗 Useful Commands

```bash
# Check project info
xcodebuild -project Synapse.xcodeproj -list

# Show build settings
xcodebuild -project Synapse.xcodeproj -showBuildSettings

# View simulator device types
xcrun simctl list devicetypes

# View app logs
xcrun simctl spawn booted log stream --predicate 'processImagePath contains "Synapse"'
```
