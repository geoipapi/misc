import Foundation
import UIKit

struct GeoIpResponse: Codable {
    let ip: String
    let type: String
    let country: Country
    let location: Location
    let asn: ASN

    struct Country: Codable {
        let isEuMember: Bool
        let currencyCode: String
        let continent: String
        let name: String
        let countryCode: String
        let state: String
        let city: String
        let zip: String
        let timezone: String

        enum CodingKeys: String, CodingKey {
            case isEuMember = "is_eu_member"
            case currencyCode = "currency_code"
            case continent, name
            case countryCode = "country_code"
            case state, city, zip, timezone
        }
    }

    struct Location: Codable {
        let latitude: Double
        let longitude: Double
    }

    struct ASN: Codable {
        let number: Int
        let name: String
        let network: String
        let type: String
    }
}

class GeoIpFetcher {
    static func fetch(completion: @escaping (Result<GeoIpResponse, Error>) -> Void) {
        guard let url = URL(string: "https://api.geoipapi.com/json") else {
            completion(.failure(NSError(domain: "invalid_url", code: 0)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let device = UIDevice.current
        let systemVersion = ProcessInfo.processInfo.operatingSystemVersion
        let deviceID = device.identifierForVendor?.uuidString ?? "unknown"
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "UnknownApp"

        request.addValue(appName, forHTTPHeaderField: "X-App-Name")
        request.addValue(deviceID, forHTTPHeaderField: "X-Device-ID")
        request.addValue(device.model, forHTTPHeaderField: "X-Device-Model")
        request.addValue(device.systemName, forHTTPHeaderField: "X-Device-Manufacturer")
        request.addValue(device.name, forHTTPHeaderField: "X-Device-Brand")
        request.addValue(device.systemVersion, forHTTPHeaderField: "X-Device-OS-Version")
        request.addValue("\(systemVersion.majorVersion).\(systemVersion.minorVersion).\(systemVersion.patchVersion)", forHTTPHeaderField: "X-Device-SDK")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let err = error {
                completion(.failure(err))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "no_data", code: 0)))
                return
            }

            do {
                let result = try JSONDecoder().decode(GeoIpResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
