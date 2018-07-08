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

func createImage(image: UIImage?) -> UIImageView {
    let img = UIImageView(image: image)
    img.translatesAutoresizingMaskIntoConstraints = false

    return img
}

func createButton(text:String, font:UIFont) -> UIButton {
    let button = UIButton(type: .system)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle(text, for: .normal)
    button.titleLabel!.font = font
    return button
}

func createFAButton(icon: UIImage) -> UIButton {
    let button = UIButton(type: .custom)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(icon, for: .normal)
    return button
}

func createWarnButton(text: String) -> UIButton! {
    let button = createButton(text: text)
    button.tintColor = .white
    button.backgroundColor = NanoColors.red
    button.layer.borderColor = NanoColors.red.cgColor
    button.layer.cornerRadius = 5
    button.layer.borderWidth = 1

    return button
}

func createOKButton(text: String) -> UIButton! {
    let button = createButton(text: text)
    button.tintColor = .white
    button.backgroundColor = NanoColors.green
    button.layer.borderColor = NanoColors.green.cgColor
    button.layer.cornerRadius = 5
    button.layer.borderWidth = 1

    return button
}

func createTextBox(text: String) -> UITextView {
    let view = UITextView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.font = UIFont(name: "Verdana", size: 14)
    view.textColor = UIColor.black

    return view
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
