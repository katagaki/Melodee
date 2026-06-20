import SwiftUI
import TipKit

struct MainView: View {

    @Environment(ExternalFoldersManager.self) var externalFolders: ExternalFoldersManager

    @AppStorage("SelectedLibrarySource") var selectedSource: LibrarySource = .local
    @AppStorage("LastOnboardedVersion") var lastOnboardedVersion: String = ""
    @State var path: [ViewPath] = []
    @State var isOnboardingPresented: Bool = false

    var body: some View {
        let configuration = rootConfiguration()
        NavigationStack(path: $path) {
            FolderView(
                currentDirectory: configuration.directory,
                overrideStorageLocation: configuration.storageLocation,
                isLibraryRoot: true
            )
            .id(configuration.source)
            .hasFileBrowserNavigationDestinations()
        }
        .playbackBarAccessory()
        .onChange(of: selectedSource) {
            path.removeAll()
        }
        .onAppear {
            normalizeSelectedSource()
            presentOnboardingIfNeeded()
        }
        .onOpenURL { url in
            // melodee://reonboard re-opens the onboarding sheet on demand.
            if url.scheme == "melodee", url.host == "reonboard" {
                isOnboardingPresented = true
            }
        }
        .sheet(isPresented: $isOnboardingPresented) {
            OnboardingView {
                lastOnboardedVersion = OnboardingView.appVersion
                isOnboardingPresented = false
            }
        }
        .task {
            try? Tips.configure([
                .displayFrequency(.immediate),
                .datastoreLocation(.applicationDefault)
            ])
        }
    }

    // Show onboarding on first launch and whenever the major/minor version is bumped.
    func presentOnboardingIfNeeded() {
        if OnboardingView.shouldShow(
            currentVersion: OnboardingView.appVersion,
            lastSeenVersion: lastOnboardedVersion
        ) {
            isOnboardingPresented = true
        }
    }

    // MARK: - Source resolution

    struct RootConfiguration {
        var source: LibrarySource
        var directory: FSDirectory?
        var storageLocation: StorageLocation
    }

    func rootConfiguration() -> RootConfiguration {
        switch selectedSource {
        case .cloud where FileManager.default.ubiquityIdentityToken != nil:
            return RootConfiguration(source: .cloud, directory: nil, storageLocation: .cloud)
        case .external(let id):
            if let bookmark = externalFolders.bookmark(with: id),
               let url = externalFolders.resolveBookmark(bookmark) {
                let directory = FSDirectory(
                    name: bookmark.name,
                    path: url.path(percentEncoded: false),
                    files: []
                )
                return RootConfiguration(source: .external(id), directory: directory, storageLocation: .external)
            }
            return RootConfiguration(source: .local, directory: nil, storageLocation: .local)
        default:
            return RootConfiguration(source: .local, directory: nil, storageLocation: .local)
        }
    }

    func normalizeSelectedSource() {
        let resolved = rootConfiguration().source
        if resolved != selectedSource {
            selectedSource = resolved
        }
    }
}
