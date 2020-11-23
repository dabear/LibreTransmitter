//
//  AlertControllers.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 03/06/2019.
//  
//

import UIKit

func InputAlertController(_ message: String, title: String, inputPlaceholder: String, completion: @escaping (_ isOK: Bool, _ alertController: UIAlertController) -> Void ) -> UIAlertController {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

    // Create OK button
    let OKAction = UIAlertAction(title: "OK", style: .default) { (_: UIAlertAction!) in
        // Code in this block will trigger when OK button tapped.
        completion(true, alertController)
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (_: UIAlertAction!) in
        // Code in this block will trigger when cancel button tapped.
        completion(false, alertController)
    }

    alertController.addTextField { textField in
        textField.placeholder = inputPlaceholder
    }
    alertController.addAction(cancelAction)
    alertController.addAction(OKAction)
    return alertController
}

func OKAlertController(_ message: String, title: String ) -> UIAlertController {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

    // Create OK button
    let OKAction = UIAlertAction(title: "OK", style: .default) { (_: UIAlertAction!) in
        // Code in this block will trigger when OK button tapped.

    }
    alertController.addAction(OKAction)
    return alertController
}
func ErrorAlertController(_ message: String, title: String ) -> UIAlertController {
    let alertController = UIAlertController(title: title + "❗️", message: message, preferredStyle: .alert)

    // Create OK button
    let OKAction = UIAlertAction(title: "ok", style: .cancel) { (_: UIAlertAction!) in
        // Code in this block will trigger when OK button tapped.

    }
    alertController.addAction(OKAction)
    return alertController
}
