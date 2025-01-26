import SwiftUI
import os
import AVKit

struct MemoryDetailView: View {
    @StateObject private var viewModel: MemoryDetailViewModel
    @Environment(\.dismissWindow) private var dismissWindow
    
    init(memory: Memory) {
        _viewModel = StateObject(wrappedValue: MemoryDetailViewModel(memory: memory))
    }
    
    var body: some View {
        GradientBorderContainer {
            ZStack {
                GeometryReader { geometry in
                    videoPlayerSection
                        .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                    
                    VStack {
                        NavigationBar(
                            title: "Memory Detail",
                            action: {
                                dismissWindow(id: "Memory-Detail")
                            },
                            buttonImageString: "xmark"
                        )
                        .padding(.horizontal, 28)
                        .padding(.top, 28)
                        
                        Spacer()
                        
                        MemoryInfoView(viewModel: viewModel)
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.4)
                            .padding(.bottom, 0)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var videoPlayerSection: some View {
        if let urlString = viewModel.memory.videoURL, let url = URL(string: urlString) {
            CelestoriaVideoPlayerView(videoURL: url)
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(maxWidth: .infinity)
                Text("No Video")
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

struct MemoryInfoView: View {
    @ObservedObject var viewModel: MemoryDetailViewModel
    
    var body: some View {
        ZStack(alignment: .topTrailing) { // ZStack에 alignment 지정
            VisualEffectBlur(style: .systemMaterial)
                .edgesIgnoringSafeArea(.all)
            
            Rectangle()
                .fill(Color.clear)
                .overlay(
                    Color.NebulaBlack.opacity(0.3)
                        .shadow(.inner(color: Color.NebulaWhite.opacity(0.8), radius: 24))
                )
                .edgesIgnoringSafeArea(.all)
            
            // HStack으로 메인 콘텐츠 구성
            HStack(alignment: .top) {
                Image("CardUserProfileImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52, alignment: .leading)
                    .padding(.leading, 60)
                    .padding(.top, 28)
                
                Spacer()
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Seoul")
                            .foregroundColor(.NebulaWhite)
                            .font(.system(size: 12, weight: .medium))
                        
                        Circle()
                            .fill(Color.NebulaWhite.opacity(0.6))
                            .frame(width: 4, height: 4)
                            .padding(.leading, 8)
                        
                        Text(viewModel.formattedDate)
                            .foregroundColor(.NebulaWhite)
                            .font(.system(size: 12, weight: .medium))
                            .padding(.leading, 8)
                        
                        Spacer()
                    }
                    Text(viewModel.memory.title)
                        .foregroundColor(.NebulaWhite)
                        .font(.system(size: 24, weight: .bold))
                        .padding(.top, 0)
                    
                    Text(viewModel.memory.note)
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: 1075, alignment: .topLeading)
                        .padding(.top, 8)
                    
                    Spacer()
                }
                .padding(.leading, 8)
                .padding(.top, 28)
            }
            
            // DeleteButton을 ZStack의 오른쪽 상단에 고정
            Image("DeleteButton")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .padding(.trailing, 56)
                .padding(.top, 32)
        }
    }
}

