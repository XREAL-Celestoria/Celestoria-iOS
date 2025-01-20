//
//  DIContainer.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/16/25.
//

// 의존성을 관리하고 주입, 객체 생성 및 관리
import Foundation
import Supabase

@MainActor
final class DIContainer: ObservableObject {
    static let shared = DIContainer()
    // ViewModels
    let mainViewModel: MainViewModel
    let spaceCoordinator: SpaceCoordinator
    let appModel: AppModel

    // Supabase Client
    let supabaseClient: SupabaseClient

    // Repositories
    private let memoryRepository: MemoryRepository

    init() {
        // Initialize Supabase Client
        self.supabaseClient = SupabaseClient(
            supabaseURL: Config.supabaseURL,
            supabaseKey: Config.supabaseAnonKey
        )

        // Initialize Repositories
        self.memoryRepository = MemoryRepository(supabase: supabaseClient)

        // Initialize ViewModels and Coordinators
        self.mainViewModel = MainViewModel(
            fetchMemoriesUseCase: FetchMemoriesUseCase(memoryRepository: memoryRepository),
            createMemoryUseCase: CreateMemoryUseCase(memoryRepository: memoryRepository),
            deleteMemoryUseCase: DeleteMemoryUseCase(memoryRepository: memoryRepository)
        )
        self.spaceCoordinator = SpaceCoordinator()
        self.appModel = AppModel() // 명시적으로 필요한 데이터만 전달
    }
}
