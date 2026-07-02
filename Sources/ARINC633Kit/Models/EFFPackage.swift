// EFFModels.swift
import Foundation

public struct EFFPackage: Identifiable {
    public let id = UUID()
    public let fileName: String
    public var extractionRoot: URL?
    public var manifest: EFFManifest?
    public var ofp: OFPDocument?
    public var ofpDocument: EFFDocument?
    public var flightPlan: FlightPlan?
    public var airportWeathers: [AirportWeather] = []
    public var notams: [Notam] = []
    public var documents: [EFFDocument] = []        // everything from /dat
    public var rawFiles: [String: URL] = [:]

    /// Removes the temporary extraction directory from disk.
    public func cleanup() {
        guard let root = extractionRoot else { return }
        try? FileManager.default.removeItem(at: root)
    }
}

// Manifest entry from /lst
public struct EFFManifest {
    public var packageId: String?
    public var airline: String?
    public var flightNumber: String?
    public var creationDate: Date?
    public var entries: [EFFManifestEntry] = []
}

public struct EFFManifestEntry: Identifiable {
    public let id = UUID()
    public let documentId: String?
    public let fileName: String        // path inside /dat
    public let category: String?       // e.g. "FlightPlan", "Weather", "NOTAM", "Chart"
    public let mimeType: String?
    public let size: Int?
    public let checksum: String?
    public let description: String?
}

public struct FlightPlan {
    public var flightNumber: String?
    public var aircraftRegistration: String?
    public var aircraftType: String?
    public var departureICAO: String?
    public var arrivalICAO: String?
    public var alternateICAO: String?
    public var scheduledDeparture: Date?
    public var scheduledArrival: Date?
    public var route: String?
    public var crew: [String] = []
    public var waypoints: [Waypoint] = []
}

public struct Waypoint: Identifiable {
    public let id = UUID()
    public let name: String
    public let latitude: Double?
    public let longitude: Double?
    public let altitude: String?
    public let eta: String?
}

public struct AirportWeather: Identifiable {
    public let id = UUID()
    public let icao: String
    public var metar: String?
    public var taf: String?
}

public struct Notam: Identifiable {
    public let id = UUID()
    public let icao: String
    public let text: String
}
