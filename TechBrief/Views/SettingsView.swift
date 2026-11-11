import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var store

    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                // ── Plan ──────────────────────────────────────────────────────
                Section {
                    HStack {
                        Label("Current Plan", systemImage: "sparkles")
                        Spacer()
                        Text(store.isPro ? "Pro" : "Free")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("Daily Limit", systemImage: "clock")
                        Spacer()
                        Text(store.isPro ? "Unlimited" : "3 briefs / day")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Plan")
                } footer: {
                    if !store.isPro {
                        Text("Upgrade to Pro for unlimited briefs and offline PDF history.")
                    }
                }

                // ── Upgrade CTA ───────────────────────────────────────────────
                if !store.isPro {
                    Section {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.yellow)
                                Text("Upgrade to Pro — \(store.proPriceDisplay) / month")
                                    .fontWeight(.semibold)
                            }
                        }
                        .tint(Color.accent)

                        Button("Restore Purchases") {
                            Task { await store.restorePurchases() }
                        }
                    }
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
                         destination: URL(string: "https://techbrief-backend.vercel.app/privacy")!)
                    Link("Terms of Service",
                         destination: URL(string: "https://techbrief-backend.vercel.app/terms")!)
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
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
}

#Preview { SettingsView().environment(StoreManager()) }
