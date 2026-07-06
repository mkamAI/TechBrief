# TechBrief iOS ⚡

Native SwiftUI iOS app — search any tech topic and get a concise brief with key concepts, code examples, YouTube links, and a downloadable PDF. Powered by Claude AI.

---

## Setup (3 steps)

### 1. Install xcodegen (one-time)
```bash
brew install xcodegen
```

### 2. Generate the Xcode project
```bash
cd ~/Desktop/IOS\ APPS\ Build/TechBrief-iOS
xcodegen generate
```
This creates `TechBrief.xcodeproj`. Open it in Xcode.

### 3. Add your Anthropic API key
- Run the app on Simulator or a real device
- Tap the ⚙️ gear icon (top right)
- Paste your API key (get one at https://console.anthropic.com)

That's it — search any topic and generate your first brief!

---

## App flow

```
Search screen
  └── Type a topic (or tap an example chip)
      └── Claude generates the brief (~5 seconds)
          └── Brief Detail screen
              ├── Scrollable sections (concepts, code, YouTube links, what's next)
              └── Tap "PDF" in nav bar → view + share the polished PDF
```

---

## File structure

```
TechBrief/
  TechBriefApp.swift          App entry point
  ContentView.swift           Root navigator
  Extensions.swift            Color + preview data
  Models/
    Brief.swift               All data models
  Services/
    ClaudeService.swift       Anthropic API calls (URLSession)
    PDFGenerator.swift        Native PDF via UIGraphicsPDFRenderer + PDFKit
  Views/
    SearchView.swift          Search UI + example chips
    BriefDetailView.swift     Full brief display
    PDFViewerView.swift       In-app PDF viewer with share sheet
    SettingsView.swift        API key entry
```

---

## Requirements

- Xcode 15+
- iOS 17+ (Simulator or device)
- Anthropic API key
