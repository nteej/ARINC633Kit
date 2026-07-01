# ARINC633Kit

A Swift package for reading **ARINC 633** Electronic Flight Folder (`.eff`) files on iPadOS, iOS, and macOS.

`ARINC633Kit` provides a schema-agnostic reader for the airline-operational data exchanged between Airline Operational Control (AOC) systems and Electronic Flight Bags (EFBs) — Operational Flight Plans (OFP), weather, NOTAMs, load planning, and more.

Ships with an optional SwiftUI reference UI (`EFFReaderUI`) that renders the parsed package on iPad.

---

## What is ARINC 633?

ARINC 633 is an industry specification that defines a common XML-based format for AOC ↔ EFB communications. An `.eff` (Electronic Flight Folder) file is a ZIP container that bundles the documents needed for a single flight: OFP, briefing package, weather (METAR/TAF), NOTAMs, load planning, MEL, and vendor-specific attachments.

Supplement revisions (633-2 through 633-5) have progressively added schema extensions, transport bindings, and packaging conventions. Because vendors often extend the base schema with proprietary element names, **`ARINC633Kit` parses by keyword/aliases rather than by hard-coded XPath**, so it degrades gracefully across supplement versions and vendor dialects.

---

## Features

- **ZIP + MIME container handling** — Unpacks `.eff` archives whether they contain traditional `lst/` + `dat/` folders **or** sibling `.lst` (XML manifest) + `.dat` (payload) files.
- **Manifest parsing** — Reads the M633 header block and enumerates the payload documents.
- **OFP Smart Extractor** — Auto-detects the Operational Flight Plan among all payloads and extracts flight number, route, ETD/ETA, alternates, fuel, weights, waypoints, and remarks — regardless of vendor element naming.
- **Schema-agnostic XML flattener** — Converts arbitrary XML trees to a browsable `[XMLNode]` structure with search-friendly keyword indexing.
- **Extensible message pipeline** — Add new document types (Loadsheet, NOTAM parser, etc.) by conforming to `ARINC633MessageExtractor`.
- **SwiftUI reference UI** — Optional `EFFReaderUI` target with card-based document list, rich OFP summary view, and full XML field tree browser.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    EFFReaderUI  (SwiftUI)               │
│  Screens • Components • ViewModels                      │
└──────────────────────────┬──────────────────────────────┘
                           │ depends on
┌──────────────────────────▼──────────────────────────────┐
│                     ARINC633Kit  (core)                 │
│                                                         │
│  IO           ─  EFFReader, ArchiveUnpacker, MIME       │
│  Parsing      ─  XMLFlattener, OFPSmartExtractor,       │
│                  KeywordIndex, ManifestParser           │
│  Models       ─  EFFPackage, OFPDocument, XMLNode, …    │
│  Categorization  DocumentCategory, DocumentClassifier   │
│                                                         │
│  Dependencies:   Foundation, ZIPFoundation              │
└─────────────────────────────────────────────────────────┘
```

The core module has **no SwiftUI dependency** so it can be reused in command-line tools, server-side Swift, or non-UI test harnesses.

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
            .product(name: "ARINC633Kit", package: "ARINC633Kit"),
            .product(name: "EFFReaderUI", package: "ARINC633Kit")  // optional UI
        ]
    )
]
```

Or in Xcode: **File → Add Packages…** → paste the repository URL.

### Requirements

| Platform      | Minimum |
|---------------|---------|
| iOS / iPadOS  | 16.0    |
| macOS         | 13.0    |
| Mac Catalyst  | 16.0    |
| Swift         | 5.9     |

---

## Quick Start

### Read an `.eff` file

```swift
import ARINC633Kit

let url = URL(fileURLWithPath: "/path/to/flight.eff")

do {
    let package = try EFFReader().read(from: url)

    print("Flight:", package.manifest.flightNumber ?? "-")
    print("Documents:", package.documents.count)

    if let ofp = package.ofpDocuments.first,
       let plan = ofp.flightPlan {
        print("Route:", plan.route)
        print("ETD:", plan.etd?.description ?? "-")
        print("Fuel:", plan.blockFuelKg ?? 0)
    }
} catch {
    print("Failed:", error)
}
```

### Drop-in SwiftUI view

```swift
import SwiftUI
import ARINC633Kit
import EFFReaderUI

struct RootView: View {
    var body: some View {
        ContentView()  // ships with file picker + full renderer
    }
}
```

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
XL261X_XXS115_200619_RJAA_RKSI_F_260619072857.eff  (ZIP)
├── XL261X_XXS115_200619_RJAA_RKSI_F_260619072857.lst   (XML manifest)
└── XL261X_XXS115_200619_RJAA_RKSI_F_260619072857.dat   (MIME multipart payload)
```

For layout **B**, the `.dat` file is parsed as a MIME multipart envelope, and each part is extracted as an `EFFDocument`.

---

## Extending With Custom Message Types

Conform to `ARINC633MessageExtractor` to add new document interpreters without modifying the core:

```swift
import ARINC633Kit

struct LoadsheetExtractor: ARINC633MessageExtractor {
    typealias Output = Loadsheet

    func canExtract(from document: EFFDocument) -> Bool {
        document.filename.localizedCaseInsensitiveContains("loadsheet")
    }

    func extract(from document: EFFDocument) throws -> Loadsheet {
        let tree = try XMLFlattener().flatten(document.data)
        return Loadsheet(
            zeroFuelWeight: KeywordIndex(tree).firstDouble(matching: ["zfw", "zero_fuel_weight"]),
            takeoffWeight:  KeywordIndex(tree).firstDouble(matching: ["tow", "takeoff_weight"])
        )
    }
}
```

Register your extractor with the reader:

```swift
let reader = EFFReader(extractors: [LoadsheetExtractor()])
let package = try reader.read(from: url)
```

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
