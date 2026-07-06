import SwiftUI

struct BriefDetailView: View {
    let brief: Brief

    @State private var pdfData: Data?
    @State private var showPDF = false
    @State private var isGeneratingPDF = false
    @State private var shareItems: [Any] = []
    @State private var showShare = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // ── Hero ──────────────────────────────────────────────────
                heroSection

                VStack(spacing: 20) {
                    // ── What is it ────────────────────────────────────────
                    BriefSection(number: "01", title: "What is \(brief.topic)?") {
                        Text(brief.whatIsIt)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // ── Why it matters ────────────────────────────────────
                    BriefSection(number: "02", title: "Why It Matters") {
                        Text(brief.whyItMatters)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // ── Key concepts ──────────────────────────────────────
                    BriefSection(number: "03", title: "Key Concepts") {
                        VStack(spacing: 10) {
                            ForEach(brief.concepts) { concept in
                                ConceptRow(concept: concept)
                            }
                        }
                    }

                    // ── When to use ───────────────────────────────────────
                    BriefSection(number: "04", title: "When to Use It") {
                        HStack(alignment: .top, spacing: 10) {
                            UseAvoidColumn(
                                title: "✅ Use when",
                                items: brief.useWhen,
                                color: .green
                            )
                            UseAvoidColumn(
                                title: "⚠️ Avoid when",
                                items: brief.avoidWhen,
                                color: .red
                            )
                        }
                    }

                    // ── Code example ──────────────────────────────────────
                    BriefSection(number: "05", title: "Quick Example") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(brief.codeComment)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            CodeBlock(lines: brief.codeLines)
                        }
                    }

                    // ── YouTube links ─────────────────────────────────────
                    BriefSection(number: "06", title: "Watch & Learn") {
                        VStack(spacing: 8) {
                            ForEach(brief.youtubeLinks) { video in
                                YouTubeCard(video: video)
                            }
                        }
                    }

                    // ── Learn next ────────────────────────────────────────
                    BriefSection(number: "07", title: "What to Learn Next") {
                        VStack(spacing: 10) {
                            ForEach(brief.learnNext) { next in
                                NextTopicRow(next: next)
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(brief.topic)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                pdfButton
            }
        }
        .sheet(isPresented: $showPDF) {
            if let data = pdfData {
                PDFViewerView(data: data, title: brief.topic)
            }
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(items: shareItems)
        }
    }

    // ── Hero section ──────────────────────────────────────────────────────
    private var heroSection: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.102, green: 0.122, blue: 0.235),
                         Color(red: 0.145, green: 0.200, blue: 0.380)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("TECHBRIEF")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.accent)
                    .kerning(2)

                Text(brief.topic)
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(brief.tagline)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    Label("5 min read", systemImage: "clock")
                    Label("Code included", systemImage: "chevron.left.forwardslash.chevron.right")
                    Label("Videos", systemImage: "play.circle")
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
    }

    // ── PDF toolbar button ────────────────────────────────────────────────
    private var pdfButton: some View {
        Button {
            generateAndShowPDF()
        } label: {
            if isGeneratingPDF {
                ProgressView().scaleEffect(0.8)
            } else {
                Label("PDF", systemImage: "doc.richtext")
                    .font(.subheadline.weight(.semibold))
            }
        }
        .disabled(isGeneratingPDF)
    }

    private func generateAndShowPDF() {
        isGeneratingPDF = true
        Task.detached(priority: .userInitiated) {
            let data = PDFGenerator.generate(from: brief)
            await MainActor.run {
                pdfData = data
                isGeneratingPDF = false
                showPDF = true
            }
        }
    }
}

// MARK: - Section container

struct BriefSection<Content: View>: View {
    let number: String
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(number)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.accent)
                Text(title)
                    .font(.headline)
            }
            Divider()
            content
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Concept row

struct ConceptRow: View {
    let concept: Concept

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.accent)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(concept.term)
                    .font(.subheadline.weight(.semibold))
                Text(concept.definition)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Use / Avoid column

struct UseAvoidColumn: View {
    let title: String
    let items: [String]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 6) {
                    Text("•")
                        .foregroundStyle(color)
                    Text(item)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(10)
        .background(color.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Code block

struct CodeBlock: View {
    let lines: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 1) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(line.isEmpty ? " " : line)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(
                            line.trimmingCharacters(in: .whitespaces).hasPrefix("#") ||
                            line.trimmingCharacters(in: .whitespaces).hasPrefix("//")
                                ? Color(white: 0.5) : Color(red: 0.886, green: 0.910, blue: 0.941)
                        )
                }
            }
            .padding(14)
        }
        .background(Color(red: 0.059, green: 0.090, blue: 0.165))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - YouTube card

struct YouTubeCard: View {
    let video: YouTubeLink

    var body: some View {
        Button {
            if let url = video.resolvedURL {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.accent)
                        .frame(width: 40, height: 40)
                    Image(systemName: "play.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(video.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    Text("\(video.channel)  ·  \(video.duration)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Next topic row

struct NextTopicRow: View {
    let next: NextTopic

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "arrow.right")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.accent)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(next.topic)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accent)
                Text(next.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Share sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        BriefDetailView(brief: .preview)
    }
}
