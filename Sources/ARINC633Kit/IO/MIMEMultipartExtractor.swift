//
//  MIMEMultipartExtractor.swift
//  EFFReader
//
//  Created by Liyana on 30.6.2026.
//


// MIMEMultipartExtractor.swift
import Foundation

enum MIMEMultipartExtractor {

    static func extract(from datFile: URL, into dest: URL) throws -> [URL] {
        let data = try Data(contentsOf: datFile)
        guard let text = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .isoLatin1) else {
            return []
        }

        // Find boundary
        guard let boundary = findBoundary(in: text) else { return [] }
        let delimiter = "--\(boundary)"

        // Split into parts
        let segments = text.components(separatedBy: delimiter)
            .dropFirst()                         // before first boundary = preamble
            .filter { !$0.hasPrefix("--") }      // last part is "--" (closing)

        var outputs: [URL] = []
        let fm = FileManager.default

        for (idx, segment) in segments.enumerated() {
            // Headers / body separator = blank line
            let trimmed = segment.drop(while: { $0 == "\r" || $0 == "\n" })
            guard let separatorRange = trimmed.range(of: "\r\n\r\n")
                    ?? trimmed.range(of: "\n\n") else { continue }

            let headerBlock = String(trimmed[..<separatorRange.lowerBound])
            let body = String(trimmed[separatorRange.upperBound...])
                .trimmingCharacters(in: CharacterSet(charactersIn: "\r\n"))

            // Extract filename from headers
            var fileName = "part_\(idx + 1)"
            for line in headerBlock.split(whereSeparator: \.isNewline) {
                let l = String(line)
                if let r = l.range(of: "filename=", options: .caseInsensitive) {
                    let after = l[r.upperBound...]
                        .trimmingCharacters(in: CharacterSet(charactersIn: " \";\r"))
                    if !after.isEmpty { fileName = after }
                } else if let r = l.range(of: "name=", options: .caseInsensitive),
                          fileName.hasPrefix("part_") {
                    let after = l[r.upperBound...]
                        .trimmingCharacters(in: CharacterSet(charactersIn: " \";\r"))
                    if !after.isEmpty { fileName = after }
                }
            }

            let outURL = dest.appendingPathComponent(fileName)
            try? fm.createDirectory(at: outURL.deletingLastPathComponent(),
                                    withIntermediateDirectories: true)
            try body.data(using: .utf8)?.write(to: outURL)
            outputs.append(outURL)
        }
        return outputs
    }

    private static func findBoundary(in text: String) -> String? {
        // Look for: Content-Type: multipart/...; boundary="xyz"
        guard let r = text.range(of: "boundary=", options: .caseInsensitive)
        else { return nil }
        var rest = text[r.upperBound...]
        if rest.first == "\"" { rest = rest.dropFirst() }
        let end = rest.firstIndex(where: { $0 == "\"" || $0 == "\r"
                                            || $0 == "\n" || $0 == ";" })
            ?? rest.endIndex
        return String(rest[..<end])
    }
}
