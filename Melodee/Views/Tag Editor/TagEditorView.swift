import PhotosUI
import SFBAudioEngine
import SwiftUI
import TipKit

struct TagEditorView: View {

    @Environment(NowPlayingBarManager.self) var nowPlayingBarManager: NowPlayingBarManager

    @State var files: [FSFile]
    @State var audioFiles: [FSFile: AudioFile] = [:]
    @State var tagData = Tag()
    @State var selectedPhoto: PhotosPickerItem?
    @State var isSelectingFile: Bool = false
    @State var saveState: SaveState = .notSaved
    @State var savePercentage: Int = 0
    @State var isInitialLoadCompleted: Bool = false
    @State var initialLoadPercentage: Int = 0
    @State var isConfirmingAlbumArtDeletion: Bool = false
    @State var isTokensPopoverPresented: Bool = false
    @FocusState var focusedField: FocusedField?

    var albumArtControlsPadding: CGFloat {
        if #available(iOS 27.0, *) {
            8.0
        } else {
            0.0
        }
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 12.0) {
                    Group {
                        if let albumArt = tagData.albumArt,
                           let albumArtImage = UIImage(data: albumArt) {
                            Image(uiImage: albumArtImage)
                                .resizable()
                        } else {
                            Image(.albumGeneric)
                                .resizable()
                        }
                    }
                    .scaledToFill()
                    .frame(width: 240.0, height: 240.0)
                    .clipShape(RoundedRectangle(cornerRadius: 16.0))
                    .shadow(color: .black.opacity(0.15), radius: 8.0, y: 4.0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16.0)
                            .stroke(.primary, lineWidth: 1/3)
                            .opacity(0.3)
                    )
                    .overlay(alignment: .bottom) {
                        HStack(spacing: albumArtControlsPadding) {
                            PhotosPicker(selection: $selectedPhoto,
                                         matching: .images,
                                         photoLibrary: .shared()) {
                                Image(systemName: "photo")
                            }
                            .buttonStyle(.glass)
                            .buttonBorderShape(.circle)
                            Button {
                                isSelectingFile = true
                            } label: {
                                Image(systemName: "folder")
                            }
                            .buttonStyle(.glass)
                            .buttonBorderShape(.circle)
                            Button(role: .destructive) {
                                isConfirmingAlbumArtDeletion = true
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.glass)
                            .buttonBorderShape(.circle)
                            .tint(.red)
                            .disabled(tagData.albumArt == nil)
                        }
                        .controlSize(.large)
                        .imageScale(.large)
                        .padding(.bottom, 12.0)
                    }
                    Text(files.count == 1 ? files[0].name :
                            NSLocalizedString("BatchEdit.MultipleFiles", comment: ""))
                        .bold()
                        .textCase(.none)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 16.0, leading: 16.0, bottom: 16.0, trailing: 16.0))
            }
            if files.count == 1 {
                TETagDataSection(tagData: $tagData, focusedField: $focusedField)
                    .popoverTip(TETokensTip(), arrowEdge: .top)
            } else {
                TETagDataSection(tagData: $tagData, focusedField: $focusedField,
                               placeholder: NSLocalizedString("BatchEdit.Keep", comment: ""))
            }
        }
        .contentMargins(.top, 0.0, for: .scrollContent)
        .navigationTitle("ViewTitle.TagEditor")
        .navigationBarTitleDisplayMode(.inline)
        .disabled(saveState == .saving || !isInitialLoadCompleted)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Spacer()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if saveState == .notSaved && isInitialLoadCompleted {
                        Task {
                            changeSaveState(to: .saving)
                            UIApplication.shared.isIdleTimerDisabled = true
                            await saveAllTagData()
                            await readAllTagData()
                            UIApplication.shared.isIdleTimerDisabled = false
                            changeSaveState(to: .saved)
                        }
                    }
                } label: {
                    Group {
                        switch saveState {
                        case .notSaved:
                            Text("Shared.Save")
                                .bold()
                        case .saving:
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        case .saved:
                            Image(systemName: "checkmark")
                                .bold()
                        }
                    }
                    .foregroundStyle(.white)
                }
                .buttonStyle(.borderedProminent)
                .tint(saveState == .saved ? .green : .accentColor)
                .disabled(!isInitialLoadCompleted)
            }
            ToolbarSpacer(.flexible, placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) {
                Button {
                    isTokensPopoverPresented = true
                } label: {
                    Image(systemName: "curlybraces")
                }
                .popover(isPresented: $isTokensPopoverPresented) {
                    List {
                        TEAvailableTokensSection()
                    }
                    .listStyle(.plain)
                    .frame(minWidth: 320.0, idealWidth: 360.0, minHeight: 320.0, idealHeight: 440.0)
                    .presentationCompactAdaptation(.popover)
                }
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .sheet(isPresented: $isSelectingFile) {
            DocumentPicker(allowedUTIs: [.image], onDocumentPicked: { url in
                let isAccessSuccessful = url.startAccessingSecurityScopedResource()
                if isAccessSuccessful {
                    selectedPhoto = nil
                    let imageFileData: Data? = try? Data(contentsOf: url)
                    tagData.albumArt = imageFileData
                    tagData.shouldRemoveAlbumArt = false
                }
                url.stopAccessingSecurityScopedResource()
            })
            .ignoresSafeArea(edges: [.bottom])
        }
        .alert("TagEditor.RemoveAlbumArt", isPresented: $isConfirmingAlbumArtDeletion) {
            Button("Shared.Delete", role: .destructive) {
                selectedPhoto = nil
                tagData.albumArt = nil
                tagData.shouldRemoveAlbumArt = true
            }
            Button("Shared.Cancel", role: .cancel) { }
        }
        .overlay {
            if !isInitialLoadCompleted {
                ProgressAlert(title: "Alert.ReadingTags.Title",
                              message: "Alert.ReadingTags.Text",
                              percentage: $initialLoadPercentage)
            }
        }
        .overlay {
            if saveState == .saving {
                ProgressAlert(title: "Alert.SavingTags.Title",
                              message: "Alert.SavingTags.Text",
                              percentage: $savePercentage)
            }
        }
        .task {
            if !isInitialLoadCompleted {
                await readAllTagData()
                isInitialLoadCompleted = true
            }
        }
        .onChange(of: selectedPhoto) { _, _ in
            Task {
                if let selectedPhoto = selectedPhoto,
                    let data = try? await selectedPhoto.loadTransferable(type: Data.self) {
                    tagData.albumArt = data
                    tagData.shouldRemoveAlbumArt = false
                }
            }
        }
        .onChange(of: saveState) { _, _ in
            switch saveState {
            case .saved:
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    changeSaveState(to: .notSaved)
                }
            default:
                break
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(.easeOut) {
                nowPlayingBarManager.isKeyboardShowing = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut) {
                nowPlayingBarManager.isKeyboardShowing = false
            }
        }
    }
}
