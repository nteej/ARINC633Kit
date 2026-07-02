//
//  OFPSmartExtractor.swift
//  EFFReader
//
//  Created by Liyana on 1.7.2026.
//


// ARINC633Kit/Parsing/OFPSmartExtractor.swift
import Foundation

public enum OFPSmartExtractor {

    public static func extract(from url: URL) -> OFPDocument? {
        let nodes = XMLFlattener().flatten(url: url)
        guard !nodes.isEmpty else { return nil }
        let idx = KeywordIndex(nodes: nodes)

        var doc = OFPDocument(
            header: extractHeader(idx),
            flightInfo: extractFlightInfo(idx),
            route: extractRoute(idx)
        )
        doc.fuel = extractFuel(idx)
        doc.weights = extractWeights(idx)
        doc.alternates = extractAlternates(idx)
        doc.crew = extractCrew(idx)
        doc.weatherSummary = extractWeather(idx)
        doc.remarks = extractRemarks(idx)
        doc.allNodes = nodes

        if let raw = try? String(contentsOf: url, encoding: .utf8) {
            doc.rawXMLPreview = String(raw.prefix(8000))
        }
        return doc
    }

    // MARK: - Section extractors (now small + focused)

    private static func extractHeader(_ idx: KeywordIndex) -> M633Header {
        var h = M633Header()
        h.messageId   = idx.find(["messageid", "msgid", "messageidentifier"])
        h.messageType = idx.find(["messagetype", "msgtype", "documenttype"])
        h.version     = idx.find(["schemaversion", "version", "arincversion"])
        h.sender      = idx.find(["sender", "from", "originator", "source"])
        h.recipient   = idx.find(["recipient", "to", "destination", "addressee"])
        h.flightId    = idx.find(["flightid", "flightidentifier"])
        h.priority    = idx.find(["priority"])
        if let t = idx.find(["creationtime", "creationdate", "timestamp",
                              "datetime", "generatedat", "created"]) {
            h.creationTime = DateParsing.parse(t)
        }
        return h
    }

    private static func extractFlightInfo(_ idx: KeywordIndex) -> OFPFlightInfo {
        var f = OFPFlightInfo()
        f.flightNumber = idx.find(["flightnumber", "fltnum", "flight"],
                                  excluding: ["flightid"])
        f.callsign     = idx.find(["callsign", "atccallsign"])
        f.airline      = idx.find(["airline", "operator", "carrier", "icaooperator"])
        f.aircraftRegistration = idx.find(
            ["aircraftregistration", "registration", "tailnumber", "tail", "regnum"])
        f.aircraftType    = idx.find(["aircrafttype", "actype", "type"],
                                     pathContains: "aircraft")
        f.aircraftSubtype = idx.find(["subtype", "variant", "series"],
                                     pathContains: "aircraft")

        f.departureICAO = idx.findInContext(
            value: ["icao", "airportcode", "code", "ident"],
            contextAny: ["departure", "origin", "from", "adep"])
            ?? idx.find(["departureicao", "departureairport", "origin", "adep"])
        f.departureName = idx.findInContext(
            value: ["name", "airportname"],
            contextAny: ["departure", "origin"])

        f.arrivalICAO = idx.findInContext(
            value: ["icao", "airportcode", "code", "ident"],
            contextAny: ["arrival", "destination", "to", "ades"])
            ?? idx.find(["arrivalicao", "arrivalairport", "destination", "ades"])
        f.arrivalName = idx.findInContext(
            value: ["name", "airportname"],
            contextAny: ["arrival", "destination"])

        f.std = DateParsing.parse(idx.find(["std", "scheduledtimeofdeparture",
                                             "scheduleddeparture"]))
        f.sta = DateParsing.parse(idx.find(["sta", "scheduledtimeofarrival",
                                             "scheduledarrival"]))
        f.etd = DateParsing.parse(idx.find(["etd", "estimatedtimeofdeparture",
                                             "offblocktime"]))
        f.eta = DateParsing.parse(idx.find(["eta", "estimatedtimeofarrival",
                                             "onblocktime"]))
        f.blockTime    = idx.find(["blocktime", "tblock"])
        f.flightTime   = idx.find(["flighttime", "flttime", "tflight"])
        f.flightRules  = idx.find(["flightrules", "rules"])
        f.flightType   = idx.find(["flighttype", "typeofflight"])
        return f
    }

    private static func extractRoute(_ idx: KeywordIndex) -> OFPRoute {
        var r = OFPRoute()
        r.routeString = idx.find(["route", "routestring", "atcroute"])
        r.initialCruiseLevel = idx.find(["initialcruiselevel", "cruiselevel",
                                          "requestedflightlevel", "rfl",
                                          "flightlevel", "fl"])
        r.costIndex = idx.find(["costindex", "ci"])
        if let d = idx.find(["totaldistance", "grounddistance", "distance",
                              "trackmiles", "airdistance"]) {
            r.distanceNM = Double(d.filter { "0123456789.".contains($0) })
        }
        r.waypoints = extractWaypoints(idx)
        return r
    }

    private static func extractWaypoints(_ idx: KeywordIndex) -> [Waypoint] {
        let groups = idx.groups { parent in
            let p = parent.lowercased()
            return ["waypoint", "routesegment", "fixpoint",
                    "routepoint", "navpoint"]
                .contains(where: p.contains)
        }
        return groups.compactMap { group in
            guard let name = group.first(where: {
                ["name", "identifier", "fix", "ident", "waypointname"]
                    .contains($0.element.lowercased())
            })?.value, !name.isEmpty else { return nil }
            return Waypoint(
                name: name,
                latitude: group.first(where: { $0.element.lowercased() == "latitude" })
                    .flatMap { Double($0.value) },
                longitude: group.first(where: { $0.element.lowercased() == "longitude" })
                    .flatMap { Double($0.value) },
                altitude: group.first(where: {
                    ["altitude", "fl", "flightlevel"].contains($0.element.lowercased())
                })?.value,
                eta: group.first(where: {
                    ["eta", "estimatedtimeofarrival", "time"]
                        .contains($0.element.lowercased())
                })?.value
            )
        }
    }

    private static func extractFuel(_ idx: KeywordIndex) -> OFPFuel? {
        let fuelNodes = idx.nodes(pathContaining: "fuel")
        guard !fuelNodes.isEmpty else { return nil }
        let f = KeywordIndex(nodes: fuelNodes)
        var fuel = OFPFuel()
        fuel.taxi          = f.find(["taxi", "taxifuel"])
        fuel.tripFuel      = f.find(["trip", "tripfuel"])
        fuel.contingency   = f.find(["contingency", "contingencyfuel"])
        fuel.alternate     = f.find(["alternate", "alternatefuel"])
        fuel.finalReserve  = f.find(["finalreserve", "finalreservefuel", "reserve"])
        fuel.additional    = f.find(["additional", "additionalfuel", "extra"])
        fuel.minimumTakeoff = f.find(["minimumtakeoff", "mintakeoff"])
        fuel.blockFuel     = f.find(["block", "blockfuel"])
        fuel.totalFuel     = f.find(["total", "totalfuel"])
        fuel.unit          = f.find(["unit", "fuelunit", "uom"])
        return fuel
    }

    private static func extractWeights(_ idx: KeywordIndex) -> OFPWeights? {
        var w = OFPWeights()
        w.dryOperatingWeight = idx.find(["dryoperatingweight", "dow"])
        w.zeroFuelWeight     = idx.find(["zerofuelweight", "zfw"])
        w.takeoffWeight      = idx.find(["takeoffweight", "tow"])
        w.landingWeight      = idx.find(["landingweight", "ldw", "law"])
        w.maxTakeoffWeight   = idx.find(["maxtakeoffweight", "mtow"])
        w.maxLandingWeight   = idx.find(["maxlandingweight", "mlw"])
        w.maxZeroFuelWeight  = idx.find(["maxzerofuelweight", "mzfw"])
        w.payload            = idx.find(["payload", "totalpayload"])
        w.unit               = idx.find(["weightunit"])
        let has = [w.dryOperatingWeight, w.zeroFuelWeight, w.takeoffWeight,
                   w.landingWeight, w.payload]
            .contains { $0?.isEmpty == false }
        return has ? w : nil
    }

    private static func extractAlternates(_ idx: KeywordIndex) -> [OFPAlternate] {
        let groups = idx.groups { parent in
            let p = parent.lowercased()
            return p.contains("alternate") && !p.contains("alternatefuel")
        }
        return groups.compactMap { group in
            let icao = group.first(where: {
                ["icao", "airportcode", "code", "ident"].contains($0.element.lowercased())
            })?.value ?? ""
            guard !icao.isEmpty else { return nil }
            return OFPAlternate(
                icao: icao,
                name: group.first(where: {
                    ["name", "airportname"].contains($0.element.lowercased())
                })?.value,
                distanceNM: group.first(where: { $0.element.lowercased() == "distance" })
                    .flatMap { Double($0.value) },
                fuelRequired: group.first(where: {
                    ["fuelrequired", "fuel"].contains($0.element.lowercased())
                })?.value,
                flightTime: group.first(where: {
                    ["flighttime", "time"].contains($0.element.lowercased())
                })?.value
            )
        }
    }

    private static func extractCrew(_ idx: KeywordIndex) -> [OFPCrew] {
        let groups = idx.groups { parent in
            let p = parent.lowercased()
            return p.contains("crewmember") || p.hasSuffix("/crew")
                || p.contains("/pilot")
        }
        return groups.compactMap { group in
            let name = group.first(where: {
                ["name", "fullname", "crewname"].contains($0.element.lowercased())
            })?.value
            let role = group.first(where: {
                ["role", "position", "function"].contains($0.element.lowercased())
            })?.value
            guard name != nil || role != nil else { return nil }
            return OFPCrew(
                role: role,
                name: name,
                employeeId: group.first(where: {
                    ["employeeid", "id", "staffid"].contains($0.element.lowercased())
                })?.value
            )
        }
    }

    private static func extractWeather(_ idx: KeywordIndex) -> [OFPWeatherEntry] {
        let groups = idx.groups { parent in
            let p = parent.lowercased()
            return p.contains("airportweather") || p.contains("weatherinfo")
                || p.contains("metartaf")
        }
        return groups.compactMap { group in
            let icao = group.first(where: {
                ["icao", "airportcode"].contains($0.element.lowercased())
            })?.value ?? ""
            guard !icao.isEmpty else { return nil }
            return OFPWeatherEntry(
                icao: icao,
                metar: group.first(where: {
                    ["metar", "metartext"].contains($0.element.lowercased())
                })?.value,
                taf: group.first(where: {
                    ["taf", "taftext"].contains($0.element.lowercased())
                })?.value
            )
        }
    }

    private static func extractRemarks(_ idx: KeywordIndex) -> [String] {
        idx.nodes.filter {
            ["remarks", "remark", "notes", "comment"]
                .contains($0.element.lowercased())
        }.map(\.value)
    }
}