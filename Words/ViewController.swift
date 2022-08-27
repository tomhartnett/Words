//
//  ViewController.swift
//  Words
//
//  Created by Tom Hartnett on 2/16/22.
//

import Combine
import UIKit

class ViewController: UIViewController {

    private let answerView: AnswerView = {
        let a = AnswerView(frame: .zero)
        a.translatesAutoresizingMaskIntoConstraints = false
        return a
    }()

    private let stackView: UIStackView = {
        let s = UIStackView(frame: .zero)
        s.axis = .vertical
        s.spacing = 16
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let exclusionsTextField: UITextField = {
        let t = UITextField(frame: .zero)
        t.backgroundColor = UIColor(named: "Parchment")
        t.placeholder = "Excluding letters"
        t.borderStyle = .roundedRect
        t.returnKeyType = .done
        t.autocapitalizationType = .none
        t.autocorrectionType = .no
        t.spellCheckingType = .no
        t.clearButtonMode = .always
        t.font = UIFont.monospacedSystemFont(ofSize: 20, weight: .bold)
        t.translatesAutoresizingMaskIntoConstraints = false
        return t
    }()

    private let inclusionsTextField: UITextField = {
        let t = UITextField(frame: .zero)
        t.backgroundColor = UIColor(named: "Parchment")
        t.placeholder = "Must include letters"
        t.borderStyle = .roundedRect
        t.returnKeyType = .done
        t.autocapitalizationType = .none
        t.autocorrectionType = .no
        t.spellCheckingType = .no
        t.clearButtonMode = .always
        t.font = UIFont.monospacedSystemFont(ofSize: 20, weight: .bold)
        t.translatesAutoresizingMaskIntoConstraints = false
        return t
    }()

    private let resultsLabel: UILabel = {
        let l = UILabel(frame: .zero)
        l.font = UIFont.monospacedSystemFont(ofSize: 18, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let tableView: UITableView = {
        let t = UITableView(frame: .zero)
        t.backgroundColor = UIColor(named: "Parchment")
        t.allowsSelection = false
        t.translatesAutoresizingMaskIntoConstraints = false
        return t
    }()

    private let clearButton: UIButton = {
        let b = UIButton()
        let title = NSAttributedString(
            string: "Clear",
            attributes: [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue]
        )
        b.setAttributedTitle(title, for: .normal)
        b.titleLabel?.font = UIFont.monospacedSystemFont(ofSize: 15, weight: .semibold)
        b.tintColor = UIColor.darkText
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private var dataSource: ResultsDataSource?

    private lazy var wordList = WordList()

    private var subsciptions = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        constructView()

        configureTable()

        wordList.results
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [unowned self] words in
                let count = words.count
                if count == 1 {
                    resultsLabel.text = "\(count) word"
                } else {
                    resultsLabel.text = "\(count) words"
                }

                var snapshot = NSDiffableDataSourceSnapshot<Section, String>()
                snapshot.appendSections([.words])
                snapshot.appendItems(words)
                self.dataSource?.apply(snapshot, animatingDifferences: false)
            })
            .store(in: &subsciptions)

        search()
    }

    private func constructView() {

        view.backgroundColor = UIColor(named: "Parchment")

        answerView.delegate = self

        exclusionsTextField.delegate = self

        inclusionsTextField.delegate = self

        clearButton.addTarget(self, action: #selector(didTapClear), for: .touchUpInside)

        let hstack = UIStackView()
        hstack.axis = .horizontal
        hstack.addArrangedSubview(resultsLabel)
        hstack.addArrangedSubview(UIView())
        hstack.addArrangedSubview(clearButton)

        stackView.addArrangedSubview(exclusionsTextField)
        stackView.addArrangedSubview(inclusionsTextField)
        stackView.addArrangedSubview(hstack)
        view.addSubview(answerView)
        view.addSubview(stackView)
        view.addSubview(tableView)

        let margin: CGFloat = 16

        NSLayoutConstraint.activate([
            answerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: margin),
            answerView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            answerView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: answerView.bottomAnchor, constant: margin),
            stackView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: margin),
            tableView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func configureTable() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
        dataSource = ResultsDataSource(tableView: tableView) { t, indexPath, word in
            let cell = t.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)

            var content = cell.defaultContentConfiguration()
            content.text = word
            content.textProperties.font = UIFont.monospacedSystemFont(ofSize: 20, weight: .regular)

            cell.contentConfiguration = content
            cell.backgroundColor = .clear

            return cell
        }
    }

    private func search() {
        wordList.search(for: answerView.answer,
                        excluding: exclusionsTextField.text,
                        including: inclusionsTextField.text)
    }

    @objc
    private func didTapClear() {
        answerView.clear()
        exclusionsTextField.text = ""
        inclusionsTextField.text = ""
        search()
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

            search()

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

        // Only allow letters in excluded characters field
        guard character.isLetter else {
            return false
        }

        if let text = textField.text,
           let textRange = Range(range, in: text) {
            textField.text = text.replacingCharacters(in: textRange,
                                                      with: string.uppercased())
        }

        search()

        return false
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        textField.text = ""
        search()
        return false
    }
}

extension ViewController: AnswerViewDelegate {
    func answerDidChange(_ answer: String) {
        search()
    }
}

private extension UITableViewCell {
    static var reuseIdentifier: String {
        return "WordCell"
    }
}

private enum Section {
    case words
}

private typealias ResultsDataSource = UITableViewDiffableDataSource<Section, String>
