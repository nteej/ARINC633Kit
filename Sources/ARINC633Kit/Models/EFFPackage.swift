// EFFModels.swift
import Foundation

struct EFFPackage: Identifiable {
    let id = UUID()
    let fileName: String
    var extractionRoot: URL?  
    var manifest: EFFManifest?
    var ofp: OFPDocument?
    var ofpDocument: EFFDocument?
    var flightPlan: FlightPlan?
    var airportWeathers: [AirportWeather] = []
    var notams: [Notam] = []
    var documents: [EFFDocument] = []        // everything from /dat
    var rawFiles: [String: URL] = [:]
}

// Manifest entry from /lst
struct EFFManifest {
    var packageId: String?
    var airline: String?
    var flightNumber: String?
    var creationDate: Date?
    var entries: [EFFManifestEntry] = []
}

struct EFFManifestEntry: Identifiable {
    let id = UUID()
    let documentId: String?
    let fileName: String        // path inside /dat
    let category: String?       // e.g. "FlightPlan", "Weather", "NOTAM", "Chart"
    let mimeType: String?
    let size: Int?
    let checksum: String?
    let description: String?
}

// A document extracted from /dat
struct EFFDocument: Identifiable {
    let id = UUID()
    let name: String
    let path: String            // relative path inside the eff
    let url: URL                // unpacked location on disk
    let category: String        // FlightPlan / Weather / NOTAM / Chart / PDF / Image / XML / Other
    let mimeType: String?
    let sizeBytes: Int64
    let description: String?
}

struct FlightPlan {
    var flightNumber: String?
    var aircraftRegistration: String?
    var aircraftType: String?
    var departureICAO: String?
    var arrivalICAO: String?
    var alternateICAO: String?
    var scheduledDeparture: Date?
    var scheduledArrival: Date?
    var route: String?
    var crew: [String] = []
    var waypoints: [Waypoint] = []
}

struct Waypoint: Identifiable {
    let id = UUID()
    let name: String
    let latitude: Double?
    let longitude: Double?
    let altitude: String?
    let eta: String?
}

struct AirportWeather: Identifiable {
    let id = UUID()
    let icao: String
    var metar: String?
    var taf: String?
}

struct Notam: Identifiable {
    let id = UUID()
    let icao: String
    let text: String
}
