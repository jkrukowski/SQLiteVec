//
//  EmbeddingDatabase.swift
//  EmbeddingSearch
//
//  Created by Jan Krukowski on 8/22/24.
//

import Dependencies
import Foundation
import NaturalLanguage
import Observation
import SQLiteVec

actor EmbeddingDatabase {
    @Dependency(\.database) private var database
    @Dependency(\.embeddingProvider) private var embeddingProvider

    func initializeDatabase() async throws {
        try await database.execute(
            """
                CREATE TABLE IF NOT EXISTS texts(
                  id INTEGER PRIMARY KEY,
                  text TEXT
                );
            """
        )
        try await database.execute(
            """
                CREATE VIRTUAL TABLE IF NOT EXISTS embeddings USING vec0(
                  id INTEGER PRIMARY KEY,
                  embedding float[512]
                );
            """
        )
    }

    func store(texts: [String]) async throws {
        try await database.transaction {
            for text in texts {
                try await store(text: text)
            }
        }
    }

    func store(text: String) async throws {
        guard let vector = embeddingProvider.vector(for: text) else {
            throw EmbeddingDatabase.Error.cannotCreateVector
        }
        try await database.execute(
            """
                INSERT INTO texts(text) VALUES(?);
            """,
            params: [text]
        )
        let lastInsertRowId = await database.lastInsertRowId
        let vectorEmbeddings = vector.map { Float($0) }
        try await database.execute(
            """
                INSERT INTO embeddings(id, embedding)
                VALUES (?, ?);
            """,
            params: [lastInsertRowId, vectorEmbeddings]
        )
    }

    func querySimilar(to text: String, k: Int = 5) async throws -> [[String: Any]] {
        guard let vector = embeddingProvider.vector(for: text) else {
            throw EmbeddingDatabase.Error.cannotCreateVector
        }
        let vectorEmbeddings = vector.map { Float($0) }
        return try await database.query(
            """
                SELECT embeddings.id as id, distance, text
                FROM embeddings
                LEFT JOIN texts ON texts.id = embeddings.id
                WHERE embedding MATCH ? AND k = ?
                ORDER BY distance
            """,
            params: [vectorEmbeddings, k]
        )
    }
}

extension EmbeddingDatabase {
    enum Error: Swift.Error {
        case cannotCreateVector
    }
}
