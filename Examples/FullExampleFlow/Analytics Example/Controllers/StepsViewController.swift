//
//  StepsViewController.swift
//  Analytics Example
//
//  Created by Cody Garvin on 6/3/20.
//  Copyright © 2020 Cody Garvin. All rights reserved.
//

import UIKit

class StepsViewController: UIViewController {
    
    var codeString: String? {
        didSet {
            codeView.text = codeString
        }
    }
    
    var descriptionString: String? {
        didSet {
            descriptionView.text = descriptionString
        }
    }
    
    var propertyViews: [UIView]? {
        didSet {
            stackView.removeFromSuperview()
            setup()
        }
    }
    
    private var codeView: UITextView!
    private var descriptionView: UILabel!
    private var stackView: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Titlebar setup
        titleBarSetup()

        // Do any additional setup after loading the view.
        setup()
    }
    
    private func titleBarSetup() {
        
        let titleImageView = UIImageView(image: UIImage(named: "SegmentLogo"))
        titleImageView.frame = CGRect(x: 0, y: 0, width: 193.0, height: 40.0)
        titleImageView.contentMode = .scaleAspectFit
        navigationItem.titleView = titleImageView
    }

    private func setup() {
        view.backgroundColor = UIColor.white
        
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16.0).isActive = true
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16.0).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16.0).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16.0).isActive = true
        stackView.alignment = .leading
        
        if let propertyViews = propertyViews {
            for (count, view) in propertyViews.enumerated() {
                stackView.insertArrangedSubview(view, at: count)
                view.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
            }
        }

        let containerView = UIView(frame: .zero)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        descriptionView = UILabel(frame: .zero)
        descriptionView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(descriptionView)
        descriptionView.font = UIFont.systemFont(ofSize: 14.0)
        descriptionView.textColor = UIColor.primaryColor02()
        descriptionView.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor).isActive = true
        descriptionView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        descriptionView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        descriptionView.numberOfLines = 0
        descriptionView.text = descriptionString
        
        codeView = UITextView(frame: .zero)
        codeView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(codeView)
        codeView.font = UIFont(name: "Menlo-Regular", size: 12.0)
        codeView.textColor = UIColor.primaryColor02()
        codeView.translatesAutoresizingMaskIntoConstraints = false
        codeView.topAnchor.constraint(equalTo: descriptionView.bottomAnchor, constant: 16.0).isActive = true
        codeView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        codeView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        codeView.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor).isActive = true
        codeView.layer.borderColor = UIColor.primaryColor02().cgColor // 18 / 66 / 74
        codeView.layer.cornerRadius = 6.0
        codeView.text = codeString

        codeView.layer.borderWidth = 1.0
        codeView.backgroundColor = UIColor.secondaryColor01() // 204 / 217 / 222

        stackView.addArrangedSubview(containerView)
        containerView.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
        
        // Theme
        navigationController?.navigationBar.tintColor = UIColor.primaryColor01()
    }
}

extension UIColor {
    // 204/217/222
    static func secondaryColor01() -> UIColor {
        return UIColor(red: 0.8, green: 0.85, blue: 0.87, alpha: 1.0)
    }
    
    // 18/66/74
    static func primaryColor02() -> UIColor {
        return UIColor(red: 0.07, green: 0.26, blue: 0.29, alpha: 1.0)
    }
    
    // 82 / 189 / 149
    static func primaryColor01() -> UIColor {
        return UIColor(red: 0.32, green: 0.74, blue: 0.58, alpha: 1.0)
    }

}

extension UIButton {
    static func SegmentButton(_ title: String, target: Any, action: Selector) -> UIButton {
        let trackButton = UIButton()
        trackButton.setTitle(title, for: .normal)
        trackButton.setTitleColor(UIColor.primaryColor02(), for: .normal)
        trackButton.setTitleColor(UIColor.lightGray, for: .disabled)
        trackButton.addTarget(target, action: action, for: .touchUpInside)
        trackButton.titleLabel?.textColor = UIColor.primaryColor02()
        trackButton.layer.borderColor = UIColor.primaryColor02().cgColor
        trackButton.layer.borderWidth = 1.0
        trackButton.layer.cornerRadius = 6.0
        trackButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
        return trackButton
    }
}

extension UIView {
    static func separator() -> UIView {
        let separator = UIView()
        separator.heightAnchor.constraint(equalToConstant: 12.0).isActive = true
        separator.backgroundColor = .white
        return separator
    }
}
