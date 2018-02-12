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

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var drawing: Bool = false
    var color: UIColor = UIColor.red
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
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
            
            let offset = SCNVector3(-0.1 * transform.m31, -0.1 * transform.m32, -0.1 * transform.m33)
            let drawPosition = SCNVector3.init(offset.x + position.x, offset.y + position.y, offset.z + position.z)
            
            let sphereNode = SCNNode(geometry: SCNSphere(radius: 0.01))
            sphereNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            sphereNode.position = drawPosition
            
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
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
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
}
