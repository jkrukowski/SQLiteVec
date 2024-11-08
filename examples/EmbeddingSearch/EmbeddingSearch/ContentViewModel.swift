//
//  ContentViewModel.swift
//  EmbeddingSearch
//
//  Created by Jan Krukowski on 8/22/24.
//

import Dependencies
import Foundation
import OSLog
import Observation
import SwiftUI

let logger = Logger()

@MainActor
final class ContentViewModel: ObservableObject {
    @Published var searchResult = [QueryResult]()
    @Published var dataState = DataState.initial
    @Dependency(\.embeddingDatabase) private var embeddingDatabase
    private var searchTask: Task<Void, any Error>?

    func populateDatabase() async {
        if dataState.isLoading {
            return
        }
        do {
            dataState = .loading
            try await embeddingDatabase.initializeDatabase()
            let texts = try await loadTexts()
            try await embeddingDatabase.store(texts: texts)
            dataState = .loaded
        } catch {
            logger.error("Error: \(error)")
            dataState = .error(error.localizedDescription)
        }
    }

    func search(by text: String) async {
        searchTask?.cancel()
        searchTask = Task {
            do {
                let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if query.isEmpty {
                    searchResult = []
                    return
                }
                if Task.isCancelled {
                    return
                }
                let result = try await embeddingDatabase.querySimilar(to: query)
                searchResult = result.compactMap(QueryResult.init)
            } catch {
                logger.error("Error: \(error)")
            }
        }
    }

    private func loadTexts() async throws -> [String] {
        guard let url = Bundle.main.url(forResource: "sentences", withExtension: "txt") else {
            fatalError("Missing required file in main bundle")
        }
        let task = Task.detached {
            try String(contentsOf: url)
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }
        return try await task.value
    }
}

extension ContentViewModel {
    enum DataState {
        case initial
        case loading
        case loaded
        case error(String)

        var isLoading: Bool {
            switch self {
            case .loading:
                true
            default:
                false
            }
        }
    }
}

struct QueryResult: Hashable, Identifiable {
    let id: Int
    let text: String
    let distance: Double
}

extension QueryResult {
    init?(_ result: [String: any Sendable]) {
        guard let id = result["id"] as? Int else {
            return nil
        }
        guard let text = result["text"] as? String else {
            return nil
        }
        guard let distance = result["distance"] as? Double else {
            return nil
        }
        self.init(id: id, text: text, distance: distance)
    }
}
