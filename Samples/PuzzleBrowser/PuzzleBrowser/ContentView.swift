//
// ContentView.swift
//
// Created by Imre Mihaly on 2024.
//
// All rights reserved.
//


import SwiftUI
import LichessPuzzleDb

struct ContentView: View {
    @State
    var isSearching: Bool = false
    
    @State
    var result: [Puzzle] = []
    
    @State
    var minRating = "0"
    
    @State
    var maxRating = "3300"

    @State
    var pageLimit = "100"

    @State
    var themes: String = ""
    
    @State
    var page = 0
    
    @State
    var fetchDuration: Double = 0.0
    
    @State
    var dbInstalled = false
    
    
    var body: some View {
        VStack {
            if dbInstalled {
                Header()
                PageHeader()
                HSeparator()
                Content()
                HSeparator()
                Footer()
            } else {
                Text("Puzzle db is not installed.")
            }
        }
        .onAppear {
            if LichessPuzzleDb.installDbIfNeeded() {
                dbInstalled = true
                search()
            }
        }
    }
    
    @ViewBuilder
    func Header() -> some View {
        HStack {
            Group {
                VStack {
                    HStack {
                        Text("min rating:")
                        Spacer()
                    }
                    TextField("", text: $minRating)
#if os(iOS)
                        .padding(.horizontal)
                        .border(.gray)
                        .autocapitalization(.none)
#endif
                }
                .padding(.horizontal)
                VStack {
                    HStack {
                        Text("max rating:")
                        Spacer()
                    }
                    TextField("", text: $maxRating)
#if os(iOS)
                        .padding(.horizontal)
                        .border(.gray)
                        .autocapitalization(.none)
#endif
                }
                .padding(.horizontal)
                VStack {
                    HStack {
                        Text("themes:")
                        Spacer()
                    }
                    TextField("", text: $themes)
#if os(iOS)
                        .padding(.horizontal)
                        .border(.gray)
                        .autocapitalization(.none)
#endif
                }
                .padding(.horizontal)
                VStack {
                    HStack {
                        Text("page limit:")
                        Spacer()
                    }
                    TextField("", text: $pageLimit)
#if os(iOS)
                        .padding(.horizontal)
                        .border(.gray)
                        .autocapitalization(.none)
#endif
                }
                .padding(.horizontal)
            }
            .onSubmit {
                search()
            }

            Button {
                self.search()
            } label: {
                Image(systemName: "magnifyingglass")
            }
            
            Spacer()
        }
        .padding()
    }
    
    @ViewBuilder
    func PageHeader() -> some View {
        HStack {
            Button(action: {
                page -= 1
                search()
            }, label: {
                Image(systemName: "arrow.left.circle")
            })
            .buttonStyle(.borderless)
            .disabled(page == 0)
            
            Text("page: \(page + 1)")

            Button(action: {
                page += 1
                search()
            }, label: {
                Image(systemName: "arrow.right.circle")
            })
            .buttonStyle(.borderless)
            .disabled(result.isEmpty)
            
            Spacer()
        }
        .padding()
    }
    
    @ViewBuilder
    func Content() -> some View {
        if result.isEmpty {
            VStack {
                Spacer()
                if isSearching {
                    ProgressView()
                } else {
                    Text("Nothing to show")
                }
                Spacer()
            }
        } else {
            HStack {
                Text("id")
                    .padding(.horizontal)
                    .frame(width: 100)
                    .multilineTextAlignment(.leading)
                VSeparator()
                Text("rating")
                    .padding(.horizontal)
                    .frame(width: 100)
                    .multilineTextAlignment(.leading)
                VSeparator()
                Text("themes")
                    .padding(.horizontal)
                    .frame(width: 200)
                    .multilineTextAlignment(.leading)
                VSeparator()
                Text("FEN")
                    .padding(.horizontal)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .frame(height: 20.0)
            HSeparator()

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(result.indices, id: \.self) { idx in
                        HStack {
                            Text(result[idx].id)
                                .padding(.horizontal)
                                .frame(width: 100)
                            VSeparator()
                            Text("\(result[idx].rating)")
                                .padding(.horizontal)
                                .frame(width: 100)
                            VSeparator()
                            Text(result[idx].themesAsString)
                                .padding(.horizontal)
                                .frame(width: 200)
                            VSeparator()
                            Text(result[idx].fen)
                                .frame(width: 400)
                                .padding(.horizontal)
                            VSeparator()
                            Text(result[idx].moves.first!)
                                .padding(.horizontal)
                            Spacer()
                        }
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(idx % 2 == 0 ? Color.black : Color.white)
                        .textSelection(.enabled)
                        
                        .background {
                            idx % 2 == 0 ? Color.white : Color.blue.opacity(0.3)
                        }
                        HSeparator()
                    }
                }
            }
        }
    }

    @ViewBuilder
    func Footer() -> some View {
        HStack {
            if !fetchDuration.isZero {
                Text("Fetch duration: \(fetchDuration) seconds")
            } else if isSearching {
                ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .controlSize(.small).tint(.blue)
                .padding(.horizontal)
                
                Text("Fetching...")
            }
            Spacer()
        }
        .padding()
    }

    @ViewBuilder
    func HSeparator() -> some View {
        Color.gray.frame(height: 1)
    }

    @ViewBuilder
    func VSeparator() -> some View {
        Color.gray.frame(width: 1)
    }

    private func search() {
        
        // clear results
        withAnimation {
            self.result = []
            self.fetchDuration = 0.0
            self.isSearching = true
        }
        
        Task {
            var start = Date()
            start = Date()
            
            var ratingRange: ClosedRange<Int>? = nil
            if let m = Int(minRating), let M = Int(maxRating) {
                ratingRange = m...M
            }
            
            var pageLimit: Int? = nil
            if let l = Int(self.pageLimit) {
                pageLimit = l
            }
            
            var offset: Int? = nil
            if let l = pageLimit {
                offset = page * l
            }

            var themeFilter: LichessPuzzleDb.ThemeFilter? = nil
            let themeString = self.themes.trimmingCharacters(in: .whitespaces)
            if !themeString.isEmpty {
                themeFilter = .any(themes: Set(themeString.components(separatedBy: .whitespaces)))
            }

            let res = await LichessPuzzleDb.shared.puzzles(ratingRange: ratingRange,
                                                           themeFilter: themeFilter,
                                                           sort: [.rating(ascending: false)],
                                                           pageSize: pageLimit,
                                                           offset: offset)
            self.fetchDuration = Date().timeIntervalSince(start)
            await MainActor.run {
                withAnimation {
                    self.result = res
                    self.isSearching = false
                }
            }
        }
    }
}

extension Puzzle {
    var themesAsString: String {
        let themes = Array(self.themes)
        return themes.sorted().joined(separator: ", ")
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
