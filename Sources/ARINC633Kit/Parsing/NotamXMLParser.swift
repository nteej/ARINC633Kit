//
//  NotamXMLParser.swift
//  EFFReader
//
//  Created by Liyana on 30.6.2026.
//


// NotamXMLParser.swift
import Foundation

final class NotamXMLParser: NSObject, XMLParserDelegate {
    private var results: [Notam] = []
    private var icao = ""
    private var text = ""
    private var current = ""
    private var buffer = ""

    func parse(url: URL) -> [Notam] {
        guard let parser = XMLParser(contentsOf: url) else { return [] }
        parser.delegate = self
        parser.parse()
        return results
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        current = elementName
        buffer = ""
        if elementName == "Notam" { icao = ""; text = "" }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        buffer += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        let v = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
        switch elementName {
        case "ICAO", "AirportCode": icao = v
        case "NotamText", "Text", "RawText": text = v
        case "Notam":
            if !text.isEmpty {
                results.append(Notam(icao: icao, text: text))
            }
        default: break
        }
        buffer = ""
    }
}