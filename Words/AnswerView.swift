//
//  AnswerView.swift
//  Words
//
//  Created by Tom Hartnett on 6/5/22.
//

import UIKit

protocol AnswerViewDelegate: AnyObject {
    func answerDidChange(_ answer: String)
}

class AnswerView: UIView {

    weak var delegate: AnswerViewDelegate?

    var answer: String {
        let letter1 = textField1.value
        let letter2 = textField2.value
        let letter3 = textField3.value
        let letter4 = textField4.value
        let letter5 = textField5.value

        return "\(letter1)\(letter2)\(letter3)\(letter4)\(letter5)"
    }

    private let answersStackView: UIStackView = {
        let s = UIStackView(frame: .zero)
        s.axis = .horizontal
        s.spacing = 5
        s.distribution = .equalSpacing
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let textField1: AnswerLetterTextField = {
        return AnswerLetterTextField.makeTextField()
    }()

    private let textField2: AnswerLetterTextField = {
        return AnswerLetterTextField.makeTextField()
    }()

    private let textField3: AnswerLetterTextField = {
        return AnswerLetterTextField.makeTextField()
    }()

    private let textField4: AnswerLetterTextField = {
        return AnswerLetterTextField.makeTextField()
    }()

    private let textField5: AnswerLetterTextField = {
        return AnswerLetterTextField.makeTextField()
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        constructView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(:NSCoder) is not implemented")
    }

    func clear() {
        textField1.text = ""
        textField2.text = ""
        textField3.text = ""
        textField4.text = ""
        textField5.text = ""
    }

    private func constructView() {
        addSubview(answersStackView)

        [textField1, textField2, textField3, textField4, textField5].forEach {
            answersStackView.addArrangedSubview($0)
            $0.delegate = self
        }

        NSLayoutConstraint.activate([
            answersStackView.topAnchor.constraint(equalTo: topAnchor),
            answersStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            answersStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            answersStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

extension AnswerView: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Allow deletions
        if string == "" {
            if let text = textField.text,
               let textRange = Range(range, in: text) {
                textField.text = text.replacingCharacters(in: textRange,
                                                          with: string)

                delegate?.answerDidChange(answer)
            }

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

        guard character.isLetter else {
            return false
        }

        textField.text = string.uppercased()

        delegate?.answerDidChange(answer)

        return false
    }
}

private class AnswerLetterTextField: UITextField {
    override var intrinsicContentSize: CGSize {
        CGSize(width: 62, height: 62)
    }

    var value: String {
        let textValue = text ?? ""
        return textValue.isEmpty ? "." : textValue
    }

    static func makeTextField() -> AnswerLetterTextField {
        let t = AnswerLetterTextField(frame: .zero)
        t.autocorrectionType = .no
        t.autocapitalizationType = .none
        t.backgroundColor = UIColor(named: "Parchment")
        t.borderStyle = .roundedRect
        t.clearButtonMode = .never
        t.font = UIFont.systemFont(ofSize: 48)
        t.returnKeyType = .done
        t.textAlignment = .center
        return t
    }
}
