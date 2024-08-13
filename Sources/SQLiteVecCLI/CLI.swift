import SQLiteVec

@main
struct CLI {
    static func main() async throws {
        try SQLiteVec.initialize()
        let data: [(index: Int, vector: [Float])] = [
            (1, [0.1, 0.1, 0.1, 0.1]),
            (2, [0.2, 0.2, 0.2, 0.2]),
            (3, [0.3, 0.3, 0.3, 0.3]),
            (4, [0.4, 0.4, 0.4, 0.4]),
            (5, [0.5, 0.5, 0.5, 0.5]),
        ]
        let query: [Float] = [0.3, 0.3, 0.3, 0.3]
        let db = try Database(.inMemory)
        try await db.execute("CREATE VIRTUAL TABLE vec_items USING vec0(embedding float[4])")
        for row in data {
            try await db.execute(
                """
                    INSERT INTO vec_items(rowid, embedding) 
                    VALUES (?, ?)
                """,
                params: [row.index, row.vector]
            )
        }
        let result = try await db.query(
            """
                SELECT rowid, distance 
                FROM vec_items 
                WHERE embedding MATCH ? 
                ORDER BY distance 
                LIMIT 3
            """,
            params: [query]
        )
        print(result)
    }
}
