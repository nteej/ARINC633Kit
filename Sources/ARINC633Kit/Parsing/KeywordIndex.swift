//
//  KeywordIndex.swift
//  EFFReader
//
//  Created by Liyana on 1.7.2026.
//


// ARINC633Kit/Parsing/KeywordIndex.swift
import Foundation

/// Schema-agnostic lookup over flattened XML nodes.
/// Used by all smart extractors (OFP, Loadsheet, NOTAM, etc.)
public struct KeywordIndex {
    public let nodes: [XMLNode]

    public init(nodes: [XMLNode]) { self.nodes = nodes }

    /// Find first value whose element matches any key (case-insensitive).
    public func find(_ keys: [String],
                     excluding: [String] = [],
                     pathContains: String? = nil) -> String? {
        for n in nodes {
            let el = n.element.lowercased()
            let path = n.path.lowercased()
            if excluding.contains(el) { continue }
            if let pc = pathContains?.lowercased(), !path.contains(pc) { continue }
            if keys.contains(el) { return n.value }
        }
        return nil
    }

    /// Find a value whose element matches `valueKeys`
    /// AND whose path contains any of `contextAny`.
    public func findInContext(value: [String],
                              contextAny: [String]) -> String? {
        for n in nodes {
            let el = n.element.lowercased()
            let path = n.path.lowercased()
            if value.contains(el),
               contextAny.contains(where: { path.contains($0) }) {
                return n.value
            }
        }
        return nil
    }

    /// All nodes whose path contains the substring.
    public func nodes(pathContaining substring: String) -> [XMLNode] {
        let needle = substring.lowercased()
        return nodes.filter { $0.path.lowercased().contains(needle) }
    }

    /// Group nodes by their immediate parent path where parent matches predicate.
    public func groups(parentMatches: (String) -> Bool) -> [[XMLNode]] {
        var groups: [String: [XMLNode]] = [:]
        for n in nodes {
            let comps = n.path.split(separator: "/").map(String.init)
            guard comps.count >= 2 else { continue }
            let parentPath = comps.dropLast().joined(separator: "/")
            let parentName = String(comps.dropLast().last ?? "")
            if parentMatches(parentPath) || parentMatches(parentName) {
                groups[parentPath, default: []].append(n)
            }
        }
        return Array(groups.values)
    }
}