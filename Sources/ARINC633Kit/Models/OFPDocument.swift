//
//  OFPDocument.swift
//  EFFReader
//
//  Created by Liyana on 30.6.2026.
//


// OFPModels.swift
import Foundation

public struct OFPDocument {
    public var header: M633Header
    public var flightInfo: OFPFlightInfo
    public var route: OFPRoute
    public var fuel: OFPFuel?
    public var weights: OFPWeights?
    public var weatherSummary: [OFPWeatherEntry] = []
    public var alternates: [OFPAlternate] = []
    public var crew: [OFPCrew] = []
    public var remarks: [String] = []
    public var rawXMLPreview: String?
    public var allNodes: [XMLNode] = []
}

// M633 message envelope — present at top of every ARINC 633 message
public struct M633Header {
    public var messageId: String?
    public var messageType: String?       // e.g. "OFP", "FlightPlan"
    public var version: String?            // ARINC 633 schema version
    public var sender: String?             // Airline / dispatch system
    public var recipient: String?
    public var creationTime: Date?
    public var flightId: String?
    public var priority: String?
}

public struct OFPFlightInfo {
    public var flightNumber: String?
    public var callsign: String?
    public var airline: String?
    public var aircraftRegistration: String?
    public var aircraftType: String?
    public var aircraftSubtype: String?
    public var departureICAO: String?
    public var departureName: String?
    public var arrivalICAO: String?
    public var arrivalName: String?
    public var std: Date?      // Scheduled Time of Departure
    public var sta: Date?      // Scheduled Time of Arrival
    public var etd: Date?      // Estimated Time of Departure
    public var eta: Date?      // Estimated Time of Arrival
    public var blockTime: String?
    public var flightTime: String?
    public var flightRules: String?    // IFR / VFR
    public var flightType: String?     // Scheduled / Charter
}

public struct OFPRoute {
    public var routeString: String?
    public var distanceNM: Double?
    public var initialCruiseLevel: String?
    public var costIndex: String?
    public var waypoints: [Waypoint] = []
}

public struct OFPFuel {
    public var taxi: String?
    public var tripFuel: String?
    public var contingency: String?
    public var alternate: String?
    public var finalReserve: String?
    public var additional: String?
    public var minimumTakeoff: String?
    public var blockFuel: String?
    public var totalFuel: String?
    public var unit: String?  // KG / LB
}

public struct OFPWeights {
    public var dryOperatingWeight: String?
    public var zeroFuelWeight: String?
    public var takeoffWeight: String?
    public var landingWeight: String?
    public var maxTakeoffWeight: String?
    public var maxLandingWeight: String?
    public var maxZeroFuelWeight: String?
    public var payload: String?
    public var unit: String?
}

public struct OFPAlternate: Identifiable {
    public let id = UUID()
    public let icao: String
    public let name: String?
    public let distanceNM: Double?
    public let fuelRequired: String?
    public let flightTime: String?
}

public struct OFPCrew: Identifiable {
    public let id = UUID()
    public let role: String?        // CPT / FO / Cabin
    public let name: String?
    public let employeeId: String?
}

public struct OFPWeatherEntry: Identifiable {
    public let id = UUID()
    public let icao: String
    public let metar: String?
    public let taf: String?
}
