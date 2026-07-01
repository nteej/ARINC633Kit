//
//  OFPDocument.swift
//  EFFReader
//
//  Created by Liyana on 30.6.2026.
//


// OFPModels.swift
import Foundation

struct OFPDocument {
    var header: M633Header
    var flightInfo: OFPFlightInfo
    var route: OFPRoute
    var fuel: OFPFuel?
    var weights: OFPWeights?
    var weatherSummary: [OFPWeatherEntry] = []
    var alternates: [OFPAlternate] = []
    var crew: [OFPCrew] = []
    var remarks: [String] = []
    var rawXMLPreview: String?
    var allNodes: [XMLNode] = []
}

// M633 message envelope — present at top of every ARINC 633 message
struct M633Header {
    var messageId: String?
    var messageType: String?       // e.g. "OFP", "FlightPlan"
    var version: String?            // ARINC 633 schema version
    var sender: String?             // Airline / dispatch system
    var recipient: String?
    var creationTime: Date?
    var flightId: String?
    var priority: String?
}

struct OFPFlightInfo {
    var flightNumber: String?
    var callsign: String?
    var airline: String?
    var aircraftRegistration: String?
    var aircraftType: String?
    var aircraftSubtype: String?
    var departureICAO: String?
    var departureName: String?
    var arrivalICAO: String?
    var arrivalName: String?
    var std: Date?      // Scheduled Time of Departure
    var sta: Date?      // Scheduled Time of Arrival
    var etd: Date?      // Estimated Time of Departure
    var eta: Date?      // Estimated Time of Arrival
    var blockTime: String?
    var flightTime: String?
    var flightRules: String?    // IFR / VFR
    var flightType: String?     // Scheduled / Charter
}

struct OFPRoute {
    var routeString: String?
    var distanceNM: Double?
    var initialCruiseLevel: String?
    var costIndex: String?
    var waypoints: [Waypoint] = []
}

struct OFPFuel {
    var taxi: String?
    var trip: String?
    var contingency: String?
    var alternate: String?
    var finalReserve: String?
    var additional: String?
    var minimumTakeoff: String?
    var blockFuel: String?
    var totalFuel: String?
    var unit: String?  // KG / LB
}

struct OFPWeights {
    var dryOperatingWeight: String?
    var zeroFuelWeight: String?
    var takeoffWeight: String?
    var landingWeight: String?
    var maxTakeoffWeight: String?
    var maxLandingWeight: String?
    var maxZeroFuelWeight: String?
    var payload: String?
    var unit: String?
}

struct OFPAlternate: Identifiable {
    let id = UUID()
    let icao: String
    let name: String?
    let distanceNM: Double?
    let fuelRequired: String?
    let flightTime: String?
}

struct OFPCrew: Identifiable {
    let id = UUID()
    let role: String?        // CPT / FO / Cabin
    let name: String?
    let employeeId: String?
}

struct OFPWeatherEntry: Identifiable {
    let id = UUID()
    let icao: String
    let metar: String?
    let taf: String?
}
