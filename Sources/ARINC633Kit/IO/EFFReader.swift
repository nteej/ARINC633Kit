//
//  EFFReader.swift
//  EFFReader
//
//  Created by Liyana on 1.7.2026.
//


// ARINC633Kit/IO/EFFReader.swift
import Foundation

public enum EFFReader {

    public static func read(from effURL: URL) throws -> EFFPackage {
        let unpack = try EFFArchiveUnpacker.unpack(eff: effURL)

        var package = EFFPackage(fileName: effURL.lastPathComponent)
        package.extractionRoot = unpack.workDir

        if let lst = unpack.lstFile {
            package.manifest = ManifestParser.parse(lstFile: lst)
        }

        package.documents = buildDocuments(
            from: unpack.extractedDocs,
            root: unpack.datExtractDir,
            manifest: package.manifest
        )

        // Run all registered extractors (today just OFP, tomorrow more)
        applyExtractors(to: &package)

        return package
    }

    private static func buildDocuments(from files: [URL], root: URL,
                                        manifest: EFFManifest?) -> [EFFDocument] {
        files.compactMap { url -> EFFDocument? in
            if url.lastPathComponent.hasPrefix(".") { return nil }
            if url.path.contains("__MACOSX") { return nil }

            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?
                .fileSize ?? 0
            let relative = url.path.replacingOccurrences(
                of: root.path + "/", with: "")
            let entry = manifest?.entries.first {
                $0.fileName.caseInsensitiveCompare(relative) == .orderedSame
                || $0.fileName.lowercased()
                    .hasSuffix(url.lastPathComponent.lowercased())
            }
            let category: DocumentCategory = entry?.category
                .flatMap(DocumentCategory.init(rawValue:))
                ?? DocumentClassifier.classify(fileName: url.lastPathComponent)

            return EFFDocument(
                name: url.lastPathComponent,
                path: relative,
                url: url,
                category: category,
                mimeType: entry?.mimeType
                    ?? DocumentClassifier.mimeType(for: url),
                sizeBytes: Int64(size),
                description: entry?.description
            )
        }
        .sorted { $0.name < $1.name }
    }

    private static func applyExtractors(to package: inout EFFPackage) {
        for doc in package.documents {
            // OFP — stop at first match; later files with the same name pattern should not overwrite
            if package.ofp == nil, OFPSmartExtractor.canHandle(fileName: doc.name) {
                package.ofp = OFPSmartExtractor.extract(from: doc.url)
                package.ofpDocument = doc
            }
            // Future extractors plug in here, e.g.:
            // if LoadsheetSmartExtractor.canHandle(fileName: doc.name) { ... }
        }
    }
}