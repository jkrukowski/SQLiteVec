//
//  Dependencies.swift
//  EmbeddingSearch
//
//  Created by Jan Krukowski on 8/22/24.
//

import Dependencies
import Foundation
import NaturalLanguage
import SQLiteVec

protocol EmbeddingProvider {
    func vector(for string: String) -> [Double]?
}

extension NLEmbedding: EmbeddingProvider {}

private enum EmbeddingProviderKey: DependencyKey {
    static let liveValue: any EmbeddingProvider = NLEmbedding.sentenceEmbedding(for: .english)!
}

private enum DatabaseProviderKey: DependencyKey {
    static let liveValue: Database = try! Database(.inMemory)
}

private enum EmbeddingDatabaseProviderKey: DependencyKey {
    static let liveValue: EmbeddingDatabase = .init()
}

extension DependencyValues {
    var embeddingProvider: any EmbeddingProvider {
        get { self[EmbeddingProviderKey.self] }
        set { self[EmbeddingProviderKey.self] = newValue }
    }

    var database: Database {
        get { self[DatabaseProviderKey.self] }
        set { self[DatabaseProviderKey.self] = newValue }
    }

    var embeddingDatabase: EmbeddingDatabase {
        get { self[EmbeddingDatabaseProviderKey.self] }
        set { self[EmbeddingDatabaseProviderKey.self] = newValue }
    }
}
