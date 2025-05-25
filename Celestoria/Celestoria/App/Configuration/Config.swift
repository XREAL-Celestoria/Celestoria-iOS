//
//  Config.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Foundation

enum Config {
    // 앱 메타정보
    static let appName = "Celestoria"
    static let version = "1.0"
    
    // 민감 정보 (Info.plist에서 불러옴)
    static var b2KeyID: String { getPlistValue("B2_KEY_ID") }
    static var b2ApplicationKey: String { getPlistValue("B2_APPLICATION_KEY") }
    static var b2BucketId: String { getPlistValue("B2_BUCKET_ID") }
    static var bucketName: String { getPlistValue("BUCKET_NAME") }
    
    static var cloudflareDomain: String {
        let domain = getPlistValue("CLOUDFLARE_DOMAIN")
        let full = "https://\(domain)"
        print("☁️ [DEBUG] Cloudflare domain: \(full)")
        return full
    }
    
    static var supabaseURL: URL {
        let host = getPlistValue("SUPABASE_HOST")
        let urlString = "https://\(host)"
        print("🌐 [DEBUG] Reconstructed URL: \(urlString)")
        guard let url = URL(string: urlString) else {
            fatalError("❌ URL 변환 실패: \(urlString)")
        }
        return url
    }
    
    static var supabaseAnonKey: String {
        getPlistValue("SUPABASE_ANON_KEY")
    }
    
    // Info.plist에서 값을 불러오는 공통 함수
    private static func getPlistValue(_ key: String) -> String {
        let bundle = Bundle.main
        
        // Info.plist 경로 및 상태 확인
        if let path = bundle.path(forResource: "Info", ofType: "plist") {
            print("📄 Info.plist path: \(path)")
        } else {
            print("❌ Info.plist 파일을 찾을 수 없습니다.")
        }
        
        // 전체 Info.plist 딕셔너리 키 확인
        if let allInfo = bundle.infoDictionary {
            print("📦 Info.plist keys available: \(Array(allInfo.keys))")
        } else {
            print("❌ Info.plist 전체 딕셔너리를 가져올 수 없습니다.")
        }
        
        // 실제 값 가져오기
        if let value = bundle.object(forInfoDictionaryKey: key) as? String {
            print("✅ [DEBUG] \(key) = \(value)")
            return value
        } else {
            print("❌ [DEBUG] Info.plist에서 '\(key)' 키를 찾을 수 없습니다.")
            fatalError("❌ Info.plist에서 '\(key)' 키를 찾을 수 없습니다.")
        }
    }
}
