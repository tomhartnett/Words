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

    private let textField: UITextField = {
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
        textField.backgroundColor = backgroundColor
        tableView.backgroundColor = backgroundColor

        textField.delegate = self

        view.addSubview(textField)
        view.addSubview(tableView)

        let margin: CGFloat = 16

        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: margin),
            textField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: margin),
            textField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -margin),
            tableView.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: margin),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: margin),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -margin),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
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
            wordList.search(for: textField.text)
            return true
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

        // Only allow letters, space, and period `.`
        guard character.isLetter || character == " " || character == "." else {
            return false
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

        wordList.search(for: textField.text)

        return false
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        wordList.search(for: nil)
        return true
    }
}

private extension UITableViewCell {
    static var reuseIdentifier: String {
        return "WordCell"
    }
}
