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

    func search(for string: String?, excluding excludedCharacters: String? = nil) {
        guard let string = string?.lowercased(), !string.isEmpty, string.count <= 5 else {
            results = []
            return
        }

        let dots = String(repeating: ".", count: 5 - string.count)
        let pattern = "\(string)\(dots)"

        var patternWithExcluded: String = ""
        if let excludedCharacters = excludedCharacters, !excludedCharacters.isEmpty {
            pattern.forEach {
                if $0 == "." {
                    // \b[^uo]t..r\b
                    patternWithExcluded.append("[^\(excludedCharacters.lowercased())]")
                } else {
                    patternWithExcluded.append($0)
                }
            }
        } else {
            patternWithExcluded = pattern
        }

        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
            let filteredWords = self.words.filter({
                $0.lowercased().range(of: "\\b\(patternWithExcluded)\\b", options: .regularExpression) != nil
            })

            self.results = filteredWords
        }
    }
}
