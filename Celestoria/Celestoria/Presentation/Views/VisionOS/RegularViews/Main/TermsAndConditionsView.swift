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
                    These Terms and Conditions govern the use of the Celestoria application ("Application") for Apple Vision Pro. By downloading and using this Application, you agree to be bound by these Terms. If you do not agree, please do not use the Application.

                    1. Software License  
                    This Application is provided to you under a limited, non-exclusive, and non-transferable license. You are granted the right to use the Application on your Vision Pro device. Modification, redistribution, reverse-engineering, or resale of this Application is prohibited without prior written consent from the provider.

                    2. Privacy Policy  
                    The Application may collect user data (e.g., location data, voice input, usage logs, device information, and interaction data) to improve performance, provide support, and comply with legal requirements. Please review our complete Privacy Policy for further details.

                    3. User-Generated Content and Community Guidelines  
                        a. Content Submission and Responsibility:  
                            Users are permitted to create and share content ("User-Generated Content"). By submitting content, you agree that it must not contain objectionable, abusive, or otherwise inappropriate material.
                        
                        b. Content Moderation:  
                            - Administrator Review: Administrators review newly submitted content twice daily.  
                            - User Reporting: If a post is reported by one or more users, it is reviewed within one hour. Posts receiving three or more reports are automatically blocked pending further review.
                            
                        c. User Conduct and Blocking:  
                            Users are required to conduct themselves respectfully. The Application provides an option to block abusive users. The provider reserves the right to remove content and suspend or terminate access for any user who violates these guidelines.
                            
                        d. Prompt Action:  
                            All reports of objectionable content are addressed within 24 hours. Appropriate actions include removal of content and ejection of the offending user from the Application.

                    4. Terms of Service  
                    The Application must not be used for illegal activities or to infringe on the rights of others. The provider reserves the right to update or discontinue any part of the Application at any time.

                    5. Limitation of Liability  
                    The Application is provided "as-is" without warranties of any kind. The provider is not liable for any damages resulting from the use of this Application.

                    6. Termination  
                    The provider may restrict or terminate access to the Application at any time if these Terms are violated. Users may terminate their use by deleting the Application.

                    7. Governing Law  
                    These Terms are governed by the laws applicable to Apple’s App Store. Any disputes will be resolved in accordance with Apple’s policies.

                    8. Amendments  
                    The provider may modify these Terms as necessary. Users will be notified of changes via in-app notifications or on our official website. Continued use of the Application signifies acceptance of the updated Terms.
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
