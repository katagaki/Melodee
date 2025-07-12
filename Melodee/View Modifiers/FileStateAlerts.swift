//
//  FileStateAlerts.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2025/07/12.
//

import SwiftUI

struct FileStateAlerts: ViewModifier {

    @Environment(\.colorScheme) var colorScheme
    @Environment(FilesystemManager.self) var fileManager

    @State var state: FBState
    var refreshFiles: () -> Void

    func body(content: Content) -> some View {
        content
            .alert("Alert.RenameFile.Title", isPresented: $state.isRenamingFile, actions: {
                TextField("Shared.NewFileName", text: $state.newFileName)
                Button("Shared.Change") {
                    if let fileBeingRenamed = state.fileBeingRenamed {
                        fileManager.rename(file: fileBeingRenamed, newName: state.newFileName)
                        refreshFiles()
                    }
                }
                .disabled(state.newFileName == "")
                Button("Shared.Cancel", role: .cancel) {
                    state.fileBeingRenamed = nil
                }
            })
            .alert("Alert.RenameDirectory.Title", isPresented: $state.isRenamingDirectory, actions: {
                TextField("Shared.NewDirectoryName", text: $state.newDirectoryName)
                Button("Shared.Change") {
                    if let directoryBeingRenamed = state.directoryBeingRenamed {
                        fileManager.rename(directory: directoryBeingRenamed,
                                                    newName: state.newDirectoryName)
                        refreshFiles()
                    }
                }
                .disabled(state.newDirectoryName == "")
                Button("Shared.Cancel", role: .cancel) {
                    state.directoryBeingRenamed = nil
                }
            })
            .alert("Alert.ExtractingZIP.Error.Title", isPresented: $state.isErrorAlertPresenting, actions: {
                Button("Shared.OK", role: .cancel) { }
            }, message: {
                Text(verbatim: state.errorText)
            })
            .alert("Alert.DeleteFile.Title", isPresented: $state.isDeletingFileOrDirectory, actions: {
                Button("Shared.Yes", role: .destructive) {
                    if let fileOrDirectoryBeingDeleted = state.fileOrDirectoryBeingDeleted {
                        fileManager.delete(fileOrDirectoryBeingDeleted)
                        refreshFiles()
                    }
                }
                Button("Shared.No", role: .cancel) {
                    state.fileOrDirectoryBeingDeleted = nil
                }
            }, message: {
                Text(NSLocalizedString("Alert.DeleteFile.Text", comment: "")
                    .replacingOccurrences(of: "%1", with: state.fileOrDirectoryBeingDeleted?.name ?? ""))
            })
    }
}

extension View {
    func fileStateAlerts(state: FBState, refreshFiles: @escaping () -> Void) -> some View {
        self.modifier(FileStateAlerts(state: state, refreshFiles: refreshFiles))
    }
}
