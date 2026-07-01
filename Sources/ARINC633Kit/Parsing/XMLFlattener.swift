//
//  XMLNode.swift
//  EFFReader
//
//  Created by Liyana on 30.6.2026.
//


// XMLFlattener.swift
import Foundation

/// Represents one leaf value in the XML with its full path and attributes.
struct XMLNode: Identifiable {
    let id = UUID()
    let path: String          // e.g. "OFP/Flight/Departure/ICAO"
    let element: String       // last component, e.g. "ICAO"
    let value: String
    let attributes: [String: String]
}

/// Flattens any XML into a list of leaf nodes with full paths.
/// Schema-agnostic — works with any ARINC 633 dialect.
final class XMLFlattener: NSObject, XMLParserDelegate {

    private(set) var nodes: [XMLNode] = []
    private var pathStack: [String] = []
    private var attrStack: [[String: String]] = []
    private var textBuffer = ""
    private var hadChildren: [Bool] = []   // tracks if current element has child elements

    func flatten(url: URL) -> [XMLNode] {
        nodes = []
        pathStack = []
        attrStack = []
        guard let parser = XMLParser(contentsOf: url) else { return [] }
        parser.shouldProcessNamespaces = false
        parser.delegate = self
        parser.parse()
        return nodes
    }

    func flatten(data: Data) -> [XMLNode] {
        nodes = []
        pathStack = []
        attrStack = []
        let parser = XMLParser(data: data)
        parser.shouldProcessNamespaces = false
        parser.delegate = self
        parser.parse()
        return nodes
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        // Strip namespace prefix if any
        let local = elementName.split(separator: ":").last.map(String.init) ?? elementName
        pathStack.append(local)
        attrStack.append(attributeDict)
        if !hadChildren.isEmpty { hadChildren[hadChildren.count - 1] = true }
        hadChildren.append(false)
        textBuffer = ""

        // Emit attributes as nodes too (so e.g. <Flight number="LH441"/> is captured)
        for (k, v) in attributeDict {
            let attrPath = (pathStack + ["@\(k)"]).joined(separator: "/")
            nodes.append(XMLNode(path: attrPath,
                                 element: "@\(k)",
                                 value: v,
                                 attributes: [:]))
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        textBuffer += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        let trimmed = textBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasKids = hadChildren.removeLast()
        if !trimmed.isEmpty && !hasKids {
            let local = pathStack.last ?? elementName
            let path = pathStack.joined(separator: "/")
            let attrs = attrStack.last ?? [:]
            nodes.append(XMLNode(path: path,
                                 element: local,
                                 value: trimmed,
                                 attributes: attrs))
        }
        if !pathStack.isEmpty { pathStack.removeLast() }
        if !attrStack.isEmpty { attrStack.removeLast() }
        textBuffer = ""
    }
}
