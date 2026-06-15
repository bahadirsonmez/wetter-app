import WeatherModel

enum WeatherLocationSource: Equatable {

    case current
    case saved(SavedLocation)
}
