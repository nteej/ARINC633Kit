//
//  AirportWeatherXMLParser.swift
//  EFFReader
//
//  Created by Liyana on 1.7.2026.
//


// AirportWeatherXMLParser.swift
import Foundation

final class AirportWeatherXMLParser: NSObject, XMLParserDelegate {
    private var results: [AirportWeather] = []
    private var currentICAO = ""
    private var currentMETAR: String?
    private var currentTAF: String?
    private var currentText = ""
    private var current = ""

    func parse(url: URL) -> [AirportWeather] {
        guard let parser = XMLParser(contentsOf: url) else { return [] }
        parser.delegate = self
        parser.parse()
        return results
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        current = elementName
        currentText = ""
        if elementName == "Airport" || elementName == "AirportWeather" {
            currentICAO = attributeDict["icao"] ?? attributeDict["ICAO"] ?? ""
            currentMETAR = nil; currentTAF = nil
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        let value = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        switch elementName {
        case "ICAO", "AirportCode": currentICAO = value
        case "METAR", "MetarText":  currentMETAR = value
        case "TAF",   "TafText":    currentTAF = value
        case "Airport", "AirportWeather":
            if !currentICAO.isEmpty {
                results.append(AirportWeather(icao: currentICAO,
                                              metar: currentMETAR,
                                              taf: currentTAF))
            }
        default: break
        }
        currentText = ""
    }
}