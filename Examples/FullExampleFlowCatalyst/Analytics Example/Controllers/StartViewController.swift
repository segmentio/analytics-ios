//
//  ViewController.swift
//  Analytics Example
//
//  Created by Cody Garvin on 6/1/20.
//  Copyright © 2020 Cody Garvin. All rights reserved.
//

import UIKit
import Analytics

class StartViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var writeKeyField: UITextField!
    
    private var storedKeys: Array<String>?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Start"
        
        // Do any additional setup after loading the view.
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "writeKeyCell")
        
        storedKeys = storedWriteKeys()
        
        Analytics.shared().flush()
    }

    @IBAction
    func login(_ sender: Any) {
        
        // Grab the current write key
        guard let writeKey = writeKeyField.text else { return }
        
        // Store off the current write key
        saveWriteKey(writeKey)
        
        let loginController = LoginViewController()
        self.navigationController?.pushViewController(loginController, animated: true)
    }
    
    private func storedWriteKeys() -> Array<String>? {
        var returnKeys: Array<String>?
        
        if let existingKeys = UserDefaults.standard.object(forKey: "writekeys") as? Array<String> {
            returnKeys = existingKeys
        }
        
        return returnKeys
    }
    
    private func saveWriteKey(_ key: String) {
        var writeKeys = [key]
        if let keys = storedWriteKeys() {
            
            if !keys.contains(key) {
                writeKeys.append(contentsOf: keys)
            } else {
                return
            }
        }
        
        UserDefaults.standard.set(writeKeys, forKey: "writekeys")
    }
}

extension StartViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return storedWriteKeys()?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let returnCell = tableView.dequeueReusableCell(withIdentifier: "writeKeyCell") else {
            return UITableViewCell()
        }
        returnCell.textLabel?.text = storedKeys?[indexPath.row]
        returnCell.textLabel?.font = UIFont.systemFont(ofSize: 12.0)
        return returnCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Grab key from index
        writeKeyField.text = storedKeys?[indexPath.row]
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Write Keys"
    }
}

