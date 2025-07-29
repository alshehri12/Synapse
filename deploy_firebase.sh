#!/bin/bash

# Firebase Deployment Script for Synapse
# This script deploys Firestore security rules and indexes to fix chat functionality

echo "🚀 Deploying Firebase configuration for Synapse..."
echo "================================================"

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed."
    echo "Please install it with: npm install -g firebase-tools"
    exit 1
fi

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    echo "🔐 Please login to Firebase:"
    firebase login
fi

echo ""
echo "📋 What will be deployed:"
echo "  ✅ Firestore Security Rules (firestore.rules)"
echo "  ✅ Firestore Indexes (firestore.indexes.json)"
echo ""

read -p "Continue with deployment? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔥 Deploying Firestore rules and indexes..."
    
    # Deploy Firestore rules and indexes
    if firebase deploy --only firestore; then
        echo ""
        echo "✅ Deployment successful!"
        echo ""
        echo "🎉 Chat functionality should now work properly!"
        echo "   - Messages will sync between all pod members"
        echo "   - Typing indicators will show for other users"
        echo "   - Security rules prevent unauthorized access"
        echo ""
        echo "🔧 Next steps:"
        echo "   1. Test the chat in your app"
        echo "   2. Check Firebase Console for any rule violations"
        echo "   3. Monitor the logs with: firebase functions:log"
    else
        echo ""
        echo "❌ Deployment failed!"
        echo "Please check your Firebase project configuration."
        exit 1
    fi
else
    echo "Deployment cancelled."
    exit 0
fi 