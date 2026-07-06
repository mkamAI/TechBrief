import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // ── Plan ──────────────────────────────────────────────────────
                Section {
                    HStack {
                        Label("Current Plan", systemImage: "sparkles")
                        Spacer()
                        Text("Free")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("Daily Limit", systemImage: "clock")
                        Spacer()
                        Text("3 briefs / day")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Plan")
                } footer: {
                    Text("Upgrade to Pro for unlimited briefs and offline PDF history.")
                }

                // ── Upgrade CTA ───────────────────────────────────────────────
                Section {
                    Button {
                        // StoreKit paywall — hooked up in a future sprint
                    } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(.yellow)
                            Text("Upgrade to Pro — $4.99 / month")
                                .fontWeight(.semibold)
                        }
                    }
                    .tint(Color.accent)
                }

                // ── About ─────────────────────────────────────────────────────
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Powered by")
                        Spacer()
                        Text("Claude Haiku")
                            .foregroundStyle(.secondary)
                    }
                    Link("Privacy Policy",
                         destination: URL(string: "https://example.com/privacy")!)
                    Link("Terms of Service",
                         destination: URL(string: "https://example.com/terms")!)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview { SettingsView() }
