//
//  LoginViewController.swift
//  LightSaver
//
//  Created by Stauber on 2/12/18.
//  Copyright © 2018 Stauber. All rights reserved.
//

import UIKit
import JidoMaps

class LoginViewController: UIViewController {

    @IBOutlet var usernameInput: UITextField!
    @IBOutlet var drawingInput: UITextField!
    var appID: String = Bundle.main.bundleIdentifier!
    
    @IBOutlet var startDrawingButton: UIButton!
    @IBOutlet var reloadDrawingButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaults = UserDefaults.standard
        if let username = defaults.string(forKey:"username") {
            usernameInput.text = username
        }
        if let drawingID = defaults.string(forKey:"drawing_id") {
            drawingInput.text = drawingID
        }
        
        let tap = UITapGestureRecognizer(target: self.view, action: Selector("endEditing:"))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func startDrawingButton(_ sender: UIButton) {
        if checkEmptyInput() {
            return
        }
        setUserDefaults()
        startDrawingButton.isEnabled = false
        reloadDrawingButton.isEnabled = false
        //Brief pause to make sure any prior ARSessions are properly closed
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.performSegue(withIdentifier: "newSegue", sender: self)
        }
    }
    
    @IBAction func reloadDrawingButton(_ sender: UIButton) {
        if checkEmptyInput() {
            return
        }
        setUserDefaults()
        startDrawingButton.isEnabled = false
        reloadDrawingButton.isEnabled = false
        //Brief pause to make sure any prior ARSessions are properly closed
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.performSegue(withIdentifier: "loadSegue", sender: self)
        }
    }
    
    
    // Set Map Mode based on button pressed
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if let viewController = segue.destination as? ViewController {
                if segue.identifier == "newSegue" {
                    viewController.sessionMode = .mapping
                } else if segue.identifier == "loadSegue" {
                    viewController.sessionMode = .localization
                }
                startDrawingButton.isEnabled = true
                reloadDrawingButton.isEnabled = true
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
