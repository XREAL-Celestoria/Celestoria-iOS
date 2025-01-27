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
    @Published var selectedImage: String? // 현재 선택된 starfield(이미지) 이름
    private let spaceCoordinator: SpaceCoordinator
    private let profileUseCase: ProfileUseCase
    let appModel: AppModel

    init(appModel: AppModel, spaceCoordinator: SpaceCoordinator, profileUseCase: ProfileUseCase) {
        self.appModel = appModel
        self.spaceCoordinator = spaceCoordinator
        self.profileUseCase = profileUseCase
        
        // 초기 상태는 (로그인 안됐으면 gray, 됐으면 DB 값)
        if let sfName = appModel.userProfile?.starfield {
            self.selectedImage = sfName
        } else {
            self.selectedImage = StarField.GRAY.imageName
        }
        
        // ⭐ userProfile이 나중에라도 바뀌면, selectedImage 재설정
        Task {
            for await newProfile in appModel.$userProfile.values {
                if let starfieldName = newProfile?.starfield {
                    self.selectedImage = starfieldName
                } else {
                    self.selectedImage = StarField.GRAY.imageName
                }
                Logger.info("GalaxyViewModel observer: userProfile changed to \(String(describing: newProfile?.starfield)) => selectedImage = \(String(describing: self.selectedImage))")
            }
        }
    }

    // GalaxyView에서 이미지 클릭 시 호출
    func selectImage(with imageName: String) {
        // 이미 선택된 이미지이면 무시
        guard selectedImage != imageName else { return }
        selectedImage = imageName
        Logger.info("GalaxyViewModel selectImage: \(imageName)")
    }

    // Save 버튼 클릭 시
    func saveSelectedImage() {
        guard let imageName = selectedImage else { return }
        Logger.info("GalaxyViewModel saveSelectedImage: \(imageName)")
        
        // 비로그인 상태면 갱신 불가 -> 그냥 리턴(원하면 Alert 처리 등)
        guard appModel.userId != nil else {
            Logger.info("GalaxyViewModel: no user -> cannot update DB.")
            return
        }

        Task {
            do {
                // DB의 starfield 업데이트
                let updatedProfile = try await profileUseCase.updateProfile(
                    starfield: imageName
                )
                
                // AppModel에 반영 -> didSet에서 selectedStarfield 업데이트
                appModel.userProfile = updatedProfile
                
                // Immersive 공간 업데이트
                spaceCoordinator.updateBackground(with: imageName)
                
            } catch {
                Logger.error("Failed to update starfield: \(error.localizedDescription)")
            }
        }
    }

    // Save 버튼 활성화 여부
    var isUploadEnabled: Bool {
        // 비로그인 상태는 저장 불가
        guard appModel.userId != nil else { return false }
        // 현재 DB 값과 다를 때만 true
        guard let imageName = selectedImage else { return false }
        if let dbValue = appModel.userProfile?.starfield {
            return imageName != dbValue
        }
        // userProfile.starfield가 없다면(true) → 보통 없을 일은 없지만...
        return true
    }

    // 그리드에서 체크 표시를 위해
    func isSelected(image: String) -> Bool {
        return selectedImage == image
    }
}
