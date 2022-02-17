//
//  WordList.swift
//  Words
//
//  Created by Tom Hartnett on 2/16/22.
//

import Foundation

class WordList {

    private let words: [String]

    init() {
        guard let url = Bundle.main.url(forResource: "dictionary", withExtension: "txt") else {
            fatalError("Word list not found")
        }

        guard let data = try? Data(contentsOf: url) else {
            fatalError("Failed to read file at \(url.path)")
        }

        let allWords = String(data: data, encoding: .utf8)
        self.words = allWords?.split(separator: "\n").map { String($0) } ?? []

        guard !words.isEmpty else {
            fatalError("Word list is empty")
        }
    }

    func search(pattern: String) -> [NSAttributedString] {
        return []
    }
}
