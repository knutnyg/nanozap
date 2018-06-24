import Foundation
import UIKit

func createTextField(placeholder:String?) -> UITextField {

    let textField = UITextField()
    textField.translatesAutoresizingMaskIntoConstraints = false

    if let text = placeholder {
        textField.placeholder = text
    }

    textField.borderStyle = .roundedRect
    textField.textAlignment = .center
    textField.keyboardType = .emailAddress
    textField.returnKeyType = .done

    return textField
}

func createButton(text:String, font:UIFont) -> UIButton {
    let button = UIButton(type: .system)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle(text, for: .normal)
    button.titleLabel!.font = font
    return button
}

func createButton(text:String) -> UIButton {
    let button = UIButton(type: .system)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle(text, for: .normal)
    return button
}

func createLabel(text:String) -> UILabel{
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = text
    label.font = UIFont(name: "Helvetica", size: 18)
    return label
}

func createLabel(text:String, font:UIFont) -> UILabel{
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = text
    label.font = font
    return label
}
