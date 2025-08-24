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
  - `ScraperService` (web scraping for timetables)
  - `HolidayService` (holiday API integration)
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

- **Timetable Display**: Shows bus schedules with real-time updates
- **Settings Management**: CRUD operations for route configurations
- **Holiday Detection**: Uses holidays-jp.github.io API
- **Web Scraping**: Extracts timetable data from bus company websites
- **In-App Browser**: Displays proximity information
- **Dynamic Updates**: Grays out passed departure times

## Development Commands

**Note**: This project is currently in the design phase. When the Xcode project is created:

- Build: `xcodebuild -scheme BusSchedules -destination 'platform=iOS Simulator,name=iPhone 15'`
- Test: `xcodebuild test -scheme BusSchedules -destination 'platform=iOS Simulator,name=iPhone 15'`
- Run single test: Use Xcode's test navigator or command line with specific test methods

## External Dependencies

- **HTML Parsing**: SwiftSoup (to be added)
- **Holiday API**: https://holidays-jp.github.io/api/v1/date.json
- **Data Source**: Nagoya City Transportation Bureau website

## Development Phases

1. **Project Setup**: Xcode project creation, dependency setup
2. **Data Layer**: Scraping service, holiday service, persistence
3. **Persistence**: Settings storage with UserDefaults/SwiftData
4. **UI Implementation**: Settings screens, schedule display, WebView
5. **Integration**: Data-UI binding, real-time updates, testing

## Testing Strategy

- **Unit Tests**: Service layer logic, ViewModels, data models
- **UI Tests**: User interaction flows, screen navigation
- **Mock Objects**: Located in `BusSchedulesTests/Mocks/`