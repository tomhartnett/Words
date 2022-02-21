//
//  WordList.swift
//  Words
//
//  Created by Tom Hartnett on 2/16/22.
//

import Combine
import Foundation

class WordList {

    var results: AnyPublisher<[String], Never> {
        _results.eraseToAnyPublisher()
    }

    private let _results = PassthroughSubject<[String], Never>()

    private let _answer = CurrentValueSubject<String, Never>("")

    private let _exclusions = CurrentValueSubject<String, Never>("")

    private let words: [String]

    private var subscription: AnyCancellable?

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

        subscription = Publishers.CombineLatest(_answer, _exclusions)
            .dropFirst()
            .throttle(for: .milliseconds(1500), scheduler: DispatchQueue.global(qos: .background), latest: true)
            .sink(receiveValue: { [weak self] answer, exclusions in
                guard let self = self else { return }

                guard !answer.isEmpty, answer.count <= 5, answer.first(where: { $0 != "." }) != nil else {
                    self._results.send([])
                    return
                }

                let dots = String(repeating: ".", count: 5 - answer.count)
                let pattern = "\(answer)\(dots)".lowercased()

                var patternWithExcluded: String = ""
                if !exclusions.isEmpty {
                    pattern.forEach {
                        if $0 == "." {
                            // \b[^uo]t..r\b
                            patternWithExcluded.append("[^\(exclusions.lowercased())]")
                        } else {
                            patternWithExcluded.append($0)
                        }
                    }
                } else {
                    patternWithExcluded = pattern
                }

                let filteredWords = self.words.filter({
                    $0.lowercased().range(of: "\\b\(patternWithExcluded)\\b", options: .regularExpression) != nil
                })

                self._results.send(filteredWords)
            })
    }

    func search(for string: String?, excluding exclusions: String? = nil) {
        _answer.value = string ?? ""
        _exclusions.value = exclusions ?? ""
    }
}
