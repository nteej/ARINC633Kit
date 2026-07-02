// ARINC633Kit/Parsing/ManifestParser.swift
import Foundation

/// Parses the .lst manifest file found inside an .eff archive.
/// The .lst is XML-based and lists the documents contained in the .dat payload.
enum ManifestParser {

    static func parse(lstFile: URL) -> EFFManifest {
        var manifest = EFFManifest()
        let nodes = XMLFlattener().flatten(url: lstFile)
        guard !nodes.isEmpty else { return manifest }
        let idx = KeywordIndex(nodes: nodes)

        manifest.packageId    = idx.find(["packageid", "packageidentifier", "id"])
        manifest.airline      = idx.find(["airline", "operator", "carrier"])
        manifest.flightNumber = idx.find(["flightnumber", "fltnum", "flight"])
        if let s = idx.find(["creationdate", "creationtime", "timestamp", "created"]) {
            manifest.creationDate = DateParsing.parse(s)
        }

        let entryGroups = idx.groups { parent in
            let p = parent.lowercased()
            return p.contains("document") || p.contains("entry") || p.contains("file")
        }

        manifest.entries = entryGroups.compactMap { group in
            guard let fileName = group.first(where: {
                ["filename", "name", "file"].contains($0.element.lowercased())
            })?.value, !fileName.isEmpty else { return nil }

            return EFFManifestEntry(
                documentId: group.first(where: {
                    ["documentid", "id", "docid"].contains($0.element.lowercased())
                })?.value,
                fileName: fileName,
                category: group.first(where: {
                    ["category", "type", "documenttype"].contains($0.element.lowercased())
                })?.value,
                mimeType: group.first(where: {
                    ["mimetype", "contenttype"].contains($0.element.lowercased())
                })?.value,
                size: group.first(where: {
                    ["size", "filesize", "bytes"].contains($0.element.lowercased())
                }).flatMap { Int($0.value) },
                checksum: group.first(where: {
                    ["checksum", "hash", "md5", "sha256"].contains($0.element.lowercased())
                })?.value,
                description: group.first(where: {
                    ["description", "desc"].contains($0.element.lowercased())
                })?.value
            )
        }

        return manifest
    }
}
