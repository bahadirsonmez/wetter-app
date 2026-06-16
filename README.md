# wetterApp

## Project Overview

wetterApp is a UIKit weather application built for the iOS Code Challenge. The app is implemented with programmatic UI, local Swift packages, and a separated Model / ViewModel / UI architecture.

The app shows weather for the current location and saved locations, including current conditions, forecast graph data, and weather detail tiles.

## Features

- Current location weather using Core Location.
- Saved locations list with persistence.
- Location search using MapKit.
- Current weather summary.
- Forecast graph based on OpenWeather forecast data.
- Weather detail tiles for minimum temperature, maximum temperature, pressure, wind, visibility, cloud coverage, sunrise, and sunset.
- Pull-to-refresh.
- iPhone and iPad support.
- Dynamic Type support.
- Programmatic UIKit UI with no storyboard dependency.

## Bonus Features

- Saved location management.
- Location search and add flow.
- Tile reordering.
- Adaptive iPad split view navigation.
- Page-based weather navigation between available locations.

## Technical Highlights

- Swift Concurrency with `async` / `await`.
- Protocol-oriented networking for testability.
- Local Swift packages:
  - `WeatherModel`
  - `WeatherViewModel`
- `UserDefaults` persistence for saved locations.
- Custom `UICollectionViewLayout` for the temperature graph.
- Manual frame calculation for weather tiles.
- Cache-aware weather service with refresh bypass support.
- Unit tests for domain models, ViewModels, services, layout geometry, and UI coordination.

## Architecture

The project is split into three main layers:

- `WeatherModel`: domain models, networking contracts, networking implementation, persistence contracts, and location search contracts.
- `WeatherViewModel`: presentation models, formatting, mapping, and imperative ViewModels.
- `wetterApp`: UIKit screens, app composition, navigation, infrastructure implementations, and platform integrations.

The UI layer depends on ViewModel protocols where practical. Domain and networking errors are mapped into presentation-level states before reaching view controllers.

## Project Structure

```text
wetterApp/
├── WeatherModel/
│   ├── Sources/WeatherModel/
│   └── Tests/WeatherModelTests/
├── WeatherViewModel/
│   ├── Sources/WeatherViewModel/
│   └── Tests/WeatherViewModelTests/
├── wetterApp/
│   ├── App/
│   │   ├── Configuration/
│   │   └── Navigation/
│   ├── Config/
│   ├── Infrastructure/
│   │   ├── Location/
│   │   ├── LocationSearch/
│   │   └── Persistence/
│   └── Screens/
│       ├── LocationSearch/
│       ├── Locations/
│       └── LocationWeather/
├── wetterAppTests/
├── docs/
└── wetterApp.xcodeproj
```

## Requirements

- Xcode with Swift 5.9 or newer.
- iOS 15.0 or newer.
- OpenWeather API key.

## OpenWeather API Setup

The API key must be provided through a local `Secrets.xcconfig` file. Do not commit the real file or the API key.

Create the local secrets file:

```sh
cp wetterApp/Config/Secrets.xcconfig.example \
   wetterApp/Config/Secrets.xcconfig
```

Then edit `wetterApp/Config/Secrets.xcconfig`:

```xcconfig
OPEN_WEATHER_API_KEY = your_open_weather_api_key
```

`Secrets.xcconfig` is ignored by Git. `wetterApp/Config/App.xcconfig` includes it optionally, so the project can still open without the local secrets file, but weather requests require a valid key.

## Running the Application

1. Open `wetterApp.xcodeproj` in Xcode.
2. Select the `wetterApp` scheme.
3. Create `wetterApp/Config/Secrets.xcconfig` as described above.
4. Add a valid `OPEN_WEATHER_API_KEY`.
5. Run the app on an iPhone or iPad simulator.

## Running Tests

Run package tests:

```sh
cd WeatherModel
swift test
```

```sh
cd WeatherViewModel
swift test
```

Run app tests from the repository root:

```sh
xcodebuild test \
  -project wetterApp.xcodeproj \
  -scheme wetterApp \
  -destination 'platform=iOS Simulator,name=iPhone 16e'
```

If the requested simulator is not installed, replace the destination with an available iOS simulator from your local Xcode setup.

## Design Decisions

- Storyboards were removed to keep the UI fully programmatic.
- Model and ViewModel code live in local Swift packages to keep the core architecture independent from UIKit.
- `WeatherFetching`, `LocationSearching`, and `LocationsStoring` are protocol-based so networking, search, and persistence can be tested without platform side effects.
- ViewModels expose imperative callbacks instead of Combine or other reactive frameworks to keep the challenge implementation small and explicit.
- Weather tiles use manual frame calculation because the challenge explicitly disallows Auto Layout and `UIStackView` for that section.
- The temperature graph uses a custom collection view layout so item positioning, sticky headers, and resize invalidation are controlled by app code.
- `UserDefaults` is used for saved locations because the stored data is small, user-specific, and simple enough to keep as a single Codable snapshot.
- OpenWeather API keys are read from build settings instead of source code.
