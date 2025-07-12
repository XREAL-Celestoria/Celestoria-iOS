
//
//  iPhoneContentView.swift
//  Celestoria (iPhone Target)
//
//  Created by YourName on 2025/07/12.
//

import SwiftUI

struct iPhoneContentView: View {
    // AppModel, MainViewModel, LoginViewModel 등을 environmentObject로 받아서 사용합니다.
    // 현재는 테스트용이므로 간단하게 Text만 표시합니다.
    // @EnvironmentObject var appModel: AppModel
    // @EnvironmentObject var mainViewModel: MainViewModel
    // @EnvironmentObject var loginViewModel: LoginViewModel

    var body: some View {
        VStack {
            Image(systemName: "iphone.gen2.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .foregroundColor(.blue)
                .padding(.bottom, 20)

            Text("Hello, Celestoria on iPhone!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 10)

            Text("This is your iPhone-specific content view.")
                .font(.headline)
                .foregroundColor(.gray)

            Spacer()
        }
        .padding()
        .navigationTitle("iPhone App") // iPhone에서는 UINavigationBarTitle로 표시됩니다.
    }
}

// MARK: - Previews (선택 사항: 필요한 경우 주석 해제)
// #Preview {
//     iPhoneContentView()
//         // .environmentObject(AppModel()) // 프리뷰를 위해 필요한 경우 주입
//         // .environmentObject(MainViewModel(fetchMemoriesUseCase: DummyFetchMemoriesUseCase(), deleteMemoryUseCase: DummyDeleteMemoryUseCase(), spaceCoordinator: DummySpaceCoordinator()))
//         // .environmentObject(LoginViewModel(signInUseCase: DummySignInWithAppleUseCase(), profileUseCase: DummyProfileUseCase(), appModel: AppModel()))
// }
