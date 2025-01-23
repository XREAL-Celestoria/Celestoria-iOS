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
    @EnvironmentObject var viewModel: AddMemoryMainViewModel
    @EnvironmentObject private var appModel: AppModel
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left View
                LeftView()
                    .frame(width: geometry.size.width / 2, height: geometry.size.height)
                
                // Right View
                RightView()
                    .frame(width: geometry.size.width / 2, height: geometry.size.height)
                    .background(
                        Rectangle()
                            .fill(Color.NebulaBlack.shadow(.inner(color: Color.NebulaWhite.opacity(0.2), radius: 24)))
                            .frame(width: geometry.size.width / 2, height: geometry.size.height)
                        )
            
            }
            .background(Color.NebulaBlack)
        }
        // Alert for Success
        .alert(isPresented: $viewModel.showSuccessAlert) {
            Alert(
                title: Text("Success"),
                message: Text("Memory saved successfully!"),
                dismissButton: .default(Text("OK"))
            )
        }
        // Handle Error Messages
        .onChange(of: viewModel.errorMessage) {
            guard let message = viewModel.errorMessage else { return }
            print("Error: \(message)")
        }
    }
}

// MARK: - Left View
private struct LeftView: View {
    @EnvironmentObject var viewModel: AddMemoryMainViewModel
    @Environment(\.dismissWindow) private var dismissWindow
    @EnvironmentObject private var appModel: AppModel
    
    var body: some View {
        VStack {
            // Navigation Bar
            NavigationBar(
                title: "Add Memory Star",
                buttonImageString: "xmark",
                action: {
                    appModel.showAddMemoryView = false
                    dismissWindow(id: "Add-Memory")
                }
            )
            .padding(.horizontal, 28)
            .padding(.top, 28)
            
            Spacer()
            
            // Video Picker
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.clear)
                    .stroke(Color(hex: "9D9D9D"), lineWidth: 2)
                    .frame(width: 260, height: 132)
                
                PhotosPicker(selection: $viewModel.selectedVideoItem, matching: .spatialMedia){
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
                }
                .frame(width: 260, height: 132)
                .cornerRadius(20)
                .background(.clear)
                .buttonStyle(PlainButtonStyle())
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            
            Spacer()
        }
        .background(Color.NebulaBlack)
        
    }
}

// MARK: - Right View
private struct RightView: View {
    @EnvironmentObject var viewModel: AddMemoryMainViewModel
    @EnvironmentObject private var appModel: AppModel
    
    var body: some View {
        VStack(spacing: 24) {
            // Category Section
            Text("Category")
                .foregroundColor(.NebulaWhite)
                .font(.system(size: 22, weight: .bold))
                .padding(.top, 64)
            
            CategoryButtons()
            
            NoteInputSection()
            
            UploadButton {
                Task {
                    await viewModel.saveMemory(
                        note: viewModel.note,
                        title: viewModel.title,
                        userId: appModel.userId
                    )
                }
            }
        }
        .padding()
    }
}

// MARK: - Category Buttons
private struct CategoryButtons: View {
    @EnvironmentObject var viewModel: AddMemoryMainViewModel
    
    var body: some View {
        HStack(spacing: 60) {
            CategoryButton(
                category: Category.PET,
                isSelected: viewModel.selectedCategory == Category.PET,
                action: {
                    viewModel.toggleCategory(Category.PET)
                }
            )
            CategoryButton(
                category: Category.ENTERTAINMENT,
                isSelected: viewModel.selectedCategory == Category.ENTERTAINMENT,
                action: {
                    viewModel.toggleCategory(Category.ENTERTAINMENT)
                }
            )
            CategoryButton(
                category: Category.TRAVEL,
                isSelected: viewModel.selectedCategory == Category.TRAVEL,
                action: {
                    viewModel.toggleCategory(Category.TRAVEL)
                }
            )
            CategoryButton(
                category: Category.FAMILY,
                isSelected: viewModel.selectedCategory == Category.FAMILY,
                action: {
                    viewModel.toggleCategory(Category.FAMILY)
                }
            )
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
    }
}

// MARK: - Note Input Section
private struct NoteInputSection: View {
    @EnvironmentObject var viewModel: AddMemoryMainViewModel
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 36)
                .stroke(Color(hex: "9D9D9D"), lineWidth: 1)
                .frame(width: 560, height: 288)
            
            VStack() {
                // Title Input
                TextField("Write the title", text: $viewModel.title)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(.NebulaWhite)
                    .padding(.top, 28)
                    .frame(width: 504, height: 64, alignment: .bottomLeading)
                
                Divider()
                    .background(Color(hex: "9D9D9D"))
                    .frame(width: 560, height: 1)
                
                // Note Input
                TextField("Write the note", text: $viewModel.note, axis: .vertical)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(.NebulaWhite)
                    .padding(.top, 12)
                    .frame(width: 504, height: 228, alignment: .topLeading)
                
                // Character Count
                Text("\(viewModel.note.count) / 500")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Color(hex: "9D9D9D"))
                    .frame(width: 560, alignment: .trailing)
                    .padding(.top, 4)
            }
        }
    }
}

// MARK: - Upload Button
private struct UploadButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Upload")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.NebulaWhite)
                .frame(width: 380, height: 64)
                .background(Color(hex: "1F1F29").cornerRadius(16))
        }
        .buttonStyle(UploadButtonStyle())
        .padding(.bottom, 60)
    }
}


struct UploadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

