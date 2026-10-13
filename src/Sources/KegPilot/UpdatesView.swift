import SwiftUI

struct UpdatesView: View {
    @ObservedObject var model: BrewModel
    @Environment(\.theme) private var theme
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass").foregroundStyle(theme.secondaryText)
                    TextField("Search updates", text: $model.updateSearch).textFieldStyle(.plain)
                        .foregroundStyle(theme.text)
                        .accessibilityLabel("Search updates")
                    if !model.updateSearch.isEmpty {
                        Button { model.updateSearch = "" } label: { Image(systemName: "xmark.circle.fill") }
                            .buttonStyle(.plain).foregroundStyle(theme.secondaryText)
                            .help("Clear search").accessibilityLabel("Clear search")
                    }
                }
                .padding(.horizontal, 9)
                .frame(height: 28)
                .background(theme.field, in: RoundedRectangle(cornerRadius: 8))
                Button("Check") { model.checkUpdates() }
                    .frame(height: 28)
                    .help("Check current Homebrew definitions · ⌘R")
                Button("Refresh definitions") { model.refreshDefinitions() }
                    .frame(height: 28)
                    .help("Fetch current definitions, then check for updates · ⌘⇧R")
            }.disabled(model.busy || !model.ready)
            HStack {
                Text("\(model.updates.count) available · \(model.updates.filter { $0.pinned }.count) pinned")
                Spacer()
                Button("Upgrade All") { model.upgradeAll() }
                    .disabled(model.busy || !model.ready || model.updates.filter { !$0.pinned }.isEmpty || model.updatesStale)
            }.font(.caption).foregroundStyle(theme.secondaryText)
            if let error = model.updatesError { Text(error).font(.caption).foregroundStyle(.red) }
            if model.updatesStale { Text("Results may be stale. Check again before upgrading.").font(.caption).foregroundStyle(theme.warning) }
            ScrollView {
                LazyVStack(spacing: 7) {
                    if model.checkingUpdates { ProgressView("Checking Homebrew…").padding(20) }
                    else if model.updatesLoaded && model.updates.isEmpty {
                        VStack(spacing: 6) {
                            Image(systemName: "checkmark.circle").font(.title2).foregroundStyle(.green)
                            Text("No updates in current definitions").font(.caption).foregroundStyle(theme.text)
                            Text("Use Refresh definitions to fetch the newest package data.").font(.system(size: 10)).foregroundStyle(theme.secondaryText)
                        }.padding(18)
                    }
                    ForEach(model.updates.filter { model.updateSearch.isEmpty || $0.name.localizedCaseInsensitiveContains(model.updateSearch) }) { package in
                        HStack {
                            Image(systemName: package.kind == "App" ? "app.badge" : "shippingbox.fill").foregroundStyle(theme.accent)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(package.name).font(.system(size: 12, weight: .semibold)).foregroundStyle(theme.text)
                                Text("\(package.installedVersions.joined(separator: ", ")) → \(package.currentVersion)")
                                    .font(.system(size: 11, design: .monospaced)).foregroundStyle(theme.accent)
                                Text(package.kind + (package.pinned ? " · Pinned" : "")).font(.system(size: 10)).foregroundStyle(theme.secondaryText)
                            }
                            Spacer()
                            Button {
                                if model.infoTarget == package.id { model.dismissInfo() }
                                else { model.fetchInfo(token: package.name, kind: package.kind, id: package.id) }
                            } label: { Image(systemName: "info.circle") }
                                .buttonStyle(.plain).controlSize(.small).foregroundStyle(theme.secondaryText)
                                .disabled(model.busy || !model.ready).help("Show package details")
                                .accessibilityLabel("Show details for \(package.name)")
                                .popover(isPresented: Binding(get: { model.infoTarget == package.id },
                                                              set: { if !$0 && model.infoTarget == package.id { model.dismissInfo() } })) {
                                    PackageInfoPopover(model: model, fallbackName: package.name).environment(\.theme, theme)
                                }
                            Button("Upgrade") { model.upgrade(package) }.controlSize(.small)
                                .disabled(model.busy || !model.ready || package.pinned || !package.valid || model.updatesStale)
                                .accessibilityLabel("Upgrade \(package.name) to \(package.currentVersion)")
                        }.padding(10).background(theme.surface, in: RoundedRectangle(cornerRadius: 9))
                        .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(theme.surfaceBorder))
                    }
                }
            }
            Text(model.updatesChecked.map { "Checked \($0.formatted(date: .omitted, time: .shortened)) · Standard Homebrew update rules" } ?? "Checks Homebrew formulae and casks")
                .font(.system(size: 10)).foregroundStyle(theme.secondaryText)
        }.frame(height: 270)
        .onAppear { model.loadUpdatesIfNeeded() }
        .onChange(of: model.ready) { _ in model.loadUpdatesIfNeeded() }
    }
}
