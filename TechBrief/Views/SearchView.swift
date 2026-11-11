import SwiftUI

// MARK: - ViewModel

@MainActor
@Observable
final class SearchViewModel {
    var topic: String = ""
    var state: LoadState = .idle
    var brief: Brief?
    var errorMessage: String = ""
    var showPaywall: Bool = false

    enum LoadState { case idle, loading, done, error }

    let service = ClaudeService()

    func generate(topic: String, isPro: Bool) async {
        guard !topic.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        state = .loading
        errorMessage = ""
        brief = nil

        do {
            let result = try await service.generateBrief(for: topic, isPro: isPro)
            brief = result
            state = .done
        } catch TechBriefError.freeLimitReached {
            state = .idle
            showPaywall = true
        } catch {
            errorMessage = error.localizedDescription
            state = .error
        }
    }

    func refreshUsage(isPro: Bool) async {
        await service.fetchUsage(isPro: isPro)
    }
}

// MARK: - View

struct SearchView: View {
    @State private var vm = SearchViewModel()
    @State private var showSettings = false
    @Environment(StoreManager.self) private var store

    private let examples = [
        "Kubernetes", "TypeScript", "GraphQL",
        "WebSockets", "Redis", "LangChain",
        "OAuth2", "CI/CD"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroHeader
                    .padding(.top, 16)

                searchBar
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                usageBanner
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                if vm.state == .idle {
                    exampleChips
                        .padding(.top, 12)
                }

                stateContent
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showSettings = true } label: {
                    Image(systemName: "gear")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: Binding(
            get: { vm.showPaywall && !store.isPro },
            set: { vm.showPaywall = $0 }
        )) {
            PaywallView()
        }
        .navigationDestination(item: $vm.brief) { brief in
            BriefDetailView(brief: brief)
        }
        .task {
            await vm.refreshUsage(isPro: store.isPro)
        }
        .onChange(of: store.isPro) { _, isPro in
            Task { await vm.refreshUsage(isPro: isPro) }
        }
    }

    // ── Hero ──────────────────────────────────────────────────────────────
    private var heroHeader: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.accent)
                    .frame(width: 56, height: 56)
                Text("TB")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            Text("TechBrief")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(.primary)
            Text("Search any tech topic.\nGet the gist in 5 minutes.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .padding(.vertical, 8)
    }

    // ── Search bar ────────────────────────────────────────────────────────
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.body.weight(.medium))
            TextField("e.g. Kubernetes, TypeScript…", text: $vm.topic)
                .font(.body)
                .submitLabel(.search)
                .onSubmit { Task { await vm.generate(topic: vm.topic, isPro: store.isPro) } }
                .disabled(vm.state == .loading)
            if !vm.topic.isEmpty {
                Button {
                    vm.topic = ""
                    vm.state = .idle
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // ── Usage banner ──────────────────────────────────────────────────────
    @ViewBuilder
    private var usageBanner: some View {
        if store.isPro {
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
                Text("Unlimited briefs with Pro")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
            )
            .transition(.opacity.combined(with: .move(edge: .top)))
        } else if let usage = vm.service.usage {
            HStack(spacing: 6) {
                // pip dots
                HStack(spacing: 4) {
                    ForEach(0..<usage.limit, id: \.self) { i in
                        Circle()
                            .fill(i < usage.used ? Color.accent : Color(.separator))
                            .frame(width: 7, height: 7)
                    }
                }
                Text(usageCopy(usage))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(usage.remaining == 0 ? Color.orange : .secondary)

                Spacer()

                if usage.remaining == 0 {
                    Button("Upgrade →") { vm.showPaywall = true }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accent)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
            )
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private func usageCopy(_ usage: UsageInfo) -> String {
        switch usage.remaining {
        case 0:       return "No free briefs left today"
        case 1:       return "1 free brief left today"
        default:      return "\(usage.remaining) of \(usage.limit) free briefs left today"
        }
    }

    // ── Example chips ─────────────────────────────────────────────────────
    private var exampleChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(examples, id: \.self) { example in
                    Button {
                        vm.topic = example
                        Task { await vm.generate(topic: example, isPro: store.isPro) }
                    } label: {
                        Text(example)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color(.systemBackground), in: Capsule())
                            .foregroundStyle(.primary)
                            .overlay(Capsule().stroke(Color(.separator), lineWidth: 0.5))
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // ── State content ─────────────────────────────────────────────────────
    @ViewBuilder
    private var stateContent: some View {
        switch vm.state {
        case .idle:    howItWorksCards
        case .loading: loadingView
        case .done:    EmptyView()
        case .error:   errorView
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.3)
                .tint(Color.accent)
            VStack(spacing: 4) {
                Text("Briefing you on \(vm.topic)…")
                    .font(.headline)
                Text("Asking Claude to summarise the key concepts")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var errorView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text("Generation failed")
                .font(.headline)
            Text(vm.errorMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Try again") { vm.state = .idle }
                .buttonStyle(.bordered)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var howItWorksCards: some View {
        VStack(spacing: 12) {
            Text("How it works")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)
            HowItWorksRow(icon: "magnifyingglass", color: .blue,
                          title: "Search a topic",
                          subtitle: "Type any tech topic — language, tool, protocol, or framework")
            HowItWorksRow(icon: "cpu", color: .purple,
                          title: "Claude briefs you",
                          subtitle: "Key concepts, code example, and curated YouTube links generated instantly")
            HowItWorksRow(icon: "doc.richtext", color: .green,
                          title: "Download the PDF",
                          subtitle: "Save a polished cheat sheet to read offline or share with your team")
        }
    }
}

// MARK: - How It Works Row

struct HowItWorksRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(14)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    NavigationStack { SearchView() }
        .environment(StoreManager())
}
