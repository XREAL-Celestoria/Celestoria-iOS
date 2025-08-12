//
//  NotificationsSettingView.swift
//  Celestoria
//
//  Created by Minjun Kim on 8/13/25.
//


//
//  NotificationsSettingView.swift
//  Celestoria
//
//  Created by AI Assistant on 8/12/25.
//

import SwiftUI
import Supabase

struct NotificationsSettingView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        // Creating notification dependencies inline
        // This is a temporary solution - ideally these would be injected
        let supabaseClient = SupabaseClient(
            supabaseURL: Config.supabaseURL,
            supabaseKey: Config.supabaseAnonKey
        )
        
        let notificationRepository = NotificationRepository(supabase: supabaseClient)
        let memoryRepository = MemoryRepository(supabase: supabaseClient)
        let authRepository = AuthRepository(supabase: supabaseClient)
        let mediaRepository = MediaRepository()
        
        let profileUseCase = ProfileUseCase(
            authRepository: authRepository,
            mediaRepository: mediaRepository
        )
        
        let notificationUseCase = NotificationUseCase(
            notificationRepository: notificationRepository,
            profileUseCase: profileUseCase,
            memoryRepository: memoryRepository
        )
        
        NotificationsView(
            notificationUseCase: notificationUseCase,
            appState: appState
        )
    }
}