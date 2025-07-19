#!/bin/bash

# Script to add Google Sign-In dependencies to Xcode project

echo "Adding Google Sign-In dependencies..."

# Add Google Sign-In Swift Package
# Note: This needs to be done manually in Xcode
echo "Please add the following Swift Package in Xcode:"
echo "URL: https://github.com/google/GoogleSignIn-iOS"
echo "Dependency Rule: Up to Next Major Version"
echo "Products to add:"
echo "  - GoogleSignIn"
echo "  - GoogleSignInSwift"

echo ""
echo "After adding the package, the project should build successfully."
echo "If you encounter any issues, please check:"
echo "1. GoogleService-Info.plist is properly configured"
echo "2. URL schemes are added to Info.plist"
echo "3. Bundle ID matches the one in Firebase console" 