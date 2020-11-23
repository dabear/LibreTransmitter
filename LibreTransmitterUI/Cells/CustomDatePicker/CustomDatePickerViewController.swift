//
//  CustomDatePickerViewController.swift
//  MiaomiaoClientUI
//
//  Created by Bjørn Inge Berg on 18/06/2019.
//  Copyright © 2019 Bjørn Inge Berg. All rights reserved.
//

import UIKit

protocol CustomDatePickerDelegate: class {
    func CustomDatePickerDelegateDidTapDone(fromComponent: DateComponents?, toComponents: DateComponents?)
    func CustomDatePickerDelegateDidTapCancel()
}

extension UIView {
    func fixInView(_ container: UIView!) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.frame = container.frame
        container.addSubview(self)
        NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: container, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: container, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
    }
}

extension CustomDatePickerDelegate {
    //makes it optional
    func CustomDatePickerDelegateDidTapCancel() {}
}
class CustomDatePickerViewController: UIViewController {
    fileprivate let pickerView = CustomDatePicker()

    public weak var delegate: CustomDatePickerDelegate?

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        setDescriptionLabel()
    }

    func setDescriptionLabel() {
        self.pickerView.setPickerLabels(labels: [1: labeldesc], containedView: self.view)
    }

    private lazy var labeldesc = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        let saveButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneTapped))
        saveButton.tintColor = .red

        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelTapped))
        cancelButton.tintColor = .red

        self.navigationItem.rightBarButtonItem = saveButton
        self.navigationItem.leftBarButtonItem = cancelButton
        self.navigationItem.prompt = "Schedule"

        self.pickerView.backgroundColor = .systemBackground
        self.pickerView.reloadAllComponents()
        self.pickerView.fixInView(self.view)
        self.view.addSubview(self.pickerView)

        labeldesc.text = "TO"

        setDescriptionLabel()
    }

    @objc
    func doneTapped() {
        print("done tapped")
        delegate?.CustomDatePickerDelegateDidTapDone(fromComponent: self.pickerView.lastSelectedComponentLeft, toComponents: self.pickerView.lastSelectedComponentRight)
        self.navigationController?.popViewController(animated: true)
    }

    func crash() -> Int {
        print("now crashing!")

        [][1]
        //fatalError()
        return 1
    }

    @objc
    func cancelTapped() {
        print("cancel tapped")
        delegate?.CustomDatePickerDelegateDidTapCancel()
        self.navigationController?.popViewController(animated: true)
    }
}
