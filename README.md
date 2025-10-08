# 🧠 Synapse - Collaborative Innovation Platform

A modern iOS app built with SwiftUI that connects creative minds and transforms ideas into reality through collaborative pods.

## ✨ Features

### 🚀 Core Functionality
- **Idea Sharing & Discovery**: Share innovative ideas and discover projects from the community
- **Collaborative Pods**: Create and join collaborative teams to work on ideas together
- **Real-time Chat**: Built-in messaging system for seamless team communication
- **Task Management**: Organize and track progress with integrated task management
- **Analytics Dashboard**: Monitor project progress and team performance
- **Multi-language Support**: English and Arabic localization

### 🎯 Key Capabilities
- **Supabase Integration**: Auth, Postgres with RLS, and realtime
- **Google Sign-In**: Secure authentication via Supabase OAuth (optional)
- **Email OTP/Verification**: Postmark-ready via Supabase Auth
- **Modern UI/UX**: Beautiful, intuitive interface designed for iOS

## 🛠️ Tech Stack

- **Frontend**: SwiftUI, iOS 18.1+
- **Backend**: Supabase (Auth, Postgres, optional Edge Functions)
- **Authentication**: Email/Password, OTP, Google via Supabase
- **Database**: Postgres (RLS-secured tables)
- **Real-time**: Supabase Realtime (chat, tasks, notifications)
- **Architecture**: MVVM with Environment Objects

## 📱 Screenshots

### 🚀 Launch Page
![Launch Page](screenshots/launch-page.png)
*Beautiful launch page with Arabic/English language support*

### 🔐 Authentication
![Authentication](screenshots/authentication.png)
*Secure login with Google Sign-In and OTP verification*

### 💡 Idea Discovery
![Idea Discovery](screenshots/idea-discovery.png)
*Explore and share innovative ideas with the community*

### 👥 Collaborative Pods
![Collaborative Pods](screenshots/collaborative-pods.png)
*Create and join teams to work on ideas together*

### 💬 Real-time Chat
![Real-time Chat](screenshots/chat.png)
*Built-in messaging system for seamless team communication*

### 📊 Analytics Dashboard
![Analytics](screenshots/analytics.png)
*Monitor project progress and team performance*

### 🌍 Multi-language Support
![Arabic Support](screenshots/arabic-support.png)
*Full Arabic localization with RTL support*

## 🚀 Getting Started

### Prerequisites
- Xcode 16.0+
- iOS 18.1+ deployment target
- Supabase project (URL + anon key)
- Optional: Google OAuth set up in Supabase

### Installation
1. Clone the repository
```bash
git clone https://github.com/alshehri12/Synapse.git
```

2. Open `Synapse.xcodeproj` in Xcode

3. Configure Supabase:
   - In `Synapse/Info.plist`, set `SupabaseURL` and `SupabaseAnonKey`
   - Optional: set `GIDClientID` for Google Sign-In
   - Open Supabase Dashboard → SQL Editor → run `supabase_schema.sql`
   - (Recommended) Run `seed_demo_data.sql` to populate demo content

4. Build and run the project

## 🏗️ Project Structure

```
Synapse/
├── App/
│   ├── ContentView.swift
│   └── SynapseApp.swift
├── Views/
│   ├── Authentication/
│   ├── Explore/
│   ├── Pods/
│   ├── Profile/
│   └── Shared/
├── Managers/
│   ├── SupabaseManager.swift
│   └── LocalizationManager.swift
├── Models/
│   ├── Models.swift
│   └── Extensions.swift
└── Resources/
    ├── Assets.xcassets/
    └── Localization/
```

## 🔧 Key Components

### Views
- **Authentication**: Secure login with Google Sign-In
- **Explore**: Discover and share innovative ideas
- **Pods**: Collaborative workspace with chat, tasks, and analytics
- **Profile**: User profile management and settings

### Managers
- **SupabaseManager**: Handles authentication, ideas, pods, tasks, chat
- **LocalizationManager**: Multi-language support

## 🌟 Highlights

- **Modern Architecture**: Built with latest SwiftUI and iOS features
- **Real-time Collaboration**: Live updates across all team members
- **Scalable Design**: Modular architecture for easy feature additions
- **Performance Optimized**: Efficient data loading and caching
- **Accessibility**: Full VoiceOver support and accessibility features

## 🤝 Contributing

This is a personal project showcasing iOS development skills. Feel free to explore the code and provide feedback!

## 📄 License

This project is for educational and portfolio purposes.

## 👨‍💻 Developer

**Abdulrahman Alshehri**
- GitHub: [@alshehri12](https://github.com/alshehri12)
- iOS Developer passionate about creating innovative mobile experiences

---

⭐ **Star this repository if you find it helpful!**
