//
//  ContentView.swift
//  ExploreMC3
//
//  Created by Cliffton S on 30/07/23.
//

import SwiftUI
import ARKit
import SceneKit

//struct ContentView : View {
//    var body: some View {
//        ARViewContainer().edgesIgnoringSafeArea(.all)
//    }
//}

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {
    
    //    let motionManager: CMMotionManager = {
    //       let result = CMMotionManager()
    //        result.accelerometerUpdateInterval = 1/30
    //        return result
    //    }()

        @IBOutlet var sceneView: ARSCNView!
        var cameraNode: SCNNode!
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            // Create a new scene
            let scene = SCNScene()

            // Set the scene to the view
            sceneView.scene = scene

            // Set the view's delegate
            sceneView.delegate = self
            
            // Show statistics such as fps and timing information
            sceneView.showsStatistics = true
            
            //anchor  test
            let config = ARWorldTrackingConfiguration()
            config.planeDetection = .horizontal
            sceneView.session.run(config)
            let worldAnchor = ARWorldAnchor(column3: [0, 0, -1, 1])
            sceneView.session.add(anchor: worldAnchor)
            
    //        addBuilding()
            setupCamera()
            self.sceneView.scene.physicsWorld.contactDelegate = self
        }

        var balls = [String]()
        var contactedBalls = [String: Int]()
        var totScore: Int = 0
        
        func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
            if let name = contact.nodeB.name {
                contactedBalls[name] = (contactedBalls[name] ?? 0) + 1
                if ((contactedBalls[name] ?? 0) == 8) {
                    totScore+=1
                    print(totScore)
                }
            }
        }
        
        func setupCamera(){
            cameraNode = SCNNode()
            cameraNode.camera = SCNCamera()
            cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
            sceneView.scene.rootNode.addChildNode(cameraNode)
            
        }
        func addBuilding(){
            guard let buildingScene = SCNScene(named: "art.scnassets/blocks.scn") else {
                return
            }

            guard let sandNode = buildingScene.rootNode.childNode(withName: "sand", recursively: false), let houseNode = buildingScene.rootNode.childNode(withName: "house", recursively: false), let coconutNode = buildingScene.rootNode.childNode(withName: "coconutTree", recursively: false) else {
                return
            }

            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = .horizontal
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
            sceneView.addGestureRecognizer(tap)
        }
        
        
    //    func addBackboard() {
    //        guard let backboardScene = SCNScene(named: "art.scnassets/hoop.scn") else {
    //            return
    //        }
    //
    //        guard let backboardNode = backboardScene.rootNode.childNode(withName: "backboard", recursively: false), let netNode = backboardScene.rootNode.childNode(withName: "net", recursively: false), let sensorNode = backboardScene.rootNode.childNode(withName: "score", recursively: false) else {
    //            return
    //        }
    //
    //        backboardNode.position = SCNVector3(x: 0, y: 0.75, z: -5)
    //        sensorNode.position = SCNVector3(x: 0, y: 0.945, z: -4.385)
    //        netNode.position = SCNVector3(x: 0, y: 0.75, z: -5.02)
    //
    //        let physicsShape = SCNPhysicsShape(node: backboardNode, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron])
    //        let physicsBody = SCNPhysicsBody(type: .static, shape: physicsShape)
    //
    //        backboardNode.physicsBody = physicsBody
    //
    //        sceneView.scene.rootNode.addChildNode(backboardNode)
    //
    //        sensorNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: sensorNode))
    //        sensorNode.physicsBody?.categoryBitMask = 8
    //        sensorNode.physicsBody?.collisionBitMask = 0
    //
    //        sceneView.scene.rootNode.addChildNode(sensorNode)
    //        sceneView.scene.rootNode.addChildNode(netNode)
    //
    //        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
    //        sceneView.addGestureRecognizer(tap)
    ////        motionManager.startAccelerometerUpdates(to: .main) { data, error in
    ////            self.handleShake(data, error)
    ////        }
    //    }
        
        var lastBall = Date()
        
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

                let ball = SCNSphere(radius: 0.15)
                let ballMaterial = SCNMaterial()
                ballMaterial.diffuse.contents = UIImage(named: "basketballSkin.png")
                ball.materials = [ballMaterial]

                let ballNode = SCNNode(geometry: ball)
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
        
    //    func handleShake(_ data: CMAccelerometerData?, _ error: Error?) {
    //        guard error == nil, let a = data?.acceleration.z else { return }
    //        let acc = abs(a)
    //        //shake strength
    //        if acc >= 1.5 && lastBall.advanced(by: 0.2).compare(Date()) == .orderedAscending {
    //            lastBall = Date()
    //
    //            guard let centerPoint = sceneView.pointOfView else { return }
    //
    //            let cameraTransform = centerPoint.transform
    //            let cameraLocation = SCNVector3(x: cameraTransform.m41, y: cameraTransform.m42, z: cameraTransform.m43)
    //            let cameraOrientation = SCNVector3(x: -cameraTransform.m31, y: -cameraTransform.m32, z: -cameraTransform.m33)
    //
    //            let cameraPosition = SCNVector3Make(cameraLocation.x + cameraOrientation.x, cameraLocation.y + cameraOrientation.y, cameraLocation.z + cameraOrientation.z)
    //
    //            let ball = SCNSphere(radius: 0.15)
    //            let ballMaterial = SCNMaterial()
    //            ballMaterial.diffuse.contents = UIImage(named: "basketballSkin.png")
    //            ball.materials = [ballMaterial]
    //
    //            let ballNode = SCNNode(geometry: ball)
    //            ballNode.position = cameraPosition
    //            ballNode.name = UUID().uuidString
    //
    //            balls.append(ballNode.name!)
    //
    //            let physicsShape = SCNPhysicsShape(node: ballNode, options: nil)
    //            let physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsShape)
    //
    //            physicsBody.contactTestBitMask = 8
    //            ballNode.physicsBody = physicsBody
    //
    //            //speed ball (normal : 3)
    //            let forceVector: Float = 5
    //            ballNode.physicsBody?.applyForce(
    //                SCNVector3(
    //                    x: cameraOrientation.x * forceVector,
    //                    y: cameraOrientation.y * Float(abs(acc)) * forceVector,
    //                    z: cameraOrientation.z * Float(abs(acc)) * forceVector
    //                ),
    //                asImpulse: true
    //            )
    //
    //            sceneView.scene.rootNode.addChildNode(ballNode)
    //        }
    //    }
        
        func horizontalAction(node: SCNNode) {
            let leftAction = SCNAction.move(by: SCNVector3(x: -1, y: 0, z: 0), duration: 2)
            let rightAction = SCNAction.move(by: SCNVector3(x: 1, y: 0, z: 0), duration: 2)
            
            let actionSequence = SCNAction.sequence([leftAction, rightAction])
            node.runAction(SCNAction.repeatForever(actionSequence))
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

        // MARK: - ARSCNViewDelegate
        
    /*
        // Override to create and configure nodes for anchors added to the view's session.
        func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
            let node = SCNNode()
         
            return node
        }
    */
        
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

    //
    extension ViewController{
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            guard let worldAnchor = anchor as? ARWorldAnchor else { return }
            
            
            let myNode = SCNNode()
            myNode.geometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
            let path = "texture.jpg"
            myNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: path)
            node.addChildNode(myNode)
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
