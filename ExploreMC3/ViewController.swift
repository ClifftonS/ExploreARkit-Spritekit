//
//  ViewController.swift
//  Basketball-AR
//
//  Created by André Arns on 10/11/21.
//

import UIKit
import SceneKit
import ARKit
import CoreMotion
import SceneKit.ModelIO

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var cameraNode: SCNNode!
    var tempSCNNode:SCNNode?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create a new scene
        var scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene

        // Set the view's delegate
        sceneView.delegate = self
        
        sceneView.scene = scene
        
//        addBuilding()
////        setupCamera()
//        self.sceneView.scene.physicsWorld.contactDelegate = self
    }

    var balls = [String]()
    var contactedBalls = [String: Int]()
    var totScore: Int = 0
    
    
//    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
//        if let name = contact.nodeB.name {
//            contactedBalls[name] = (contactedBalls[name] ?? 0) + 1
//            if ((contactedBalls[name] ?? 0) == 8) {
//                totScore+=1
//                print(totScore)
//            }
//        }
//    }
    
    
    var tapCount: Int = 0
    
    
    //Screen touch pertama
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        guard let touch = touches.first else { return }
        let result = sceneView.hitTest(touch.location(in:sceneView), types: [ARHitTestResult.ResultType.featurePoint])
        guard let hitResult = result.last else { return }
        let hitTransform = SCNMatrix4.init(hitResult.worldTransform)
        let hitVector = SCNVector3Make(hitTransform.m41, hitTransform.m42, hitTransform.m43)
        
        if tapCount == 0 {
            //place object
            addBuilding(position: hitVector)
            //        createBall(position: hitVector)
            tapCount+=1
        }else{
            //throw ball onTap
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
            sceneView.addGestureRecognizer(tap)
            
        }
        
    }
    
    //Create Ball Manual(Lewat Code) untuk di place
    func createBall(position : SCNVector3){
        var ballShape = SCNSphere(radius: 0.1)
        var ballNode = SCNNode(geometry: ballShape)
        ballNode.position = position
        sceneView.scene.rootNode.addChildNode(ballNode)
    }
    
    var customModel: SCNNode!
    
    //Buat Node lewat Scene
    func addBuilding(position: SCNVector3){
        guard let Scene = SCNScene(named: "Resources.scnassets/Views.scn") else {
            print("gagal load box")
            return
        }
        
        guard let Node = Scene.rootNode.childNode(withName: "scenes", recursively: false) else {
            print("gagal print node")
            return
        }
        
        tempSCNNode = Node
        
        guard let tempSCNNode = tempSCNNode else {return}
        tempSCNNode.position = position
        
        sceneView.scene.rootNode.addChildNode(tempSCNNode)
        
        
        
    }

    
    var lastBall = Date()
    
    //throw ball function(ball buat manual code)
    @objc func handleTap(recognizer: UITapGestureRecognizer){
        let acc = 2.0
        //shake strength
        if acc >= 1.5 && lastBall.advanced(by: 0.2).compare(Date()) == .orderedAscending {
            lastBall = Date()

            guard let centerPoint = sceneView.pointOfView else { return }

            let cameraTransform = centerPoint.transform
            let cameraLocation = SCNVector3(x: cameraTransform.m41, y: cameraTransform.m42, z: cameraTransform.m43)
            let cameraOrientation = SCNVector3(x: -cameraTransform.m31, y: -cameraTransform.m32, z: -cameraTransform.m33)

            let cameraPosition = SCNVector3Make(cameraLocation.x + cameraOrientation.x, cameraLocation.y + cameraOrientation.y, cameraLocation.z + cameraOrientation.z)

            let ball = SCNScene(named: "BAT.scnassets/bola.scn")!
            let ballNode = ball.rootNode.childNode(withName: "cannon", recursively: false)!
            
            tempSCNNode = ballNode
            
            ballNode.position = cameraPosition
            ballNode.name = UUID().uuidString

            balls.append(ballNode.name!)

            let physicsShape = SCNPhysicsShape(node: ballNode, options: nil)
            let physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsShape)

            physicsBody.contactTestBitMask = 8
            ballNode.physicsBody = physicsBody

            //speed ball (normal : 3)
            let forceVector: Float = 5
            ballNode.physicsBody?.applyForce(
                SCNVector3(
                    x: cameraOrientation.x * forceVector,
                    y: cameraOrientation.y * Float(abs(acc)) * forceVector,
                    z: cameraOrientation.z * Float(abs(acc)) * forceVector
                ),
                asImpulse: true
            )

            sceneView.scene.rootNode.addChildNode(ballNode)
        }
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

class ARWorldAnchor: ARAnchor{
    init(column0: SIMD4<Float> = [1,0,0,0],
         column1: SIMD4<Float> = [0,1,0,0],
         column2: SIMD4<Float> = [0,0,1,0],
         column3: SIMD4<Float> = [0,0,0,1]){
        let transform = simd_float4x4(columns: (column0, column1, column2, column3))
        let worldAnchor = ARAnchor(name: "World Anchor", transform: transform)
        super.init(anchor: worldAnchor)
    }
    required init(anchor: ARAnchor) {
        super.init(anchor: anchor)
    }
    required init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
        fatalError("Hasn't been implemented yet...")
    }
}
