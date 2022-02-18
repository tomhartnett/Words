//
//  WordList.swift
//  Words
//
//  Created by Tom Hartnett on 2/16/22.
//

import Foundation

class WordList {

    @Published var results: [String] = []

    private let words: [String]

    init() {
        guard let url = Bundle.main.url(forResource: "dictionary", withExtension: "txt") else {
            fatalError("Word list not found")
        }

        guard let data = try? Data(contentsOf: url) else {
            fatalError("Failed to read file at \(url.path)")
        }

        let allWords = String(data: data, encoding: .utf8)
        self.words = allWords?.split(separator: "\n").compactMap {
            let word = String($0)
            if word.count == 5 {
                return word
            } else {
                return nil
            }
        } ?? []

        guard !words.isEmpty else {
            fatalError("Word list is empty")
        }
    }

    func search(pattern: String?) {
        guard let input = pattern else {
            results = []
            return
        }

        let characters = input.uppercased().map { $0 }
        let filteredWords = words.filter({
            var containsAllCharacters = true
            for c in characters {
                if c == "." {
                    continue
                }

                if !$0.uppercased().contains(c) {
                    containsAllCharacters = false
                }
            }

            return containsAllCharacters
        })

        /*
         let invitation = "Fancy a game of Cluedo™?"
         invitation.range(of: #"\bClue(do)?™?\b"#,
                          options: .regularExpression) != nil // true
         */

        results = filteredWords
    }
}
