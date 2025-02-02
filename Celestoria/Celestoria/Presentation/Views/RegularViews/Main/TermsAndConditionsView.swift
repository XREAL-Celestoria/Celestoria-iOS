//
//  TermsAndConditionsView.swift
//  Celestoria
//
//  Created by Minjun Kim on 2/3/25.
//

import SwiftUI

// NavigationBar와 GradientBorderContainer는 이미 다른 파일에서 선언되었으므로,
// 여기에서는 다시 선언하지 않습니다.

struct TermsAndConditionsView: View {
    @EnvironmentObject var appModel: AppModel
    
    var body: some View {
        GeometryReader { geometry in
            // 메인 컨텐츠 영역 (상단 NavigationBar 아래 시작)
            VStack(spacing: 20) {
                // 네비게이션 바
                NavigationBar(
                    title: "Terms and Conditions",
                    action: {
                        appModel.activeScreen = .login
                    },
                    buttonImageString: "chevron.left"
                )
                .padding(.horizontal, 4)
                .padding(.top, 4)

                Spacer()
                    .frame(height: 0)
                    
                // "Your Agreement" 텍스트가 스크롤 상자와 동일한 너비에 좌측 정렬되도록 수정
                HStack {
                    Text("Your Agreement")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.NebulaWhite)
                    Spacer()
                        .frame(width: 22)
                }
                .frame(width: 826, alignment: .leading)
                
                // 스크롤되는 Terms and Conditions 내용
                ScrollView {
                    Text("""
                    These Terms and Conditions govern the use of this Apple Vision Pro application Celestoria. By downloading and using this Application, you agree to these Terms. If you do not agree, please refrain from using the Application.

                    1. Software License Agreement (EULA)
                    This Application is provided to you by Apple Inc. and the developer Celestoria under a license agreement, not a sale. You are granted a limited, non-exclusive, and non-transferable right to use this Application on your Vision Pro device. You may not modify, redistribute, reverse-engineer, or resell this Application without prior written permission from the Provider. The ownership of this Application remains with the Provider.

                    2. Privacy Policy
                    This Application may collect certain user data, including but not limited to:
                    - Location data, voice input, and usage logs
                    - Device information and interaction data
                    
                    The collected data will be used for the following purposes:
                    - Improving Application performance and user experience
                    - Providing customer support and resolving technical issues
                    - Complying with legal requirements

                    3. Terms of Service
                    Users must not use this Application for illegal activities or any actions that violate Apple's policies. Users must not engage in activities that infringe on the rights of others, including copyright violations or defamatory behavior. The Provider reserves the right to modify, update, or discontinue any part of the Application at any time.

                    4. End User License Agreement (EULA)
                    This Application follows Apple's Standard EULA as outlined in the App Store policies. Users must comply with Apple’s Software License Agreement (SLA) when using the Application. You can review Apple's Standard EULA at the following link:
                    Apple Standard EULA

                    5. Limitation of Liability
                    This Application is provided "as-is", and the Provider makes no warranties regarding its completeness, accuracy, or suitability for a particular purpose. The Provider shall not be liable for any damages, including data loss, device malfunctions, or any indirect damages resulting from the use of this Application.

                    6. Termination of Service and Agreement
                    The Provider may restrict or terminate your access to the Application without prior notice if you violate these Terms. If you no longer wish to use the Application, you may terminate this agreement by deleting the Application from your device.

                    7. Governing Law and Dispute Resolution
                    These Terms are governed by the laws of the jurisdiction where Apple operates its App Store. Any legal disputes will be resolved in accordance with Apple's App Store Terms and Conditions.
                    
                    8. Amendments to Terms and Conditions
                    The Provider may modify these Terms as necessary. Users will be notified of any changes through in-app notifications or on the official website. Continued use of the Application after changes are posted constitutes acceptance of the new Terms.
                    """)
                        .font(.system(size: 17))
                        .foregroundColor(.NebulaWhite)
                        .padding(30)
                }
                .frame(width: 826, height: 386)
                .background(Color.Profile.opacity(0.2))
                .cornerRadius(34.66)
                .overlay(
                    RoundedRectangle(cornerRadius: 34.66)
                        .stroke(Color.NebulaWhite, lineWidth: 1)
                )

                Spacer()
                    .frame(height: 0)

                // 하단 버튼 영역 (Cancel / Agree)
                HStack() {
                    Button(action: {
                        // Cancel 선택 시 로그인 전 화면으로 복귀
                        appModel.activeScreen = .login
                    }) {
                        Text("Cancel")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.NebulaWhite)
                            .frame(width: 400, height: 76)
                            .background(
                                AnyShapeStyle(
                                    Color(hex: "#1B212A")
                                )
                            )
                            .cornerRadius(16)
                    }
                    .buttonStyle(MainButtonStyle())

                    Spacer()
                    
                    Button(action: {
                        // Agree 선택 시 Main 화면으로 전환
                        appModel.hasAcceptedTerms = true
                        appModel.activeScreen = .main
                    }) {
                        Text("Agree")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.NebulaBlack)
                            .frame(width: 400, height: 76)
                            .background(
                                AnyShapeStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.65, green: 0.91, blue: 1),
                                            Color(red: 0.71, green: 0.79, blue: 1)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            )
                            .cornerRadius(16)
                    }
                    .buttonStyle(MainButtonStyle())
                }
                .frame(width: 826)
                
                Spacer()
            }
        }
    }
}

struct TermsAndConditionsView_Previews: PreviewProvider {
    static var previews: some View {
        TermsAndConditionsView()
            .environmentObject(AppModel())
    }
}
