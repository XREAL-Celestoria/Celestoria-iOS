//
//  AppMemoryDoneViewModel.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/25/25.
//

import SwiftUI

class AddMemoryDoneViewModel: ObservableObject {
    @Published var memoryID: String? 
    
    private let appModel: AppModel
    
    init(appModel: AppModel) {
        self.appModel = appModel
    }
    
    func handleViewMemoryStar() {
        guard let memoryID = memoryID else { return }
        
        // 카메라 이동 및 디테일 뷰 열기
//        appModel.moveToMemory(memoryID: memoryID)
//        appModel.showMemoryDetailView(for: memoryID)
    }
}
