//
//  LoginViewController.swift
//  LightSaver
//
//  Created by Stauber on 2/12/18.
//  Copyright © 2018 Stauber. All rights reserved.
//

import UIKit
import MapsyncLib

class LoginViewController: UIViewController {

    @IBOutlet var usernameInput: UITextField!
    @IBOutlet var drawingInput: UITextField!
    var appID: String = Bundle.main.bundleIdentifier!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaults = UserDefaults.standard
        if let username = defaults.string(forKey:"username") {
            usernameInput.text = username
        }
        if let drawingID = defaults.string(forKey:"drawing_id") {
            drawingInput.text = drawingID
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func startDrawingButton(_ sender: Any) {
        if checkEmptyInput() {
            return
        }
        setUserDefaults()
        performSegue(withIdentifier: "newSegue", sender: self)
    }
    
    @IBAction func reloadDrawingButton(_ sender: Any) {
        if checkEmptyInput() {
            return
        }
        setUserDefaults()
        performSegue(withIdentifier: "loadSegue", sender: self)
    }
    
    
    // Set Map Mode based on button pressed
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let viewController = segue.destination as? ViewController {
            if segue.identifier == "newSegue" {
                viewController.mapMode = .mapping
            } else if segue.identifier == "loadSegue" {
                viewController.mapMode = .localization
            }
        }
    }
 
    
    private func setUserDefaults() {
        let username = usernameInput.text
        let drawingID = drawingInput.text
        
        let defaults = UserDefaults.standard
        defaults.set(appID, forKey:"app_id")
        defaults.set(username, forKey:"username")
        defaults.set(drawingID, forKey:"drawing_id")
        
    }

    private func checkEmptyInput() -> Bool {
        let username = usernameInput.text
        let drawingID = drawingInput.text
        
        return username == "" || drawingID == ""
    }
}
