//
//  MemoryRepository.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Foundation
import Combine
import Supabase

class MemoryRepository {
    private let supabase: SupabaseClient

    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }

    func fetchMemories(for userId: UUID) -> AnyPublisher<[Memory], Error> {
        Future { promise in
            Task {
                do {
                    let response: [Memory] = try await self.supabase
                        .from("memories")
                        .select("*")
                        .eq("user_id", value: userId.uuidString)
                        .execute()
                        .value
                    promise(.success(response))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func createMemory(_ memory: Memory) -> AnyPublisher<Void, Error> {
        Future { promise in
            Task {
                do {
                    try await self.supabase
                        .from("memories")
                        .insert(memory)
                        .execute()
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func deleteMemory(_ memoryId: UUID) -> AnyPublisher<Void, Error> {
        Future { promise in
            Task {
                do {
                    try await self.supabase
                        .from("memories")
                        .delete()
                        .eq("id", value: memoryId.uuidString)
                        .execute()
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
