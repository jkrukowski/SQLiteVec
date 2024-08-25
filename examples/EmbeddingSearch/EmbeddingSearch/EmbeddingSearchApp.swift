//
//  EmbeddingSearchApp.swift
//  EmbeddingSearch
//
//  Created by Jan Krukowski on 8/22/24.
//

import SQLiteVec
import SwiftUI

@main
struct EmbeddingSearchApp: App {
    init() {
        do {
            try SQLiteVec.initialize()
        } catch {
            fatalError("Cannot initialize `SQLiteVec` due to \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
