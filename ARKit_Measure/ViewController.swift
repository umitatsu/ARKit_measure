//
//  ViewController.swift
//  ARKit_Measure
//
//  Created by Tatsuya.Umino on 2018/08/21.
//  Copyright © 2018年 Tatsuya.Umino. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    private var startNode: SCNNode?
    private var endNode: SCNNode?
    private var lineNode: SCNNode?

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var resetBtn: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        sceneView.scene = SCNScene()
        
        reset()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    private func reset() {
        startNode?.removeFromParentNode()
        startNode = nil
        endNode?.removeFromParentNode()
        endNode = nil
        statusLabel.isHidden = true
    }
    
    private func putSphere(at pos: SCNVector3, color: UIColor) -> SCNNode {
        let geometry = SCNSphere(radius: 0.01)
        geometry.materials.first?.diffuse.contents = color
        let node = SCNNode(geometry: geometry)
        sceneView.scene.rootNode.addChildNode(node)
        node.position = pos
        return node
    }
    
    private func drawLine(from: SCNNode, to: SCNNode, length: Float) -> SCNNode {
        let geometry = SCNCapsule(capRadius: 0.004, height: CGFloat(length))
        geometry.materials.first?.diffuse.contents = UIColor.red
        let line = SCNNode(geometry: geometry)
        
        let node = SCNNode()
        node.eulerAngles = SCNVector3Make(Float.pi/2, 0, 0)
        node.addChildNode(line)
        from.addChildNode(node)
        node.position = SCNVector3Make(0, 0, -length / 2)
        from.look(at: to.position)
        return node
    }
    
    private func hitTest(_ pos: CGPoint) {
        let results = sceneView.hitTest(pos, types: [.featurePoint])
        guard let result = results.first else {return}
        let hitPos = SCNVector3(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y, result.worldTransform.columns.3.z)
        
        if let startNode = startNode {
            endNode = putSphere(at: hitPos, color: UIColor.green)
            guard let endNode = endNode else {fatalError()}
            
            let position = SCNVector3Make(endNode.position.x - startNode.position.x, endNode.position.y - startNode.position.y, endNode.position.z - startNode.position.z)
            let distance = sqrt(position.x*position.x + position.y*position.y + position.z*position.z)
            print("distance: \(distance) [m]")
            
            lineNode = drawLine(from: startNode, to: endNode, length: distance)
            
            statusLabel.text = String(format: "Distance: %.2f [m]", distance)
        } else {
            startNode = putSphere(at: hitPos, color: UIColor.blue)
            statusLabel.text = "Tap an end point"
        }
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let frame = sceneView.session.currentFrame else {return}
        DispatchQueue.main.async(execute: {
            self.statusLabel.isHidden = !(frame.anchors.count > 0)
            if self.startNode == nil {
                self.statusLabel.text = "Tap a start point"
            }
        })
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        planeAnchor.addPlaneNode(on: node, contents: UIColor.blue)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        planeAnchor.updatePlaneNode(on: node)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function)
    }
    
    // MARK: - ARSessionObserver
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("trackingState: \(camera.trackingState)")
    }
    
    // MARK: - Touch Handlers
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {return}
        let pos = touch.location(in: sceneView)
        
        if let endNode = endNode {
            endNode.removeFromParentNode()
            lineNode?.removeFromParentNode()
        }
        
        hitTest(pos)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func resetBtnTapped(_ sender: UIButton) {
        reset()
    }
    
}

