//
//  ViewController.swift
//  Words
//
//  Created by Tom Hartnett on 2/16/22.
//

import Combine
import UIKit

class ViewController: UIViewController {

    private enum Section {
        case words
    }

    private let stackView: UIStackView = {
        let s = UIStackView(frame: .zero)
        s.axis = .vertical
        s.spacing = 16
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let answerTextField: UITextField = {
        let t = UITextField(frame: .zero)
        t.placeholder = "Search for words"
        t.borderStyle = .roundedRect
        t.returnKeyType = .done
        t.autocapitalizationType = .none
        t.autocorrectionType = .no
        t.clearButtonMode = .always
        t.font = UIFont(name: "Courier New Bold", size: 20)
        t.translatesAutoresizingMaskIntoConstraints = false
        return t
    }()

    private let excludedTextField: UITextField = {
        let t = UITextField(frame: .zero)
        t.placeholder = "Excluding letters"
        t.borderStyle = .roundedRect
        t.returnKeyType = .done
        t.autocapitalizationType = .none
        t.autocorrectionType = .no
        t.clearButtonMode = .always
        t.font = UIFont(name: "Courier New Bold", size: 20)
        t.translatesAutoresizingMaskIntoConstraints = false
        return t
    }()

    private let tableView: UITableView = {
        let t = UITableView(frame: .zero)
        t.allowsSelection = false
        t.translatesAutoresizingMaskIntoConstraints = false
        return t
    }()

    private var dataSource: UITableViewDiffableDataSource<Section, String>?

    private lazy var wordList = WordList()

    private var subsciptions = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        constructView()

        configureTable()

        wordList.$results
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [unowned self] words in
                var snapshot = NSDiffableDataSourceSnapshot<Section, String>()
                snapshot.appendSections([.words])
                snapshot.appendItems(words)
                self.dataSource?.apply(snapshot, animatingDifferences: false)
            })
            .store(in: &subsciptions)
    }

    private func constructView() {
        let backgroundColor = UIColor(named: "Parchment")
        view.backgroundColor = backgroundColor
        answerTextField.backgroundColor = backgroundColor
        excludedTextField.backgroundColor = backgroundColor
        tableView.backgroundColor = backgroundColor

        answerTextField.delegate = self
        excludedTextField.delegate = self

        stackView.addArrangedSubview(answerTextField)
        stackView.addArrangedSubview(excludedTextField)
        stackView.addArrangedSubview(tableView)
        view.addSubview(stackView)

        let margin: CGFloat = 16

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: margin),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: margin),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -margin),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func configureTable() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
        dataSource = UITableViewDiffableDataSource<Section, String>(tableView: tableView) { t, indexPath, word in
            let cell = t.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)

            var content = cell.defaultContentConfiguration()
            content.text = word
            if let font = UIFont(name: "Courier New", size: 20) {
                content.textProperties.font = font
            }

            cell.contentConfiguration = content
            cell.backgroundColor = .clear

            return cell
        }
    }

    private func handleAnswerInput(currentText: String?, input: Character, range: NSRange) -> String? {
        return nil
    }
}

extension ViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String)
    -> Bool {

        // Allow deletions
        if string == "" {
            if let text = textField.text,
               let textRange = Range(range, in: text) {
                textField.text = text.replacingCharacters(in: textRange,
                                                          with: string)
            }
            wordList.search(for: answerTextField.text, excluding: excludedTextField.text)
            return false
        }

        // Dismiss keyboard
        if string == "\n" {
            textField.resignFirstResponder()
            return false
        }

        // Prevent pasting into text field
        if string.count > 1 {
            return false
        }

        // Not sure what would fail here, but need Character
        guard let character = string.first else {
            return false
        }

        if textField === answerTextField {
            // Only allow letters, space, and period `.`
            guard character.isLetter || character == " " || character == "." else {
                return false
            }
        } else {
            // Only allow letters in excluded characters field
            guard character.isLetter else {
                return false
            }
        }

        let newReplacementString: String
        if character.isLetter || character == "." {
            newReplacementString = string
        } else {
            newReplacementString = "."
        }

        if let text = textField.text,
           let textRange = Range(range, in: text) {
            textField.text = text.replacingCharacters(in: textRange,
                                                      with: newReplacementString)
        }

        wordList.search(for: answerTextField.text, excluding: excludedTextField.text)

        return false
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if textField === answerTextField {
            answerTextField.text = ""
        } else {
            excludedTextField.text = ""
        }

        wordList.search(for: answerTextField.text, excluding: excludedTextField.text)

        return false
    }
}

private extension UITableViewCell {
    static var reuseIdentifier: String {
        return "WordCell"
    }
}
