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
        resultsSubject.eraseToAnyPublisher()
    }

    private let resultsSubject = PassthroughSubject<[String], Never>()

    private let answerSubject = PassthroughSubject<String, Never>()

    private let exclusionsSubject = PassthroughSubject<String, Never>()

    private let inclusionsSubject = PassthroughSubject<String, Never>()

    private let words: [String]

    private var subscription: AnyCancellable?

    init() {
        guard let url = Bundle.main.url(forResource: "words", withExtension: "json") else {
            fatalError("Word list JSON file not found in app bundle")
        }

        guard let data = try? Data(contentsOf: url) else {
            fatalError("Failed to read file at \(url.path)")
        }

        do {
            words = try JSONDecoder().decode([String].self, from: data)
        } catch {
            fatalError("Failed to decode word list: \(error.localizedDescription)")
        }

        guard !words.isEmpty else {
            fatalError("Word list is empty")
        }

        subscription = Publishers.CombineLatest3(answerSubject, exclusionsSubject, inclusionsSubject)
            .throttle(for: .milliseconds(1000), scheduler: DispatchQueue.global(qos: .background), latest: true)
            .sink(receiveValue: { [weak self] answer, exclusions, inclusions in
                guard let self = self else { return }

                guard !answer.isEmpty || !exclusions.isEmpty || !inclusions.isEmpty else {
                    self.resultsSubject.send([])
                    return
                }

                let dots = String(repeating: ".", count: 5 - answer.count)
                let pattern = "\(answer)\(dots)".lowercased()

                var patternWithExcluded: String = ""
                if !exclusions.isEmpty {
                    pattern.forEach {
                        if $0 == "." {
                            // \b[^abc]t[^abc][^abc]r\b
                            patternWithExcluded.append("[^\(exclusions.lowercased())]")
                        } else {
                            patternWithExcluded.append($0)
                        }
                    }
                } else {
                    patternWithExcluded = pattern
                }

                var filteredWords: [String]
                if patternWithExcluded.isEmpty {
                    filteredWords = self.words
                } else {
                    filteredWords = self.words.filter({
                        $0.lowercased().range(of: "\\b\(patternWithExcluded)\\b", options: .regularExpression) != nil
                    })
                }

                if !exclusions.isEmpty {
                    exclusions.forEach { c in
                        filteredWords.removeAll(where: { $0.contains(c.lowercased()) })
                    }
                }

                if !inclusions.isEmpty {
                    inclusions.forEach { c in
                        filteredWords.removeAll(where: { !$0.contains(c.lowercased()) })
                    }
                }

                self.resultsSubject.send(filteredWords)
            })
    }

    func search(for string: String?, excluding exclusions: String? = nil, including inclusions: String? = nil) {
        answerSubject.send(string ?? "")
        exclusionsSubject.send(exclusions ?? "")
        inclusionsSubject.send(inclusions ?? "")
    }
}
