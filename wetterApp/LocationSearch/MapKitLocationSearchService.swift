import MapKit
import WeatherModel

final class MapKitLocationSearchService: LocationSearching, @unchecked Sendable {

    func search(query: String) async throws -> [LocationSearchResult] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        do {
            let response = try await MKLocalSearch(request: request).start()
            return response.mapItems.compactMap { item in
                let placemark = item.placemark
                guard
                    let name = placemark.locality ?? item.name,
                    !name.isEmpty
                else {
                    return nil
                }

                return LocationSearchResult(
                    name: name,
                    state: placemark.administrativeArea,
                    countryCode: placemark.isoCountryCode,
                    latitude: placemark.coordinate.latitude,
                    longitude: placemark.coordinate.longitude
                )
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw LocationSearchError.unavailable
        }
    }
}
