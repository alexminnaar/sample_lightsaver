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

    // Mapsync
    var mapsyncSession: MapsyncSession?
    var mapsyncAssets: [MapsyncAsset] = [MapsyncAsset]()
    var mapsyncMode: MapsyncMode = .unknown
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
        
        //Initialize MapsyncSession
        do {
        self.mapsyncSession = try MapsyncSession.init(arSession: sceneView.session, mapsyncMode: mapsyncMode, userID: userID!, mapID: mapID!, developerKey: DEV_KEY, statusCallback: mapsyncStatusCallback)
        }
        catch {
            print("Failed to initialize Mapsync Session")
        }

        //Set up UI
        setUI(.unknown)
        if mapsyncMode == .localization {
            showMapsyncNotification("Scan around for your design and press reload when ready.")
        } else {
            mapsyncNotification.isHidden = true
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.worldAlignment = ARConfiguration.WorldAlignment.gravityAndHeading //Required for Mapsync
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
            
            //Save a corresponding MapsyncAsset
            let asset = MapsyncAsset.init(colorLabel, position, 0.0)
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
    
    //Uploads map and Mapsync Assets
    @IBAction func saveButtonPressed(_ sender: Any) {
        showMapsyncNotification("Saving")
        if mapsyncAssets.count > 0 {
            mapsyncSession?.uploadMap(callback: { (didUpload) in
                if !didUpload {
                    print("didn't upload map")
                    return
                }
                print("uploaded map")

            })
            
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
        showMapsyncNotification("Reloading")
        mapsyncSession?.uploadMap(callback: { (didUpload) in
            if !didUpload {
                return
            }
            
            self.reloadAssets()
        })
    }
    
    private func reloadAssets() {
        mapsyncSession?.reloadAssets(callback: { (mapsyncAssets) in
            for asset in mapsyncAssets {
                self.addAssetToScene(asset)
            }
            
            DispatchQueue.main.async {
                self.setUI(.unknown)
                self.mapsyncNotification.isHidden = true
            }
        })
    }
    
    private func addAssetToScene(_ asset: MapsyncAsset) {
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
            //Required for Mapsync
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
    
    // Mapsync status handling
    func mapsyncStatusCallback(status: MapsyncStatus){
        switch status {
        case .initialized:
            print("initialized")
            
        case .localizationError:
            print("relocalization error")
            showMapsyncNotification("Drawing not found")
            
        case .serverError:
            print("server error")
            showMapsyncNotification("Server Error")
            
        case .noMapFound:
            print("no map found")
            showMapsyncNotification("Drawing not found")
            
        case .networkFailure:
            print("network failure")
            showMapsyncNotification("Network Error")
            
        case .noAssetFound:
            print ("no asset found")
            showMapsyncNotification("Drawing not found")
        }
    }
    
    private func setUI(_ mode: MapsyncMode){
        switch mode {
        case .mapping:
            saveButton.isEnabled = true
            saveButton.isHidden = false
            reloadButton.isEnabled = false
            reloadButton.isHidden = true
            
        case .localization:
            saveButton.isEnabled = false
            saveButton.isHidden = true
            reloadButton.isEnabled = true
            reloadButton.isHidden = false
        
        default:
            saveButton.isEnabled = false
            saveButton.isHidden = true
            reloadButton.isEnabled = false
            reloadButton.isHidden = true
        }
    }
    
    // MARK: - User Instruction
    func showMapsyncNotification(_ instruction: String) {
        mapsyncNotification.layer.cornerRadius = 5
        mapsyncNotification.layer.masksToBounds = true
        mapsyncNotification.text = instruction
        mapsyncNotification.isHidden = false
        
    }
}
