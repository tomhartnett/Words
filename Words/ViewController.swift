//
//  ViewController.swift
//  Words
//
//  Created by Tom Hartnett on 2/16/22.
//

import UIKit

class ViewController: UIViewController {

    private let textField: UITextField = {
        let t = UITextField(frame: .zero)
        t.placeholder = "Search for words"
        t.borderStyle = .roundedRect
        t.returnKeyType = .done
        t.font = UIFont(name: "Courier New Bold", size: 20)
        t.translatesAutoresizingMaskIntoConstraints = false
        return t
    }()

    private let tableView: UITableView = {
        let t = UITableView(frame: .zero)

        t.translatesAutoresizingMaskIntoConstraints = false
        return t
    }()

    private lazy var wordList = WordList()

    override func viewDidLoad() {
        super.viewDidLoad()

        constructView()
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

        return false
    }
}
