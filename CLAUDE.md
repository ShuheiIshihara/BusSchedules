# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **BusNow**, an iOS bus schedule app specifically designed for Nagoya City Bus routes. The app uses GTFS-JP (General Transit Feed Specification - Japan) format data to provide accurate timetable information and real-time bus approach information for Nagoya City Bus users.

## Architecture

- **Pattern**: MVVM (Model-View-ViewModel) + Service Layer
- **UI Framework**: SwiftUI
- **Target Platform**: iOS (private distribution, not App Store)
- **Data Format**: GTFS-JP compliant
- **Target Service**: Nagoya City Bus only (unofficial app)

### Core Components

- **Models**: `StationPair` (GTFS-JP based station pairing)
- **Services**: 
  - `SupabaseService` (Supabase database integration with GTFS-JP data)
  - `SupabaseConfig` (secure configuration management)
- **ViewModels**: `StationSelectionViewModel`, `BusScheduleViewModel`
- **Views**: Station selection views, Schedule views, WebView component
- **Utils**: `StringNormalization` (Japanese text processing)

## Project Structure

```
20_Source/BusNow/
├── BusNow/                          # Main app source
│   ├── Models/                      # Data models (StationPair)
│   ├── ViewModels/                  # MVVM view models
│   ├── Views/                       # SwiftUI views
│   │   ├── StationSelectionView.swift
│   │   └── Schedule/
│   ├── Services/                    # Business logic layer
│   │   ├── SupabaseService.swift
│   │   └── SupabaseConfig.swift
│   ├── Utils/                       # Utility functions
│   │   └── StringNormalization.swift
│   ├── Assets.xcassets              # App assets
│   └── BusNowApp.swift             # App entry point
├── BusNowTests/                     # Unit tests
└── BusNowUITests/                   # UI tests
```

## Key Features

- **Station Selection Interface**: Select departure and arrival stations for Nagoya City Bus routes
- **GTFS-JP Integration**: Uses standard GTFS-JP format data for accurate timetable information
- **Real-time Clock**: Current time displayed with second precision (HH:MM:SS)
- **Schedule List**: Displays departure time, route name, destination, platform number
- **Automatic Day/Holiday Detection**: Selects appropriate timetable based on weekday/holiday
- **Proximity Info Integration**: In-app browser for bus approach information
- **Dynamic Visual Updates**: Grays out past departure times
- **Nagoya City Bus Focus**: Specialized for Nagoya City Bus routes only

## Development Commands

**Note**: Xcode project is located at `20_Source/BusNow/BusNow.xcodeproj`

- Build: `cd 20_Source/BusNow && xcodebuild -scheme BusNow -destination 'platform=iOS Simulator,name=iPhone 16'`
- Test: `cd 20_Source/BusNow && xcodebuild test -scheme BusNow -destination 'platform=iOS Simulator,name=iPhone 16'`
- Run single test: Use Xcode's test navigator or command line with specific test methods

## External Dependencies

- **Supabase Integration**: Supabase Swift SDK for GTFS-JP database access
  - **Authentication**: Anonymous access (no user registration required)
  - **Security**: Row Level Security (RLS) for public data access control
  - **API**: REST API for synchronous data retrieval
  - **Configuration**: Secure config management with `.xcconfig` files
- **Data Source**: Supabase PostgreSQL database with GTFS-JP format data
- **Persistence**: UserDefaults for app settings storage

## Data Models

- **StationPair**: Core model representing departure and arrival station pairing
- **GTFS-JP Models**: Standard GTFS-JP entities (stops, routes, trips, stop_times, calendar)
- **Bus Schedule Data**: Individual bus entry with departure time, route name, destination, platform from GTFS-JP data

## UI Specifications

- **Station Selection Screen**: Select departure and arrival stations from Nagoya City Bus stops
- **Schedule Screen**: Display bus timetable with real-time clock, schedule list, proximity info button
- **Direction Switching**: Toggle between outbound (行き) and inbound (帰り) schedules
- **WebView Component**: In-app browser for displaying bus proximity information

## Development Phases

1. **Project Setup**: Xcode project creation, Supabase SDK integration ✅
2. **Data Layer**: Supabase service with GTFS-JP integration ✅
3. **Station Selection**: UI for selecting Nagoya City Bus stops ✅
4. **Schedule Display**: Timetable view with real-time updates 🔄
5. **Integration**: Data-UI binding, database connectivity, testing 🔄

## Testing Strategy

- **Unit Tests**: Service layer logic, ViewModels, data models
- **UI Tests**: User interaction flows, screen navigation
- **Mock Objects**: Located in `BusNowTests/Mocks/`