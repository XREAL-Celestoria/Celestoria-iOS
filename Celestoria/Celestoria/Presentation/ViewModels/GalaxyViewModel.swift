//
//  GalaxyViewModel.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/26/25.
//

import Foundation
import os

@MainActor
class GalaxyViewModel: ObservableObject {
    @Published var selectedImage: String? // 현재 선택된 이미지
    private let spaceCoordinator: SpaceCoordinator
    let appModel: AppModel

    init(appModel: AppModel, spaceCoordinator: SpaceCoordinator) {
        self.appModel = appModel
        self.spaceCoordinator = spaceCoordinator
        // 초기 상태: 랜덤 백그라운드 설정
        self.selectedImage = appModel.randomBackground
    }

    // 이미지 선택
    func selectImage(with imageName: String) {
        // 이미 선택된 배경은 선택 취소 불가
        if selectedImage == imageName {
            return
        }

        // 새로운 이미지 선택
        selectedImage = imageName
    }

    // 선택된 이미지 저장 및 SpaceEntity 업데이트
    func saveSelectedImage() {
        guard let imageName = selectedImage else { return }

        // AppModel의 저장된 배경 업데이트
        if let newStarField = StarField(imageName: imageName) {
            appModel.selectedStarfield = newStarField
        } else {
            Logger(subsystem: "com.yourapp.celestoria", category: "GalaxyViewModel")
                .error("Invalid image name: \(imageName) cannot be converted to StarField.")
            return
        }

        // SpaceCoordinator에서 배경 업데이트
        spaceCoordinator.updateBackground(with: imageName)

        // 저장된 배경으로 selectedImage 동기화
        selectedImage = appModel.selectedStarfield?.imageName
    }

    // Save 버튼 활성화 상태
    var isUploadEnabled: Bool {
        guard let selectedImage = selectedImage else { return false }

        // 현재 선택된 이미지가 저장된 배경과 다를 경우 버튼 활성화
        if let savedBackground = appModel.selectedStarfield?.imageName {
            return selectedImage != savedBackground
        }

        // 초기 랜덤 배경과 다를 경우 버튼 활성화
        return selectedImage != appModel.randomBackground
    }

    // 이미지 선택 상태 확인
    func isSelected(image: String) -> Bool {
        return selectedImage == image
    }
}
