//
//  AddMemoryMainViewModel.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/23/25.
//

import Foundation
import Combine
import SwiftUI
import PhotosUI

@MainActor
class AddMemoryMainViewModel: ObservableObject {
    private let createMemoryUseCase: CreateMemoryUseCase
    
    @Published var showSuccessAlert = false
    @Published var errorMessage: String?
    @Published var selectedCategory: Category?
    @Published var selectedVideoItem: PhotosPickerItem?
    @Published var thumbnailImage: UIImage?
    @Published var isUploading = false
    
    @Published var title: String = ""
    @Published var note: String = "" {
        didSet {
            if note.count > 500 {
                note = String(note.prefix(500))
            }
        }
    }
    
    init(createMemoryUseCase: CreateMemoryUseCase) {
        self.createMemoryUseCase = createMemoryUseCase
    }
    
    func saveMemory(note: String, title: String, userId: UUID) async {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "타이틀을 입력해주세요."
            return
        }
        
        guard let videoItem = selectedVideoItem else {
            errorMessage = "비디오를 선택해주세요."
            return
        }
        
//        guard let category = selectedCategory else {
//            errorMessage = "카테고리를 선택해주세요."
//            return
//        }
        
        isUploading = true // 업로드 시작 상태 표시
        defer { // 작업 종료 후 반드시 실행
            isUploading = false
        }
        
        do {
            // 비디오 데이터 로드
            guard let videoData = try await videoItem.loadTransferable(type: Data.self) else {
                errorMessage = "비디오 데이터를 불러올 수 없습니다."
                return
            }
            
            // 메모리 생성 실행
            let memory = try await createMemoryUseCase.execute(
                note: note,
                title: title,
                category: .ENTERTAINMENT,
//                category: category,
                videoData: videoData,
                thumbnailImage: thumbnailImage,
                userId: userId
            )
            
            showSuccessAlert = true
            print("메모리 생성 완료: \(memory)")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
