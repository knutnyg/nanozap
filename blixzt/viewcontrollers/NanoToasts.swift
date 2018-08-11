import Foundation
import SwiftMessages

func displayError(message: String) {
    var config = SwiftMessages.Config()

    config.presentationStyle = .center

    // Display in a window at the specified window level: UIWindowLevelStatusBar
    // displays over the status bar while UIWindowLevelNormal displays under.
    config.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)

    // Disable the default auto-hiding behavior.
    config.duration = .forever

    // Dim the background like a popover view. Hide when the background is tapped.
    config.dimMode = .gray(interactive: true)

    // Disable the interactive pan-to-hide gesture.
    config.interactiveHide = false

    // Specify a status bar style to if the message is displayed directly under the status bar.
    config.preferredStatusBarStyle = .lightContent

    // Specify one or more event listeners to respond to show and hide events.
    config.eventListeners.append() { event in
        if case .didHide = event {
            print("yep didHide")
        }
    }

    let view = MessageView.viewFromNib(layout: .messageView)
    view.configureTheme(.info)
    view.configureContent(title: "Uh-oh", body: message)

    // hide button
    view.button?.isHidden = true
    // set a title for button
    view.button?.setTitle("OK", for: .normal)
    // Add a drop shadow.
    view.configureDropShadow()

    SwiftMessages.show(config: config, view: view)
}

func displaySuccess(message: String) {
    var config = SwiftMessages.Config()
    config.presentationStyle = .center
    config.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
    config.duration = .seconds(seconds: 2)
    config.dimMode = .gray(interactive: true)
    config.interactiveHide = false
    config.preferredStatusBarStyle = .lightContent
    config.eventListeners.append() { event in
        if case .didHide = event {
            print("yep didHide")
        }
    }

    let view = MessageView.viewFromNib(layout: .messageView)
    view.configureTheme(.success)
    view.configureContent(title: "Success", body: message)
    view.button?.isHidden = true
    view.button?.setTitle("OK", for: .normal)
    view.configureDropShadow()
    SwiftMessages.show(config: config, view: view)
}
