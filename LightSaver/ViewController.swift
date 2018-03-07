//
//  ViewController.swift
//  LightSaver
//
//  Created by Stauber on 2/12/18.
//  Copyright © 2018 Stauber. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import MapsyncLib

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    // Map Session Members
    var mapSession: MapSession?
    var mapAssets: [MapAsset] = [MapAsset]() // Stores assets to be saved
    var mapMode: MapMode? // Is set to .mapping or .localization mode by LoginViewController
    
    
    var appID: String?
    var userID: String?
    var mapID: String?
    var sessionStarted: Bool = false
    var searching: Bool = false
    
    @IBOutlet var saveButton: UIButton!
    @IBOutlet var mapNotification: UILabel!
    @IBOutlet var drawingInstruction: UIImageView!
    
    @IBOutlet var sceneView: ARSCNView!
    
    var drawing: Bool = false
    var color: UIColor = UIColor.blue
    var colorLabel: String = ""
    var green: UIColor = UIColor.init(red: 0x00, green: 0xff, blue: 0xe1, alpha: 0xff)
    var purple: UIColor = UIColor.init(red: 0.58, green: 0x00, blue: 0xff, alpha: 0xff)
    var pink: UIColor = UIColor.init(red: 0xff, green: 0x00, blue: 0xa4, alpha: 0xff)
    var drawingThreshold: Int = 250
    
    var alreadyReloaded = false
    var sceneAssets: [SCNNode] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
        //Pulls username info from userdefaults set in LoginViewController
        let defaults = UserDefaults.standard
        if let username = defaults.string(forKey:"username") {
            self.userID = username
        }
        if let appID = defaults.string(forKey:"app_id") {
            self.appID = appID
        }
        if let mapID = defaults.string(forKey:"drawing_id") {
            self.mapID = mapID
        }

        //Set up UI
        showButton(false, saveButton)
        mapNotification.layer.cornerRadius = 5
        mapNotification.layer.masksToBounds = true
        drawingInstruction.isHidden = true
        showMapNotification("Scan around your area to start!")
        
        //Initialize MapSession
        MapSession.CONTINOUSLY_UPDATED_RELOCALIZATION = true
        MapSession.CONFIDENCE_THRESHOLD = 0.10
        self.mapSession = MapSession.init(arSession: sceneView.session, mapMode: mapMode!, userID: userID!, mapID: mapID!,
                                          developerKey: DEV_KEY, assetsFoundCallback: reloadAssetsCallback, statusCallback: mapStatusCallback)
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Required for MapSession
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.worldAlignment = ARConfiguration.WorldAlignment.gravityAndHeading
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        
        if sessionStarted, drawing, let transform = sceneView.pointOfView?.transform, let position = sceneView.pointOfView?.position {
            
            // Draw until we reach a large enough drawing.
            if mapAssets.count < drawingThreshold {
                //Draw position should be in front of screen
                let offset = SCNVector3(-0.4 * transform.m31, -0.4 * transform.m32, -0.4 * transform.m33)
                let drawPosition = SCNVector3.init(offset.x + position.x, offset.y + position.y, offset.z + position.z)
                
                //Create a colored sphere
                let sphereNode = SCNNode(geometry: SCNSphere(radius: 0.01))
                sphereNode.geometry?.firstMaterial?.diffuse.contents = color
                sphereNode.position = drawPosition
                sceneView.scene.rootNode.addChildNode(sphereNode)
                
                //Save a corresponding MapAsset
                let asset = MapAsset.init(colorLabel, position, 0.0)
                mapAssets.append(asset)
            } else {
                DispatchQueue.main.async {
                    self.showMapNotification("Great Job! Now save your drawing for others to see.")

                }
            }
        }
        
    }
    
    @IBAction func drawButtonDown(_ sender: UIButton) {
        drawing = true
        
        switch sender.tag {
        case 0:
            color = purple
            colorLabel = "purple"
            
        case 1:
            color = green
            colorLabel = "green"
            
        case 2:
            color = pink
            colorLabel = "pink"
            
        default:
            color = UIColor.blue
        }
    }
    
    @IBAction func drawButtonUpInside(_ sender: Any) {
        drawing = false
    }
    
    @IBAction func drawButtonUpOutside(_ sender: Any) {
        drawing = false
    }
    
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //Uploads map and Map Assets
    @IBAction func saveButtonPressed(_ sender: Any) {
        showMapNotification("Saving")
        if mapAssets.count > 0 {
            mapSession?.storePlacement(assets: mapAssets, callback: { (didUpload) in
                if !didUpload {
                    print("didn't store placement")
                    return
                }
                print("stored placement")
                
                DispatchQueue.main.async {
                    self.showButton(false, self.saveButton)
                    self.mapNotification.isHidden = true
                }

            })
        }
    }
    
    private func reloadAssetsCallback(mapAssets: [MapAsset]) {
        print("Reloading \(mapAssets.count) assets to the scene")
        
        self.addAssetToScene(mapAssets)

        if !alreadyReloaded {
            self.showMapNotification("Design Found!")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.mapNotification.isHidden = true
                self.searching = false
            }
            alreadyReloaded = true
        }
    }
    
    private func addAssetToScene(_ assets: [MapAsset]) {
        if !alreadyReloaded {
            for asset in assets {
                let sphere = SCNSphere(radius: 0.01)
                let sphereNode = SCNNode(geometry: sphere)
                sphereNode.geometry?.firstMaterial?.diffuse.contents = getColor(asset.assetID)
                sphereNode.position = asset.position
                sphereNode.opacity = CGFloat(asset.confidence)

                sceneAssets.append(sphereNode)
                sceneView.scene.rootNode.addChildNode(sphereNode)
            }
        } else {
            for (i, asset) in assets.enumerated() {
                SCNTransaction.animationDuration = 1.0
                sceneAssets[i].opacity = CGFloat(asset.confidence)
                sceneAssets[i].position = asset.position
            }
        }

    }
    
    private func getColor(_ label: String) -> UIColor {
        switch label {
        case "purple":
            return purple
            
        case "green":
            return green
            
        case "pink":
            return pink
            
        default:
            return color
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if sessionStarted {
            //Required for Map
            mapSession?.update(frame: frame)
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        //Only display Save/Reload once ARSession starts
        switch camera.trackingState {
        case .normal:
            if !sessionStarted {
                sessionStarted = true
                if mapMode == .mapping {
                    showButton(true, saveButton)
                    mapNotification.isHidden = true
                    drawingInstruction.isHidden = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.drawingInstruction.isHidden = true
                    }
                } else if mapMode == .localization {
                    drawingInstruction.isHidden = true
                    showMapNotification("Great! Continue scanning the area while your design reloads.")
                    searching = true
                    //Search for up to 25 seconds before instructing to restart
                    DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                        // If still searching after 25 seconds, instruct to restart mapping
                        if self.searching {
                            self.showMapNotification("Design not found.  Please try again.")
                        }
                    }
                }
            }
        case .notAvailable, .limited:
            print("tracking limited")
        }
        
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    // Map status handling
    func mapStatusCallback(status: MapStatus){
        switch status {
        case .initialized:
            print("session initialized")
            
        case .localizationError:
            print("relocalization error")
            showMapNotification("Drawing not found")
            
        case .serverError:
            print("server error")
            showMapNotification("Server Error")
            
        case .noMapFound:
            print("no map found")
            showMapNotification("Drawing not found")
            
        case .networkFailure:
            print("network failure")
            showMapNotification("Network Error")
            
        case .noAssetFound:
            print("no asset found")
            showMapNotification("Drawing not found")
            
        case .authenticationError:
            print("authentication error")
            showMapNotification("Authentication Error. Please add your jido development key!")
            sceneView.session.pause()
            
        case .localizationTimeout:
            print("localization timeout")
            showMapNotification("Localization Timeout")
        }
    }
    
    private func showButton(_ show: Bool, _ button: UIButton){
        button.isHidden = !show
        button.isEnabled = show
    }
    
    // MARK: - User Instruction
    func showMapNotification(_ instruction: String) {
        mapNotification.text = instruction
        mapNotification.isHidden = false
        print("Showing notifcation: \(instruction)")
    }
}
