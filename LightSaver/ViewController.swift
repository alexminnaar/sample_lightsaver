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
    var color: UIColor = UIColor.red
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Mapsync
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
        
        mapsyncSession = MapsyncSession.init(arSession: sceneView.session, mapsyncMode: mapsyncMode, appID: appID!, userID: userID!, mapID: mapID!, statusCallback: mapsyncStatusCallback)
        
        setUI(.unknown)
        mapsyncNotification.isHidden = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
        // Release any cached data, images, etc that aren't in use.
    }

    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        
        if drawing, let transform = sceneView.pointOfView?.transform, let position = sceneView.pointOfView?.position {
            
            let offset = SCNVector3(-0.4 * transform.m31, -0.4 * transform.m32, -0.4 * transform.m33)
            let drawPosition = SCNVector3.init(offset.x + position.x, offset.y + position.y, offset.z + position.z)
            
            let sphereNode = SCNNode(geometry: SCNSphere(radius: 0.01))
            sphereNode.geometry?.firstMaterial?.diffuse.contents = color
            sphereNode.position = drawPosition
            
            let asset = MapsyncAsset.init("sphere", position, 0.0)
            
            mapsyncAssets.append(asset)
            sceneView.scene.rootNode.addChildNode(sphereNode)
            
        }
        
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    @IBAction func drawButtonDown(_ sender: Any) {
        drawing = true
    }
    
    @IBAction func drawButtonUpInside(_ sender: Any) {
        drawing = false
    }
    
    @IBAction func drawButtonUpOutside(_ sender: Any) {
        drawing = false
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        showMapsyncNotification("Saving")
        if mapsyncAssets.count > 0 {
            DispatchQueue.main.async {
                self.setUI(.unknown)
                self.mapsyncNotification.isHidden = true
            }
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

            })
        }
    }
    
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
                self.addAssetToScene(asset.position)
            }
            
            DispatchQueue.main.async {
                self.setUI(.unknown)
                self.mapsyncNotification.isHidden = true
            }
        })
    }
    
    private func addAssetToScene(_ position: SCNVector3) {
        let sphereNode = SCNNode(geometry: SCNSphere(radius: 0.01))
        sphereNode.geometry?.firstMaterial?.diffuse.contents = color
        sphereNode.position = position
        
        sceneView.scene.rootNode.addChildNode(sphereNode)
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if sessionStarted {
            mapsyncSession?.update(frame: frame)
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        
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
    
    // Mapsync
    func mapsyncStatusCallback(status: MapsyncStatus){
        switch status {
        case .initialized:
            print("initialized")
            
        case .localizationError:
            print("localization error")
            
        case .serverError:
            print("server error")
            
        case .noMapFound:
            print("no map found")
            
        case .networkFailure:
            print("network failure")
            
        case .noAssetFound:
            print ("no asset found")
            
        default:
            print("error mapsync status")
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
