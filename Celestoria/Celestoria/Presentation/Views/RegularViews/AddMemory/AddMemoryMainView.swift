//
//  AddMemoryMainView.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/22/25.
//

import SwiftUI
import PhotosUI
import AVFoundation

struct AddMemoryMainView: View {
    @Environment(\.dismissWindow) private var dismissWindow
    @EnvironmentObject var viewModel: AddMemoryMainViewModel
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        VStack {
            // Navigation Bar
            NavigationBar(title: "Add Memory Star", buttonImageString: "xmark", action: {
                appModel.showAddMemoryView = false
                dismissWindow(id: "Add-Memory")
            })

            Spacer()

            // Video Picker
            ZStack {
                Rectangle()
                    .fill(Color(.systemGray6))
                    .cornerRadius(20)
                    .frame(width: 260, height: 132)

                PhotosPicker(selection: $viewModel.selectedVideoItem, matching: .spatialMedia) {
                    VStack {
                        Image("AddMemoryVideoIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                        Text("Select your spatial video")
                            .foregroundColor(.white)
                            .font(.system(size: 17))
                            .padding(.top, 4)
                    }
                    .frame(width: 260, height: 132)
                    .cornerRadius(20)
                }
            }

            Spacer()

            // Save Button
            Button(action: {
                Task {
                    await viewModel.saveMemory(
                        note: "Example Note",
                        title: "Example Title",
                        userId: UUID() // Replace with real user ID
                    )
                }
            }) {
                Text("Save Memory")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding()
        }
        .padding()
        .alert(isPresented: $viewModel.showSuccessAlert) {
            Alert(title: Text("Success"), message: Text("Memory saved successfully!"), dismissButton: .default(Text("OK")))
        }
        .onChange(of: viewModel.errorMessage) { errorMessage in
            if let message = errorMessage {
                print("Error: \(message)")
            }
        }
    }
}
