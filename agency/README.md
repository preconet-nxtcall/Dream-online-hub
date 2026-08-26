# Agency & User Dual Application (Shared Flutter Codebase)

A production-ready Flutter architecture supporting two distinct applications (**Agency App** and **User App**) within a unified, modular, shared codebase.

## 🚀 How to Run

### Run Agency App
```bash
flutter run -t lib/main_agency.dart
```

### Run User App
```bash
flutter run -t lib/main_user.dart
```

---

## 📁 Architecture & Folder Structure

```
lib/
├── main_agency.dart           # Entry point for Agency App
├── main_user.dart             # Entry point for User App
├── app/                       # Application Root configurations (AgencyApp / UserApp)
├── core/                      # Core constants, exceptions, base usecases, DI
│   ├── constants/             # App constants, API endpoints, storage keys
│   ├── di/                    # Dependency injection setup
│   ├── errors/                # Exception and failure handling
│   └── usecases/              # Base UseCase contracts
├── features/                  # Feature Modules (Clean Architecture)
│   ├── agency_dashboard/
│   ├── auth/
│   └── user_dashboard/
├── models/                    # Data models (Common, Agency, User)
├── network/                   # REST API client (Dio), Interceptors, Response handling
├── providers/                 # State management (AuthProvider, ThemeProvider, etc.)
├── repositories/              # Repository interfaces & concrete implementations
├── routes/                    # Routing management (GoRouter - Agency & User router specs)
├── services/                  # Global services (Notification, Location, Analytics)
├── socket/                    # Real-time WebSocket connection manager & event definitions
├── storage/                   # Local storage (Shared Preferences, Secure Storage, Cache)
├── theme/                     # App styling, Color palette, Typography, Themes
├── utils/                     # Formatting, Validators, Extensions, Logger
└── widgets/                   # Common reusable UI components (Agency, User, Shared)
```

---

## 🛠 Features Overview

- **Single Shared Codebase**: Share utilities, models, networking, storage, socket events, services, and repositories between Agency & User apps while keeping app-level routes and screens isolated.
- **Flavored Entry Points**: Separate `main_agency.dart` and `main_user.dart` files for independent execution and app builds.
- **REST & Real-time Connectivity**: Integrated `ApiClient` with Dio interceptors and real-time `SocketClient` listener setup.
- **Secure Persistence**: Shared preferences and secure token storage configured out of the box.
