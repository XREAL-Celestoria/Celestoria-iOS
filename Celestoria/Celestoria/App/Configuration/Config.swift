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
        if let value = Bundle.main.object(forInfoDictionaryKey: key) as? String {
            print("✅ [DEBUG] \(key) = \(value)")
            return value
        } else {
            print("❌ [DEBUG] Info.plist에 \(key) 없음")
            fatalError("❌ Info.plist에서 \(key)를 찾을 수 없습니다.")
        }
    }
}
