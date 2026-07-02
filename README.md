# ARINC633Kit

A Swift package for reading **ARINC 633** Electronic Flight Folder (`.eff`) files on iOS, iPadOS, and macOS.

`ARINC633Kit` provides a schema-agnostic reader for the airline-operational data exchanged between Airline Operational Control (AOC) systems and Electronic Flight Bags (EFBs) — Operational Flight Plans (OFP), weather, NOTAMs, load planning, and more.

---

## What is ARINC 633?

ARINC 633 is an industry specification that defines a common XML-based format for AOC ↔ EFB communications. An `.eff` (Electronic Flight Folder) file is a ZIP container that bundles the documents needed for a single flight: OFP, briefing package, weather (METAR/TAF), NOTAMs, load planning, MEL, and vendor-specific attachments.

Supplement revisions (633-2 through 633-5) have progressively added schema extensions, transport bindings, and packaging conventions. Because vendors often extend the base schema with proprietary element names, **`ARINC633Kit` parses by keyword/aliases rather than by hard-coded XPath**, so it degrades gracefully across supplement versions and vendor dialects.

---

## Features

- **ZIP + MIME container handling** — Unpacks `.eff` archives whether they contain a traditional folder layout (`lst/` + `dat/`) or sibling-file layout (`.lst` manifest + `.dat` MIME multipart payload).
- **Manifest parsing** — Reads the M633 header block and enumerates payload documents from the `.lst` file.
- **OFP Smart Extractor** — Auto-detects the Operational Flight Plan among all payloads and extracts flight number, route, ETD/ETA, alternates, fuel, weights, waypoints, and remarks — regardless of vendor element naming.
- **Schema-agnostic XML flattener** — Converts arbitrary XML trees to a browsable `[XMLNode]` list with keyword-indexed lookup via `KeywordIndex`.
- **Extensible message pipeline** — Add new document type parsers by conforming to `ARINC633MessageExtractor`.
- **No SwiftUI dependency** — Core module is pure Foundation, suitable for CLI tools, server-side Swift, or non-UI test harnesses.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     ARINC633Kit  (core)                 │
│                                                         │
│  IO           ─  EFFReader, EFFArchiveUnpacker,         │
│                  MIMEMultipartExtractor                 │
│  Parsing      ─  XMLFlattener, KeywordIndex,            │
│                  OFPSmartExtractor, ManifestParser,     │
│                  DateParsing                            │
│  Models       ─  EFFPackage, EFFDocument, OFPDocument,  │
│                  XMLNode, FlightPlan, Waypoint, …       │
│  Categorization  DocumentCategory, DocumentClassifier   │
│                                                         │
│  Dependencies:   Foundation, ZIPFoundation              │
└─────────────────────────────────────────────────────────┘
```

---

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/nteej/ARINC633Kit.git", branch: "main")
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "ARINC633Kit", package: "ARINC633Kit")
        ]
    )
]
```

Or in Xcode: **File → Add Packages…** → paste the repository URL.

### Requirements

| Platform      | Minimum |
|---------------|---------|
| iOS / iPadOS  | 15.0    |
| macOS         | 12.0    |
| Mac Catalyst  | 15.0    |
| Swift         | 6.0     |

---

## Quick Start

### Read an `.eff` file

```swift
import ARINC633Kit

let url = URL(fileURLWithPath: "/path/to/flight.eff")

do {
    let package = try ARINC633Kit.read(from: url)
    defer { package.cleanup() }   // frees the temporary extraction directory

    print("Flight:   ", package.manifest?.flightNumber ?? "-")
    print("Documents:", package.documents.count)

    if let ofp = package.ofp {
        print("Route:    ", ofp.route.routeString ?? "-")
        print("Dep/Arr:  ", ofp.flightInfo.departureICAO ?? "-",
                           "→", ofp.flightInfo.arrivalICAO ?? "-")
        print("ETD:      ", ofp.flightInfo.etd?.description ?? "-")
        print("Block fuel:", ofp.fuel?.blockFuel ?? "-")
    }
} catch let error as EFFReaderError {
    print("EFF error:", error.localizedDescription)
} catch {
    print("Unexpected error:", error)
}
```

### Inspect all documents

```swift
let package = try ARINC633Kit.read(from: url)
defer { package.cleanup() }

for doc in package.documents {
    print(doc.category.displayName, doc.name, doc.sizeBytes, "bytes")
}
```

### Browse the raw XML field tree

```swift
if let ofp = package.ofp {
    for node in ofp.allNodes where node.path.contains("Fuel") {
        print(node.path, "=", node.value)
    }
}
```

---

## Model Overview

### `EFFPackage`

The top-level result of `ARINC633Kit.read(from:)`.

| Property | Type | Description |
|---|---|---|
| `fileName` | `String` | Original `.eff` filename |
| `manifest` | `EFFManifest?` | Parsed `.lst` manifest (package ID, airline, entries) |
| `documents` | `[EFFDocument]` | All files extracted from the `.dat` payload |
| `ofp` | `OFPDocument?` | Parsed Operational Flight Plan |
| `ofpDocument` | `EFFDocument?` | The raw `EFFDocument` that yielded the OFP |
| `flightPlan` | `FlightPlan?` | Structured flight plan (populated by `FlightPlanXMLParser`) |
| `airportWeathers` | `[AirportWeather]` | METAR/TAF entries |
| `notams` | `[Notam]` | NOTAM records |
| `extractionRoot` | `URL?` | Temporary directory holding unpacked files |
| `cleanup()` | — | Deletes `extractionRoot` from disk |

### `OFPDocument`

Extracted from the OFP XML by `OFPSmartExtractor`.

| Property | Type | Description |
|---|---|---|
| `header` | `M633Header` | ARINC 633 message envelope (sender, messageId, version, …) |
| `flightInfo` | `OFPFlightInfo` | Flight number, aircraft, dep/arr ICAO, STD/STA, ETD/ETA |
| `route` | `OFPRoute` | Route string, distance NM, cruise level, waypoints |
| `fuel` | `OFPFuel?` | Taxi, tripFuel, contingency, block, total, unit |
| `weights` | `OFPWeights?` | DOW, ZFW, TOW, LDW, MTOW, MLW, payload, unit |
| `alternates` | `[OFPAlternate]` | Alternate airports with distance and fuel |
| `crew` | `[OFPCrew]` | Crew members with role and name |
| `weatherSummary` | `[OFPWeatherEntry]` | METAR/TAF per airport embedded in the OFP |
| `remarks` | `[String]` | Free-text remark fields |
| `rawXMLPreview` | `String?` | First 8 000 characters of the source XML |
| `allNodes` | `[XMLNode]` | Full flattened node list for custom field lookup |

### `DocumentCategory`

An enum describing the type of each `EFFDocument`:

`ofp` · `flightPlan` · `weather` · `notam` · `loadsheet` · `chart` · `image` · `xml` · `pdf` · `other`

---

## Supported `.eff` Layouts

`ARINC633Kit` recognises two container variants seen in the wild:

**A. Folder layout** (early supplements)

```
sample.eff  (ZIP)
├── lst/
│   └── manifest.xml
└── dat/
    ├── FLIGHT_ofp.xml
    ├── weather.xml
    └── ...
```

**B. Sibling-file layout** (common on real airline exports)

```
XL261X_XXS115_200619_RJAA_RKSI.eff  (ZIP)
├── XL261X_XXS115_200619_RJAA_RKSI.lst   (XML manifest)
└── XL261X_XXS115_200619_RJAA_RKSI.dat   (ZIP or MIME multipart payload)
```

For layout **B**, the `.dat` file is first attempted as a nested ZIP. If that fails, it is parsed as a MIME multipart envelope and each part is extracted as an `EFFDocument`.

---

## Extending With Custom Message Types

Conform to `ARINC633MessageExtractor` to add new document interpreters without modifying the core:

```swift
import ARINC633Kit

enum LoadsheetExtractor: ARINC633MessageExtractor {
    typealias Output = MyLoadsheet

    static var category: DocumentCategory { .loadsheet }

    static func canHandle(fileName: String) -> Bool {
        fileName.lowercased().contains("loadsheet")
    }

    static func extract(from url: URL) -> MyLoadsheet? {
        let nodes = XMLFlattener().flatten(url: url)
        let idx = KeywordIndex(nodes: nodes)
        return MyLoadsheet(
            zeroFuelWeight: idx.find(["zfw", "zerofuelweight"]),
            takeoffWeight:  idx.find(["tow", "takeoffweight"])
        )
    }
}
```

Call your extractor directly alongside the standard read:

```swift
let package = try ARINC633Kit.read(from: url)
defer { package.cleanup() }

let loadsheetDocs = package.documents.filter { $0.category == .loadsheet }
for doc in loadsheetDocs {
    if let sheet = LoadsheetExtractor.extract(from: doc.url) {
        print("ZFW:", sheet.zeroFuelWeight ?? "-")
    }
}
```

---

## Error Handling

`ARINC633Kit.read(from:)` throws `EFFReaderError`:

| Case | Meaning |
|---|---|
| `.cannotOpenArchive` | The file could not be opened as a ZIP archive |
| `.extractionFailed(String)` | ZIP decompression failed; message contains the underlying error |
| `.emptyArchive` | The archive contained no files |
| `.missingDatFile` | No `.dat` payload file was found inside the archive |

---

## Testing

```bash
swift test
```

Fixtures live in `Tests/ARINC633KitTests/Fixtures/`. Contribute anonymised sample files to widen coverage across vendor dialects (Lufthansa Systems Lido, NAVBLUE, Sabre AirCentre, Jeppesen, etc.).

---

## Roadmap

- Loadsheet extractor (weights & CG)
- Structured NOTAM parser with Q-code decoding
- METAR/TAF decoder integration
- Signed EFF (ARINC 665 packaging) verification
- Encrypted `.eff` support per ARINC 633-5 §Security
- macOS Quick Look preview extension
- Command-line inspector (`arinc633 inspect flight.eff`)

---

## Contributing

Pull requests welcome. Please:

1. Open an issue describing the change first for anything larger than a bug fix
2. Include a redacted fixture file if you're adding parser support for a new vendor dialect
3. Add tests under `Tests/ARINC633KitTests/`
4. Keep the `ARINC633Kit` target free of SwiftUI imports

---

## License

MIT — see [LICENSE](LICENSE) for full text.

---

## Acknowledgements

- [ZIPFoundation](https://github.com/weichsel/ZIPFoundation) for archive handling
- The ARINC 633 working group and SAE ITC for the underlying industry specification
- Anonymised sample data contributed by operators (redacted per each carrier's data policy)

---

## Disclaimer

`ARINC633Kit` is an independent open-source implementation and is **not** affiliated with, endorsed by, or certified by SAE ITC, ARINC Industry Activities, or any airline vendor. For safety-critical operations, always cross-reference against your certified EFB software.
