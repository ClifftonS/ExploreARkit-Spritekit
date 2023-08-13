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
    @State var multipeerSession: MultipeerSession?
    @State var sessionIDObservation: NSKeyValueObservation?
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView()
        
        // Start AR session
        let session = arView.session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        config.isCollaborationEnabled = true
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        session.run(config)
        
        sessionIDObservation = arView.session.observe(\.identifier, options: [.new]) { object, change in
                    print("SessionID changed to: \(change.newValue!)")
                    // Tell all other peers about your ARSession's changed ID, so
                    // that they can keep track of which ARAnchors are yours.
                    guard let multipeerSession = self.multipeerSession else { return }
                    self.sendARSessionIDTo(peers: multipeerSession.connectedPeers)
                }

        multipeerSession = MultipeerSession(serviceName: "multiuser-ar", receivedDataHandler: self.receivedData, peerJoinedHandler: self.peerJoined, peerLeftHandler: self.peerLeft, peerDiscoveredHandler: self.peerDiscovered)
        
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
        

        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(taprecog: $taprecog)
    }
    class Coordinator: NSObject, ARSessionDelegate {
        weak var view: ARView?
        var focusEntity: FocusEntity?
        var tapDetected = false
        var bolla: Entity!
        var anchorEntity: AnchorEntity!
        var originalPosition: SIMD3<Float>!
        @Binding var taprecog: Bool
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

        
        @objc func handleTap() {
            guard let view = self.view, let focusEntity = self.focusEntity else { return }
            
            if !tapDetected {
                let modelEntity = try! Boxtumpuk.loadBox()
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
//
            }

        }
        func placeObject(named entityName: String, for anchor: ARAnchor){
            guard let view = self.view else { return }
            let ballEntity = try! ModelEntity.load(named: entityName)
            let anchorsEntity = AnchorEntity(anchor: anchor)
            let modelEntity = try! Boxtumpuk.loadBox()
            anchorsEntity.addChild(ballEntity)
            view.scene.addAnchor(anchorsEntity)
            
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
            }
            
        }
    }
    
}
extension ARViewContainer {
    private func sendARSessionIDTo(peers: [PeerID]){
        guard let multipeerSession = multipeerSession else { return }
        let idString = ARView.session.identifier.uuidString
        let command = "SessionID:" + idString
        if let commandData = command.data(using: .utf8){
            multipeerSession.sendToPeers(commandData, reliably: true, peers: peers)
        }
    }

    func receivedData(_ data: Data, from peer: PeerID) {
        guard let multipeerSession = multipeerSession else { return }
        if let collaborationData = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARSession.CollaborationData.self, from: data) {
            ARView.session.update(with: collaborationData)
            return
        }
        let sessionIDCommandString = "SessionID"
        if let commandString = String(data: data, encoding: .utf8), commandString.starts(with: sessionIDCommandString){
            let newSessionID = String(commandString[commandString.index(commandString.startIndex, offsetBy: sessionIDCommandString.count)...])
            if let oldSessionID = multipeerSession.peerSessionIDs[peer] {
                removeAllAnchorsOriginatingFromARSessionWithID(oldSessionID)
            }
            multipeerSession.peerSessionIDs[peer] = newSessionID
        }
    }
    func peerDiscovered(_ peer: PeerID) -> Bool {
        guard let multipeerSession = multipeerSession else { return false }
        if multipeerSession.connectedPeers.count > 2 {
            print("This game limited to 2 players")
            return false
        } else {
            return true
        }
    }

    func peerJoined(_ peer: PeerID) {
        print("A player wants to join the game. Hold the device next to each other")
        sendARSessionIDTo(peers: [peer])
    }
    func peerLeft(_ peer: PeerID) {
        guard let multipeerSession = multipeerSession else { return }
        print("A player has left the game")
        if let sessionID = multipeerSession.peerSessionIDs[peer] {
            removeAllAnchorsOriginatingFromARSessionWithID(sessionID)
            multipeerSession.peerSessionIDs.removeValue(forKey: peer)
        }
    }

    private func removeAllAnchorsOriginatingFromARSessionWithID(_ identifier: String) {
        guard let frame = ARView.session.currentFrame else { return }
        for anchor in frame.anchors {
            guard let anchorSessionID = anchor.sessionIdentifier else { continue }
            if anchorSessionID.uuidString == identifier {
                ARView.session.remove(anchor: anchor)
            }
        }
    }
    func session(_ session: ARSession, didOutputCollaborationData data: ARSession.CollaborationData) {
        guard let multipeerSession = multipeerSession else { return }
        if !multipeerSession.connectedPeers.isEmpty {
            guard let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: true)
            else { fatalError("Unexpectedly failed to encode collaboration data.") }
            // Use reliable mode if the data is critical, and unreliable mode if the data is optional.
            let dataIsCritical = data.priority == .critical
            multipeerSession.sendToAllPeers(encodedData, reliably: dataIsCritical)
        } else {
            print("Deferred sending collaboration to later because there are no peers.")
        }
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
