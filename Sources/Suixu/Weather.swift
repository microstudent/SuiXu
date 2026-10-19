import Foundation
import Observation

struct WeatherCity: Identifiable, Sendable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    static let all: [WeatherCity] = [
        .init(id: "shenzhen", name: "深圳", latitude: 22.54, longitude: 114.06),
        .init(id: "beijing", name: "北京", latitude: 39.90, longitude: 116.41),
        .init(id: "shanghai", name: "上海", latitude: 31.23, longitude: 121.47),
        .init(id: "guangzhou", name: "广州", latitude: 23.13, longitude: 113.26),
        .init(id: "hangzhou", name: "杭州", latitude: 30.27, longitude: 120.15),
        .init(id: "chengdu", name: "成都", latitude: 30.57, longitude: 104.07),
        .init(id: "chongqing", name: "重庆", latitude: 29.56, longitude: 106.55),
        .init(id: "wuhan", name: "武汉", latitude: 30.59, longitude: 114.31),
        .init(id: "nanjing", name: "南京", latitude: 32.06, longitude: 118.80),
        .init(id: "xian", name: "西安", latitude: 34.34, longitude: 108.94),
        .init(id: "suzhou", name: "苏州", latitude: 31.30, longitude: 120.59),
        .init(id: "hongkong", name: "香港", latitude: 22.32, longitude: 114.17)
    ]
}

struct WeatherReading: Sendable {
    let city: WeatherCity
    let temperature: Double
    let code: Int
    let isDay: Bool
    let receivedAt: Date
    var description: String {
        switch code {
        case 0: "晴"
        case 1, 2: "多云"
        case 3: "阴"
        case 45, 48: "雾"
        case 51...57: "毛毛雨"
        case 61...67: "雨"
        case 71...77: "雪"
        case 80...82: "阵雨"
        case 85, 86: "阵雪"
        case 95...99: "雷雨"
        default: "天气"
        }
    }
    var symbol: String {
        switch code {
        case 0: isDay ? "sun.max" : "moon.stars"
        case 1, 2: isDay ? "cloud.sun" : "cloud.moon"
        case 3: "cloud"
        case 45, 48: "cloud.fog"
        case 71...77, 85, 86: "cloud.snow"
        case 95...99: "cloud.bolt.rain"
        default: "cloud.rain"
        }
    }
}

private struct WeatherResponse: Decodable {
    struct Current: Decodable {
        let temperature_2m: Double
        let weather_code: Int
        let is_day: Int
    }
    let current: Current
}

@MainActor @Observable
final class WeatherModel {
    var reading: WeatherReading?
    var isLoading = false
    var error: String?
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var requestID = UUID()

    func update(enabled: Bool, cityID: String, force: Bool = false) {
        task?.cancel()
        requestID = UUID()
        let token = requestID
        guard enabled, let city = WeatherCity.all.first(where: { $0.id == cityID }) else {
            reading = nil; error = nil; isLoading = false
            return
        }
        if !force, let reading, reading.city.id == cityID, Date().timeIntervalSince(reading.receivedAt) < 1800 {
            isLoading = false
            return
        }
        if reading?.city.id != cityID { reading = nil }
        isLoading = true
        error = nil
        task = Task {
            defer { if requestID == token { isLoading = false } }
            do {
                var parts = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
                parts.queryItems = [
                    .init(name: "latitude", value: String(city.latitude)),
                    .init(name: "longitude", value: String(city.longitude)),
                    .init(name: "current", value: "temperature_2m,weather_code,is_day"),
                    .init(name: "timezone", value: "Asia/Shanghai")
                ]
                let request = URLRequest(url: parts.url!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw URLError(.badServerResponse) }
                let current = try JSONDecoder().decode(WeatherResponse.self, from: data).current
                try Task.checkCancellation()
                guard requestID == token else { return }
                reading = WeatherReading(city: city, temperature: current.temperature_2m, code: current.weather_code, isDay: current.is_day == 1, receivedAt: Date())
            } catch {
                guard requestID == token, !Task.isCancelled else { return }
                self.error = "天气暂不可用"
            }
        }
    }
}
