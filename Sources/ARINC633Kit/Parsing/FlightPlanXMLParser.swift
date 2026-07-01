//
//  FlightPlanXMLParser.swift
//  EFFReader
//
//  Created by Liyana on 30.6.2026.
//


// FlightPlanXMLParser.swift
import Foundation

final class FlightPlanXMLParser: NSObject, XMLParserDelegate {
    private var plan = FlightPlan()
    private var currentElement = ""
    private var currentText = ""
    private var currentWaypoint: Waypoint?
    private var wpName = ""
    private var wpLat: Double?
    private var wpLon: Double?
    private var wpAlt: String?
    private var wpETA: String?
    private var inWaypoint = false

    func parse(url: URL) -> FlightPlan? {
        guard let parser = XMLParser(contentsOf: url) else { return nil }
        parser.delegate = self
        parser.parse()
        return plan
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        currentText = ""
        if ["Waypoint", "RouteSegment", "FixPoint"].contains(elementName) {
            inWaypoint = true
            wpName = ""; wpLat = nil; wpLon = nil; wpAlt = nil; wpETA = nil
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        let value = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {
        case "FlightNumber":           plan.flightNumber = value
        case "AircraftRegistration":   plan.aircraftRegistration = value
        case "AircraftType":           plan.aircraftType = value
        case "DepartureAirport", "Origin", "DepartureICAO":
            plan.departureICAO = value
        case "ArrivalAirport", "Destination", "ArrivalICAO":
            plan.arrivalICAO = value
        case "AlternateAirport", "Alternate":
            plan.alternateICAO = value
        case "Route", "RouteString":
            plan.route = value
        case "ScheduledTimeOfDeparture", "STD":
            plan.scheduledDeparture = ISO8601DateFormatter().date(from: value)
        case "ScheduledTimeOfArrival", "STA":
            plan.scheduledArrival = ISO8601DateFormatter().date(from: value)
        case "CrewMember", "Pilot":
            plan.crew.append(value)

        // Waypoint sub-elements
        case "Name", "Identifier", "Fix": if inWaypoint { wpName = value }
        case "Latitude":  if inWaypoint { wpLat = Double(value) }
        case "Longitude": if inWaypoint { wpLon = Double(value) }
        case "Altitude", "FL": if inWaypoint { wpAlt = value }
        case "ETA", "EstimatedTimeOfArrival": if inWaypoint { wpETA = value }

        case "Waypoint", "RouteSegment", "FixPoint":
            if !wpName.isEmpty {
                plan.waypoints.append(
                    Waypoint(name: wpName, latitude: wpLat,
                             longitude: wpLon, altitude: wpAlt, eta: wpETA)
                )
            }
            inWaypoint = false

        default: break
        }
        currentText = ""
    }
}