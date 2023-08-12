//
//  ContentView.swift
//  ExploreMC3
//
//  Created by Cliffton S on 30/07/23.
//

import SwiftUI
import RealityKit
import ARKit
import FocusEntity
import MultipeerSession

struct ContentView : View {
    var body: some View {
        ARViewContainer().edgesIgnoringSafeArea(.all)
        
    }
}

struct ARViewContainer: UIViewRepresentable {
    @State var taprecog = false
//    @State var multipeerSession: MultipeerSession?
//    @State var sessionIDObservation: NSKeyValueObservation?
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView()
        
        // Start AR session
        let session = arView.session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
//        config.isCollaborationEnabled = true
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        session.run(config)
        
//        sessionIDObservation = observe(\.arView.session.indentifier, option: [.new]) { object, change
//            in
//            print("SessionID changed to: \(change.newValue!)")
//            guard let multipeerSession = self.multipeerSession else { return }
//            self.sendARSessionIDTo(peers: multipeerSession.connectedPeers)
//        }
//
//        multipeerSession = MultipeerSession(serviceName: "multiuser-ar", receivedDataHandler: self.receivedData, peerJoinedHandler: self.peerJoined, peerLeftHandler: self.peerLeft, peerDiscoveredHandler: self.peerDiscovered)
        
        // Add coaching overlay
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = session
        coachingOverlay.goal = .horizontalPlane
        arView.addSubview(coachingOverlay)
        
//        // Set debug options
//        #if DEBUG
//        arView.debugOptions = [.showFeaturePoints, .showAnchorOrigins, .showAnchorGeometry]
//        #endif
        
        // Handle ARSession events via delegate
        context.coordinator.view = arView
        session.delegate = context.coordinator
        
        
        // Handle taps
        arView.addGestureRecognizer(
            UITapGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleTap)
            )
        )
        
        
//        let boxAnchor = try! Experience.loadBall()
        // Add the box anchor to the scene
//        arView.scene.anchors.append(boxAnchor)
//        let modelEntity = try! Boxtumpuk.loadBox()
//        let anchorEntity = AnchorEntity()
//        anchorEntity.addChild(modelEntity)
//        arView.scene.addAnchor(anchorEntity)
        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        if taprecog == true{
//            let ball = try! Experience.loadBall()
//
//            let anchor = ARAnchor(name: "Experience", transform: uiView.cameraTransform.matrix)
//            let cameraAnchor = AnchorEntity(anchor: anchor)
            
//            let offsetFromCamera: SIMD3<Float> = [0, 0, -1] // Adjust the offset as needed
//            let ballPosition = cameraAnchor.convert(relativeTransform: Transform(matrix: Matrix4(simd_float4x4(diagonal: [1, 1, 1, 1]))), to: nil).columns.3
//            ball.transform.translation = offsetFromCamera + [ballPosition.x, ballPosition.y, ballPosition.z]
//            ball.transform.translation = offsetFromCamera
            
//            cameraAnchor.addChild(ball)
//            uiView.scene.addAnchor(cameraAnchor)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                uiView.scene.removeAnchor(cameraAnchor)
                taprecog = false

            }
        }
            
            
            
            
            
            
//            anchorEntity.addChild(modelEntity)
//            uiView.scene.addAnchor(cameraAnchor)
            
            
            
//        }
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(taprecog: $taprecog)
//        Coordinator(taprecog: $taprecog, transform: $transform)
    }
    class Coordinator: NSObject, ARSessionDelegate {
        weak var view: ARView?
        var focusEntity: FocusEntity?
        var tapDetected = false
        var bolla: Entity!
        var anchorEntity: AnchorEntity!
        var originalPosition: SIMD3<Float>!
        @Binding var taprecog: Bool
//        @Binding var transform: simd_float4x4
//        init(taprecog: Binding<Bool>, transform: Binding<simd_float4x4>) { // Add this initializer
//                _taprecog = taprecog
//            _transform = transform
//            }
        init(taprecog: Binding<Bool>) { // Add this initializer
                _taprecog = taprecog
            }


        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            guard let view = self.view else { return }
            debugPrint("Anchors added to the scene: ", anchors)
            if focusEntity == nil {
                self.focusEntity = FocusEntity(on: view, style: .classic(color: .yellow))
            }
            if taprecog == true{
                for anchor in anchors {
                    if let anchorName = anchor.name, anchorName == "bolamelompat" {
                        placeObject(named: anchorName, for: anchor)
                    }
//                    if let participantAnchor = anchor as? ARParticipantAnchor {
//                        print("Success conect")
//                        let anchorEntity = AnchorEntity(anchor: participantAnchor)
//                        let mesh = MeshResource.generateSphere(radius: 0.03)
//                        let color = UIColor.red
//                        let material = SimpleMaterial(color: color, isMetallic: false)
//                        let coloredSphere = ModelEntity(mesh: mesh, materials: [material])
//                        anchorEntity.addChild(coloredSphere)
//                        view.scene.addAnchor(anchorEntity)
//                    }
                }
            }
        }
//        func session(_ session: ARSession, didUpdate frame: ARFrame) {
//
//            transform = frame.camera.transform
//        }
        
        @objc func handleTap() {
            guard let view = self.view, let focusEntity = self.focusEntity else { return }
            
            if !tapDetected {
                let modelEntity = try! Boxtumpuk.loadBox()
//                bolla = modelEntity.bolla
//                originalPosition = bolla.position
//                print("posisiawl \(originalPosition)")
//                let modelEntity = try! Boxtumpuk.loadBox()
                let modelBola = try! Boxtumpuk.loadBola()
                bolla = modelBola.bolla
                originalPosition = bolla.position
                anchorEntity = AnchorEntity(plane: .horizontal)
                anchorEntity.addChild(modelEntity)
                anchorEntity.addChild(modelBola)
                view.scene.addAnchor(anchorEntity)
                let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
                        view.addGestureRecognizer(panGesture)
                tapDetected = true
                focusEntity.removeFromParent()
            } else {
//                let ballMesh = MeshResource.generateSphere(radius: 0.1)
//                                   let ballMaterial = SimpleMaterial(color: .red, isMetallic: false)
//                                   let ballModel = ModelEntity(mesh: ballMesh, materials: [ballMaterial])
//
//                                   // Create physics body for collision
//                                   let ballPhysicsShape = ShapeResource.generateSphere(radius: 0.1)
//
//                           ballModel.physicsBody = PhysicsBodyComponent(
//                               massProperties: .init(shape: ballPhysicsShape, mass: 0.5),
//                               material: nil,
//                               mode: .dynamic
//                           )
//
//
//
//
//                let anchorEntity = AnchorEntity(plane: .horizontal)
//                           view.scene.addAnchor(anchorEntity)
//
//                           anchorEntity.addChild(ballModel)
//                           ballEntity = ballModel
//
//                           let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
//                           view.addGestureRecognizer(panGesture)
//                if taprecog == false {
//
//                    let anchor = ARAnchor(name: "bolamelompat", transform: view.cameraTransform.matrix)
//                    view.session.add(anchor: anchor)
//                    taprecog = true
//                }
            }
            // Create a new anchor to add content to
//            let anchor = AnchorEntity()
//            view.scene.anchors.append(anchor)
//
//            // Add a Box entity with a blue material
//            let diceEntity = try! ModelEntity.loadModel(named: "Dice")
//            diceEntity.scale = [0.1, 0.1, 0.1]
//            diceEntity.position = focusEntity.position
//            let size = diceEntity.visualBounds(relativeTo: diceEntity).extents
//            let boxShape = ShapeResource.generateBox(size: size)
//            diceEntity.collision = CollisionComponent(shapes: [boxShape])
//            diceEntity.physicsBody = PhysicsBodyComponent(
//                massProperties: .init(shape: boxShape, mass: 50),
//                material: nil,
//                mode: .dynamic
//            )
//            anchor.addChild(diceEntity)
            
            
            
            
            
            
            // Create a plane below the dice
//            let planeMesh = MeshResource.generatePlane(width: 2, depth: 2)
//            let material = SimpleMaterial(color: .init(white: 1.0, alpha: 0.5), isMetallic: false)
//            let planeEntity = ModelEntity(mesh: planeMesh, materials: [material])
//            planeEntity.position = focusEntity.position
//            planeEntity.physicsBody = PhysicsBodyComponent(massProperties: .default, material: nil, mode: .static)
//            planeEntity.collision = CollisionComponent(shapes: [.generateBox(width: 2, height: 0.001, depth: 2)])
//            planeEntity.position = focusEntity.position
//            anchor.addChild(planeEntity)

//            diceEntity.addForce([0, 2, 0], relativeTo: nil)
//            diceEntity.addTorque([Float.random(in: 0 ... 0.4), Float.random(in: 0 ... 0.4), Float.random(in: 0 ... 0.4)], relativeTo: nil)
            

        }
        func placeObject(named entityName: String, for anchor: ARAnchor){
            guard let view = self.view else { return }
            let ballEntity = try! ModelEntity.load(named: entityName)
            let anchorsEntity = AnchorEntity(anchor: anchor)
            let modelEntity = try! Boxtumpuk.loadBox()
            anchorsEntity.addChild(ballEntity)
            view.scene.addAnchor(anchorsEntity)
//            let ballMesh = MeshResource.generateSphere(radius: 0.1)
//                    let ballMaterial = SimpleMaterial(color: .red, isMetallic: false)
//                    let ballModel = ModelEntity(mesh: ballMesh, materials: [ballMaterial])
//
//                    // Create physics body for collision
//                    let ballPhysicsShape = ShapeResource.generateSphere(radius: 0.1)
//
//            ballModel.physicsBody = PhysicsBodyComponent(
//                massProperties: .init(shape: ballPhysicsShape, mass: 0.5),
//                material: nil,
//                mode: .dynamic
//            )
                    
                    
                    
                    
//            let anchorEntity = AnchorEntity(anchor: anchor)
//            view.scene.addAnchor(anchorEntity)
//            let position = SIMD3<Float>(0, -0.2, -0.6) // -10 cm in meters
//                    ballModel.position = position
//            anchorEntity.addChild(ballModel)
//            ballEntity = ballModel
            
//            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
//            view.addGestureRecognizer(panGesture)
//            let modelEntity = try! Boxtumpuk.loadBola()
//            let anchorsEntity = AnchorEntity()
//            anchorsEntity.addChild(modelEntity)
//            view.scene.addAnchor(anchorsEntity)
            
        }
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = self.view else { return }
            var translation = gesture.translation(in: view)
            let location = gesture.location(in: view)
            let locationVector = SIMD3<Float>(Float(location.x), Float(location.y), 0)
                
                // Calculate the distance between gesture location and bolla's position
                let distance = simd_distance(locationVector, bolla.position)
            
            if gesture.state == .began{
                //                if let hitEntity = view.entity(at: location), hitEntity == bolla {
                
                //                                isPanning = true
                //                            }
            }
            else if gesture.state == .changed {
                // Get the translation of the gesture in the ARView's coordinate system
                
                    translation = gesture.translation(in: view)
                
                
            } else if gesture.state == .ended {
                print("Float translation x \(-Float(translation.x) * 0.0001)")
                print("Float translation y \(-Float(translation.y) * 0.0001)")
                print("Float translation z \(distance)")
                
                    if let physicsEntity = bolla as? Entity & HasPhysics {
                    physicsEntity.applyLinearImpulse([-Float(translation.x) * 0.0005, 0.01, -Float(translation.y) * 0.0005], relativeTo: physicsEntity.parent)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4){
                        self.bolla.removeFromParent()
                        let modelBola = try! Boxtumpuk.loadBola()
                        
                        self.bolla = modelBola.bolla
                        self.bolla.position = self.originalPosition
                        self.anchorEntity.addChild(self.bolla)
                    }
                
                }
            
//                DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
//                    self?.bolla.position = self?.originalPosition ?? .zero
//                    print("posisiakr \(self?.bolla.position)")
//                }
//                {
//                    bolla.position = self.originalPosition
//
//                    print("posisiakr \(bolla.position)")
//                }
            }
            
        }
    }
    
}
//extension ARViewContainer {
//    private func sendARSessionIDTo(peers: [PeerID]){
//        guard let multipeerSession = multipeerSession else { return }
//        let idString = ARView.session.identifier.uuidString
//        let command = "SessionID:" + idString
//        if let commandData = command.data(using: .utf8){
//            multipeerSession.sendToPeers(commandData, reliably: true, peers: peers)
//        }
//    }
//
//    func receivedData(_ data: Data, from peer: PeerID) {
//        guard let multipeerSession = multipeerSession else { return }
//        if let collaborationData = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARSession.CollaborationData.self, from: data) {
//            ARView.session.update(with: collaborationData)
//            return
//        }
//        let sessionIDCommandString = "SessionID"
//        if let commandString = String(data: data, encoding: .utf8), commandString.starts(with: sessionIDCommandString){
//            let newSessionID = String(commandString[commandString.index(commandString.startIndex, offsetBy: sessionIDCommandString.count)...])
//            if let oldSessionID = multipeerSession.peerSessionIDs[peer] {
//                removeAllAnchorsOriginatingFromARSessionWithID(oldSessionID)
//            }
//            multipeerSession.peerSessionIDs[peer] = newSessionID
//        }
//    }
//    func peerDiscovered(_ peer: PeerID) -> Bool {
//        guard let multipeerSession = multipeerSession else { return false }
//        if multipeerSession.connectedPeers.count > 2 {
//            print("This game limited to 2 players")
//            return false
//        } else {
//            return true
//        }
//    }
//
//    func peerJoined(_ peer: PeerID) {
//        print("A player wants to join the game. Hold the device next to each other")
//        sendARSessionIDTo(peers: [peer])
//    }
//    func peerLeft(_ peer: PeerID) {
//        guard let multipeerSession = multipeerSession else { return }
//        print("A player has left the game")
//        if let sessionID = multipeerSession.peerSessionIDs[peer] {
//            removeAllAnchorsOriginatingFromARSessionWithID(sessionID)
//            multipeerSession.peerSessionIDs.removeValue(forKey: peer)
//        }
//    }
//
//    private func removeAllAnchorsOriginatingFromARSessionWithID(_ identifier: String) {
//        guard let frame = ARView.session.currentFrame else { return }
//        for anchor in frame.anchors {
//            guard let anchorSessionID = anchor.sessionIdentifier else { continue }
//            if anchorSessionID.uuidString == identifier {
//                ARView.session.remove(anchor: anchor)
//            }
//        }
//    }
//    func session(_ session: ARSession, didOutputCollaborationData data: ARSession.CollaborationData) {
//        guard let multipeerSession = multipeerSession else { return }
//        if !multipeerSession.connectedPeers.isEmpty {
//            guard let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: true)
//            else { fatalError("Unexpectedly failed to encode collaboration data.") }
//            // Use reliable mode if the data is critical, and unreliable mode if the data is optional.
//            let dataIsCritical = data.priority == .critical
//            multipeerSession.sendToAllPeers(encodedData, reliably: dataIsCritical)
//        } else {
//            print("Deferred sending collaboration to later because there are no peers.")
//        }
//    }
//}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
