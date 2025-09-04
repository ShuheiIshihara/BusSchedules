# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an iOS bus schedule app project that helps families track multiple bus routes with real-time information. The app aggregates timetables and proximity information for commonly used bus lines into a single application.

## Architecture

- **Pattern**: MVVM (Model-View-ViewModel) + Service Layer
- **UI Framework**: SwiftUI
- **Target Platform**: iOS (private distribution, not App Store)

### Core Components

- **Models**: `RouteSetting`, `BusSchedule`, `Holiday`
- **Services**: 
  - `SupabaseService` (Supabase database integration)
  - `HolidayService` (holiday data management from database)
  - `PersistenceService` (data storage)
- **ViewModels**: `ScheduleViewModel`, `SettingsViewModel`
- **Views**: Schedule views, Settings views, WebView component

## Project Structure

```
BusSchedules/
├── BusSchedules/                    # Main app source
│   ├── Application/                 # App entry point
│   ├── Models/                      # Data models
│   ├── ViewModels/                  # MVVM view models
│   ├── Views/                       # SwiftUI views
│   │   ├── Schedule/
│   │   ├── Settings/
│   │   └── Common/
│   └── Services/                    # Business logic layer
├── BusSchedulesTests/               # Unit tests
└── BusSchedulesUITests/             # UI tests
```

## Key Features

- **Dual Tab Interface**: "Outbound" (行き) and "Inbound" (帰り) schedule switching
- **Real-time Clock**: Current time displayed with second precision (HH:MM:SS)
- **Schedule List**: Displays departure time, route name, destination, platform number
- **Automatic Day/Holiday Detection**: Selects appropriate timetable based on weekday/holiday
- **Proximity Info Integration**: In-app browser for bus approach information
- **Dynamic Visual Updates**: Grays out past departure times
- **Multi-route Support**: Handles multiple bus routes per direction from Supabase database

## Development Commands

**Note**: This project is currently in the design phase. When the Xcode project is created:

- Build: `xcodebuild -scheme BusNow -destination 'platform=iOS Simulator,name=iPhone 16'`
- Test: `xcodebuild test -scheme BusNow -destination 'platform=iOS Simulator,name=iPhone 16'`
- Run single test: Use Xcode's test navigator or command line with specific test methods

## External Dependencies

- **Supabase Integration**: Supabase Swift SDK for database access
  - **Authentication**: Anonymous access (no user registration required)
  - **Security**: Row Level Security (RLS) for public data access control
  - **API**: REST API for synchronous data retrieval
- **Data Source**: Supabase PostgreSQL database
- **Persistence**: UserDefaults or SwiftData for settings storage

## Data Models

- **RouteSetting**: Configuration entity with id, name, GTFS route identifiers for both directions, proximity URLs
- **BusSchedule**: Individual bus entry with departure time, route name, destination, platform
- **Holiday**: Date and name from holiday API

## UI Specifications

- **Main Screen**: Setting title display, tab control for direction switching, real-time clock, bus schedule list, proximity info button
- **Settings Screen**: CRUD operations for route configurations with name, GTFS route identifiers, proximity URLs
- **WebView Component**: In-app browser for displaying bus proximity information

## Development Phases

1. **Project Setup**: Xcode project creation, Supabase SDK integration
2. **Data Layer**: Supabase service, holiday service, persistence
3. **Persistence**: Settings storage with UserDefaults/SwiftData
4. **UI Implementation**: Settings screens, schedule display, WebView
5. **Integration**: Data-UI binding, database connectivity, testing

## Testing Strategy

- **Unit Tests**: Service layer logic, ViewModels, data models
- **UI Tests**: User interaction flows, screen navigation
- **Mock Objects**: Located in `BusSchedulesTests/Mocks/`