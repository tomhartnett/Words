//
//  AnswerLetterTextField.swift
//  Words
//
//  Created by Tom Hartnett on 12/21/22.
//

import UIKit

protocol AnswerLetterTextFieldDelegate: AnyObject {
    func didTapDelete()
}

class AnswerLetterTextField: UITextField {
    var value: String {
        let textValue = text ?? ""
        return textValue.isEmpty ? "." : textValue
    }

    weak var answerLetterTextFieldDelegate: AnswerLetterTextFieldDelegate?

    override func buildMenu(with builder: UIMenuBuilder) {
        // Suppress "Search Web" on iOS 16
        if #available(iOS 16.0, *) {
            builder.remove(menu: .lookup)
        }
        super.buildMenu(with: builder)
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }

    override func deleteBackward() {
        super.deleteBackward()
        answerLetterTextFieldDelegate?.didTapDelete()
    }

    static func makeTextField() -> AnswerLetterTextField {
        let t = AnswerLetterTextField(frame: .zero)
        t.autocorrectionType = .no
        t.autocapitalizationType = .none
        t.backgroundColor = UIColor(named: "Parchment")
        t.borderStyle = .roundedRect
        t.clearButtonMode = .never
        t.font = UIFont.monospacedSystemFont(ofSize: 48, weight: .regular)
        t.minimumFontSize = 20
        t.adjustsFontSizeToFitWidth = true
        t.returnKeyType = .done
        t.textAlignment = .center
        return t
    }
}

