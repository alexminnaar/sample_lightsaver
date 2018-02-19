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

    // Map
    var mapsyncSession: MapSession?
    var mapsyncAssets: [MapAsset] = [MapAsset]()
    var mapsyncMode: MapMode = .unknown
    var appID: String?
    var userID: String?
    var mapID: String?
    var sessionStarted: Bool = false
    
    @IBOutlet var saveButton: UIButton!
    @IBOutlet var reloadButton: UIButton!
    @IBOutlet var mapsyncNotification: UILabel!
    
    @IBOutlet var sceneView: ARSCNView!
    
    var drawing: Bool = false
    var color: UIColor = UIColor.blue
    var colorLabel: String = ""
    var green: UIColor = UIColor.init(red: 0x00, green: 0xff, blue: 0xe1, alpha: 0xff)
    var purple: UIColor = UIColor.init(red: 0.58, green: 0x00, blue: 0xff, alpha: 0xff)
    var pink: UIColor = UIColor.init(red: 0xff, green: 0x00, blue: 0xa4, alpha: 0xff)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
        //Pulls username from userdefaults set in LoginViewController
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
        setUI(.unknown)
        if mapsyncMode == .localization {
            showMapNotification("Scan around for your design to reload.")
        } else {
            mapsyncNotification.isHidden = true
        }
        
        //Initialize MapSession
        self.mapsyncSession = MapSession.init(arSession: sceneView.session, mapMode: mapsyncMode, userID: userID!, mapID: mapID!, developerKey: DEV_KEY, assetsFoundCallback: reloadAssetsCallback, statusCallback: mapsyncStatusCallback)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.worldAlignment = ARConfiguration.WorldAlignment.gravityAndHeading //Required for Map
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
        
        if drawing, let transform = sceneView.pointOfView?.transform, let position = sceneView.pointOfView?.position {
            
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
            mapsyncAssets.append(asset)
            
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
    
    //Uploads map and Map Assets
    @IBAction func saveButtonPressed(_ sender: Any) {
        showMapNotification("Saving")
        if mapsyncAssets.count > 0 {
            mapsyncSession?.storePlacement(assets: mapsyncAssets, callback: { (didUpload) in
                if !didUpload {
                    print("didn't store placement")
                    return
                }
                print("stored placement")
                
                DispatchQueue.main.async {
                    self.setUI(.unknown)
                    self.mapsyncNotification.isHidden = true
                }

            })
        }
    }
    
    //Uploads map and reloads assets
    @IBAction func reloadButtonPressed(_ sender: Any) {
        showMapNotification("Reloading")
    }
    
    private func reloadAssetsCallback(mapAssets: [MapAsset]) {
        print("Reloading \(mapAssets.count) assets to the scene")
        if mapAssets.count > 0 {
            print("first asset: \(mapAssets.first!.assetID)")
        }
        for asset in mapAssets {
            self.addAssetToScene(asset)
        }
        
        DispatchQueue.main.async {
            self.setUI(.unknown)
            self.mapsyncNotification.isHidden = true
        }
    }
    
    private func addAssetToScene(_ asset: MapAsset) {
        let sphereNode = SCNNode(geometry: SCNSphere(radius: 0.01))
        sphereNode.geometry?.firstMaterial?.diffuse.contents = getColor(asset.assetID)
        sphereNode.position = asset.position
        
        sceneView.scene.rootNode.addChildNode(sphereNode)
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
            mapsyncSession?.update(frame: frame)
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        //Only display Save/Reload once ARSession starts
        switch camera.trackingState {
        case .normal:
            if !sessionStarted {
                sessionStarted = true
                setUI(mapsyncMode)
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
    func mapsyncStatusCallback(status: MapStatus){
        switch status {
        case .initialized:
            print("initialized")
            
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
    
    private func setUI(_ mode: MapMode){
        switch mode {
        case .mapping:
            saveButton.isEnabled = true
            saveButton.isHidden = false
            reloadButton.isEnabled = false
            reloadButton.isHidden = true
            
        case .localization:
            saveButton.isEnabled = false
            saveButton.isHidden = true
            reloadButton.isEnabled = false
            reloadButton.isHidden = true
        
        default:
            saveButton.isEnabled = false
            saveButton.isHidden = true
            reloadButton.isEnabled = false
            reloadButton.isHidden = true
        }
    }
    
    // MARK: - User Instruction
    func showMapNotification(_ instruction: String) {
        mapsyncNotification.layer.cornerRadius = 5
        mapsyncNotification.layer.masksToBounds = true
        mapsyncNotification.text = instruction
        mapsyncNotification.isHidden = false
        print("Showing notifcation: \(instruction)")
    }
}
