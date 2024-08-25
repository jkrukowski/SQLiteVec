//
//  ContentView.swift
//  EmbeddingSearch
//
//  Created by Jan Krukowski on 8/22/24.
//

import Dependencies
import SwiftUI

@MainActor
struct ContentView: View {
    @State private var searchText = ""
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        VStack {
            switch viewModel.dataState {
            case .initial:
                Button("Load data") {
                    Task {
                        await viewModel.populateDatabase()
                    }
                }
            case .loading:
                ProgressView()
            case .loaded:
                NavigationStack {
                    VStack {
                        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Search to see the results")
                        } else {
                            ScrollView {
                                LazyVStack(alignment: .leading) {
                                    ForEach(viewModel.searchResult) { item in
                                        VStack(alignment: .leading) {
                                            Text(item.text)
                                            Text(item.distance, format: .number.precision(.fractionLength(2)))
                                                .font(.footnote)
                                                .foregroundStyle(.gray)
                                        }
                                        .padding([.top, .leading, .trailing])
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("Search")
                    .searchable(text: $searchText)
                    .onChange(of: searchText) { _, _ in
                        Task {
                            await viewModel.search(by: searchText)
                        }
                    }
                }
            case let .error(error):
                Text("Error \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
}
