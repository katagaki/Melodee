//
//  TagEditorView.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/12.
//

import ID3TagEditor
import PhotosUI
import SwiftUI
import TipKit

struct TagEditorView: View {

    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var settings: SettingsManager
    let id3TagEditor = ID3TagEditor()
    @State var files: [FSFile]
    @State var tags: [FSFile: ID3Tag] = [:]
    @State var tagData = Tag()
    @State var selectedAlbumArt: PhotosPickerItem?
    @State var saveState: SaveState = .notSaved
    @State var savePercentage: Int = 0
    @State var isInitialLoadCompleted: Bool = false
    @State var initialLoadPercentage: Int = 0
    @FocusState var focusedField: FocusedField?

    var body: some View {
        List {
            if files.count == 1 {
                TEFileHeaderSection(filename: files[0].name,
                                  albumArt: $tagData.albumArt,
                                  selectedAlbumArt: $selectedAlbumArt)
                TETagDataSection(tagData: $tagData, focusedField: $focusedField)
                    .popoverTip(TETokensTip(), arrowEdge: .top)
            } else {
                TEFileHeaderSection(filename: NSLocalizedString("BatchEdit.MultipleFiles", comment: ""),
                                  albumArt: $tagData.albumArt,
                                  selectedAlbumArt: $selectedAlbumArt)
                TETagDataSection(tagData: $tagData, focusedField: $focusedField,
                               placeholder: NSLocalizedString("BatchEdit.Keep", comment: ""))
            }
            TEAvailableTokensSection()
        }
        .disabled(saveState == .saving)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .center, spacing: 0.0) {
                Button {
                    if saveState == .notSaved {
                        DispatchQueue.global(qos: .background).async {
                            Task {
                                changeSaveState(to: .saving)
                                await saveAllTagData()
                                await readAllTagData()
                                changeSaveState(to: .saved)
                            }
                        }
                    }
                } label: {
                    switch saveState {
                    case .notSaved:
                        LargeButtonLabel(iconName: "square.and.arrow.down.fill", text: "Shared.Save")
                            .bold()
                            .frame(maxWidth: .infinity)
                    case .saving:
                        ProgressView()
                            .progressViewStyle(.circular)
                            .padding(.all, 8.0)
                            .tint(.white)
                    case .saved:
                        Image(systemName: "checkmark")
                            .font(.body)
                            .bold()
                            .padding([.top, .bottom], 8.0)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(saveState == .saved ? .green : .accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 99))
                .frame(minHeight: 56.0)
                .padding([.leading, .trailing], 16.0)
                Color.clear
                    .frame(height: settings.showNowPlayingBar ? 56.0 : 0.0)
                    .padding(.top)
            }
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
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                if focusedField == .trackNumber {
                    Button("TagEditor.Tokens.TrackNumber") {
                        tagData.track = "%TRACKNUMBER%"
                    }
                    .buttonStyle(.bordered)
                    .clipShape(RoundedRectangle(cornerRadius: 99))
                }
                Spacer()
                Button("Shared.Done") {
                    focusedField = nil
                }
                .bold()
            }
        }
        .task {
            if !isInitialLoadCompleted {
                await readAllTagData()
                isInitialLoadCompleted = true
            }
        }
        .onChange(of: selectedAlbumArt) { _, _ in
            Task {
                if let selectedAlbumArt = selectedAlbumArt,
                    let data = try? await selectedAlbumArt.loadTransferable(type: Data.self) {
                    tagData.albumArt = data
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
    }

    func readAllTagData() async {
        debugPrint("Attempting to read tag data for \(files.count) files...")
        // Check for common tag data betwen all files
        var tagCombined: TagTyped?
        initialLoadPercentage = 0
        for file in files {
            debugPrint("Attempting to read tag data for file \(file.name)...")
            do {
                let tag = try id3TagEditor.read(from: file.path)
                if let tag = tag {
                    tags.updateValue(tag, forKey: file)
                    let tagContentReader = ID3TagContentReader(id3Tag: tag)
                    if tagCombined == nil {
                        tagCombined = await TagTyped(file, reader: tagContentReader)
                    } else {
                        await tagCombined!.merge(with: file, reader: tagContentReader)
                    }
                }
            } catch {
                debugPrint("Error occurred while reading tags: \n\(error.localizedDescription)")
            }
            initialLoadPercentage += 100 / files.count
        }
        // Load data into view
        if let tagCombined = tagCombined {
            tagData = Tag(from: tagCombined)
        }
    }

    func saveAllTagData() async {
        savePercentage = 0
        _ = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
            for (file, tag) in tags {
                group.addTask {
                    return await tag.saveTagData(to: file, tagData: tagData)
                }
            }
            var saveStates: [Bool] = []
            for await result in group {
                DispatchQueue.main.async {
                    savePercentage += 100 / tags.count
                }
                saveStates.append(result)
            }
            return saveStates
        }
    }

    func changeSaveState(to newState: SaveState) {
        withAnimation(.snappy.speed(2)) {
            saveState = newState
        }
    }

}
