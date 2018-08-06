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
import JidoMaps

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    // Map Session Members
    var jidoSession: JidoSession?
    var mapAssets: [MapAsset] = [MapAsset]() // Stores assets to be saved
    var sessionMode: SessionMode? // Is set to .mapping or .localization mode by LoginViewController
    
    
    var appID: String?
    var userID: String?
    var mapId: String?
    var sessionStarted: Bool = false
    var searching: Bool = false
    
    @IBOutlet var mapNotification: UILabel!
    @IBOutlet var drawingInstruction: UIImageView!
    @IBOutlet weak var scanProgressBar: UIProgressView!
    
    @IBOutlet var sceneView: ARSCNView!
    
    var drawing: Bool = false
    var color: UIColor = UIColor.blue
    var colorLabel: String = ""
    var green: UIColor = UIColor.init(red: 0x00, green: 0xff, blue: 0xe1, alpha: 0xff)
    var purple: UIColor = UIColor.init(red: 0.58, green: 0x00, blue: 0xff, alpha: 0xff)
    var pink: UIColor = UIColor.init(red: 0xff, green: 0x00, blue: 0xa4, alpha: 0xff)
    var drawingThreshold: Int = 350
    
    var alreadyReloaded = false
    var sceneAssets: [SCNNode] = []
    
    private let TARGET_PROGRESS_POINTS = 5
    
    private static let progress1Color = UIColor(red: 251.0 / 255.0 , green: 75.0 / 255.0, blue: 75.0 / 255.0, alpha: 1.0)
    private static let progress2Color = UIColor(red: 255.0 / 255.0 , green: 168.0 / 255.0, blue: 121.0 / 255.0, alpha: 1.0)
    private static let progress3Color = UIColor(red: 255.0 / 255.0 , green: 193.0 / 255.0, blue: 99.0 / 255.0, alpha: 1.0)
    private static let progress4Color = UIColor(red: 254.0 / 255.0 , green: 255.0 / 255.0, blue: 92.0 / 255.0, alpha: 1.0)
    private static let progress5Color = UIColor(red: 192.0 / 255.0 , green: 255.0 / 255.0, blue: 51.0 / 255.0, alpha: 1.0)
    
    private static let progressColors = [progress1Color, progress2Color, progress3Color, progress4Color, progress5Color]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scanProgressBar.progress = 0.0
        self.scanProgressBar.layer.transform = CATransform3DMakeScale(1.0, 5.0, 0.0)
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]

        
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
            self.mapId = mapID
        }

        //Set up UI
        mapNotification.layer.cornerRadius = 5
        mapNotification.layer.masksToBounds = true
        drawingInstruction.isHidden = true
        showMapNotification("Scan around your area to start!")
        
        //Initialize MapSession
        self.jidoSession = JidoSession(arSession: sceneView.session, mapMode: sessionMode!, userID: self.userID!, mapID: mapId!, developerKey: DEV_KEY, screenHeight: view.frame.height, screenWidth: view.frame.width, assetsFoundCallback: self.reloadAssetsCallback, progressCallback: self.incrementScanProgress, statusCallback: self.mapStatusCallback, objectDetectedCallback: { objects in (([DetectedObject]) -> (Void)).self
            if objects.count == 0 {
                return
            }
        })
    }
    
    func incrementScanProgress(scanProgressCount: Int) {
        print("SCAN PROGRESS: \(scanProgressCount)")
        
        
        if sessionMode == .localization && scanProgressCount > 4 && !self.alreadyReloaded {
            return
        }
        
        DispatchQueue.main.async {
            self.scanProgressBar.progress = min(Float(scanProgressCount) / Float(self.TARGET_PROGRESS_POINTS), 1.0)
            
            let colorIndex = min(scanProgressCount - 1, 4)
            self.scanProgressBar.progressTintColor = ViewController.progressColors[colorIndex]
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Required for MapSession
        let configuration = ARWorldTrackingConfiguration()
        if #available(iOS 11.3, *) {
            configuration.planeDetection = [.horizontal, .vertical]
        } else {
            configuration.planeDetection = .horizontal
        }
        configuration.worldAlignment = ARConfiguration.WorldAlignment.gravity
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
                sceneAssets.append(sphereNode)
                
                //Save a corresponding MapAsset
                let asset = MapAsset.init(colorLabel, drawPosition, 0.0)
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
        
        saveDrawing()
    }
    
    @IBAction func drawButtonUpOutside(_ sender: Any) {
        drawing = false
        
        saveDrawing()
    }
    
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func saveDrawing() {
        showMapNotification("Saving")
        if mapAssets.count > 0 && jidoSession?.mappingUUID != nil {
            var count = 0
            for asset in self.mapAssets {
                asset.assetID += "-\(count)"
                count += 1
            }
            
            jidoSession?.storePlacement(assets: mapAssets, callback: { (didUpload) in
                if !didUpload {
                    print("didn't store placement")
                    return
                }
                print("stored placement")
                
                DispatchQueue.main.async {
                    self.mapNotification.isHidden = true
                }
            })
        }
    }

    
    private func reloadAssetsCallback(mapAssets: [MapAsset]) {
        DispatchQueue.main.async {
            print("Reloading \(mapAssets.count) assets to the scene")
            
            self.addAssetToScene(mapAssets)

            if !self.alreadyReloaded {
                self.showMapNotification("Design Found!")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.mapNotification.isHidden = true
                    self.searching = false
                    self.scanProgressBar.isHidden = true
                }
                
                self.alreadyReloaded = true
            }
        }
    }
    
    private func addAssetToScene(_ assets: [MapAsset]) {
        if !self.alreadyReloaded {
            for asset in assets {
                let sphere = SCNSphere(radius: 0.01)
                let sphereNode = SCNNode(geometry: sphere)
                sphereNode.geometry?.firstMaterial?.diffuse.contents = self.getColor(String(asset.assetID.split(separator: "-")[0]))
                sphereNode.position = asset.position
                sphereNode.opacity = CGFloat(1)

                self.sceneAssets.append(sphereNode)
                self.sceneView.scene.rootNode.addChildNode(sphereNode)
            }
            print("here! \(self.sceneAssets.count)")
        } else {
            print("here2! \(self.sceneAssets.count)")
            for (i, asset) in assets.enumerated() {
                SCNTransaction.animationDuration = 1.0
                self.sceneAssets[i].opacity = CGFloat(1)
                self.sceneAssets[i].position = asset.position
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
            jidoSession?.update(frame: frame)
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        //Only display Save/Reload once ARSession starts
        switch camera.trackingState {
        case .normal:
            if !sessionStarted {
                sessionStarted = true
                if sessionMode == .mapping {
                    mapNotification.isHidden = true
                    drawingInstruction.isHidden = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.drawingInstruction.isHidden = true
                    }
                } else if sessionMode == .localization {
                    drawingInstruction.isHidden = true
                    showMapNotification("Great! Continue scanning the area while your design reloads.")
                    searching = true
                    //Search for up to 60 seconds before instructing to restart
                    DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
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
            showMapNotification("No map found")
            
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

        case .configError:
            print("ARSession not properly configured")
            showMapNotification("ARSession not properly configured.")

        case .developerKeyMissingOrMalformed:
            print("Developer key missing")
            showMapNotification("Authentication Error")
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
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("PLANE DETECTED")
        self.jidoSession?.planeDetected(anchor: anchor)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor){
        self.jidoSession?.planeRemoved(anchor: anchor)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        self.jidoSession?.planeUpdated(anchor: anchor)
    }
}
