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

struct ContentView : View {
    @StateObject var vm = ARViewModel()
    var body: some View {
        ARViewContainer().edgesIgnoringSafeArea(.all).environmentObject(vm)
    }
}

struct ARViewContainer: UIViewRepresentable {
    @EnvironmentObject var vm: ARViewModel
    typealias UIViewType = ARView
    func makeUIView(context: Context) -> ARView {
        
        vm.arView.session.delegate = context.coordinator
//        _ = FocusEntity(on: vm.arView, style: .classic(color: .yellow))
                
        return vm.arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}
extension ARView {
    // Extned ARView to implement tapGesture handler
    // Hybrid workaround between UIKit and SwiftUI
    func enableTapGesture() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        self.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        let tapLocation = recognizer.location(in: self)
                            
        // Attempt to find a 3D location on a horizontal surface underneath the user's touch location.
        let results = self.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .any)
        
        if let firstResult = results.first {
            // Add an ARAnchor at the touch location with a special name you check later in `session(_:didAdd:)`.
            let anchor = ARAnchor(name: "ball5", transform: firstResult.worldTransform)
            self.session.add(anchor: anchor)
        } else {
            print("Warning: Object placement failed.")
        }
    }
}

extension ARViewContainer {
    // Communicate changes from UIView to SwiftUI by updating the properties of your coordinator
    // Confrom the coordinator to ARSessionDelegate
    
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARViewContainer
        var bolla: Entity!
        var anchorEntity: AnchorEntity!
        var originalPosition: SIMD3<Float>!
        var tapdetected: Bool = false
        var plane = [ModelEntity]()
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
                
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            for anchor in anchors {
                if let participantAnchor = anchor as? ARParticipantAnchor{
                    print("Established joint experience with a peer.")
                    
                    let anchorEntity = AnchorEntity(anchor: participantAnchor)
                    let mesh = MeshResource.generateSphere(radius: 0.03)
                    let color = UIColor.red
                    let material = SimpleMaterial(color: color, isMetallic: false)
                    let coloredSphere = ModelEntity(mesh:mesh, materials:[material])
                    
                    anchorEntity.addChild(coloredSphere)
                    
                    self.parent.vm.arView.scene.addAnchor(anchorEntity)
                } else {
                    if let anchorName = anchor.name, anchorName == "ball5" {
                        if tapdetected == false{
                            self.placeSceneObject(named: anchorName, for: anchor)
                            tapdetected = true
                        }
                        
                    }
                }
            }
        }
        
        func session(_ session: ARSession, didOutputCollaborationData data: ARSession.CollaborationData) {
            guard let multipeerSession = self.parent.vm.multipeerSession else { return }
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
        func placeSceneObject(named entityName: String, for anchor: ARAnchor){
            let modelEntity = try! ModelFix.loadBox()
            let modelBola = try! ModelFix.loadBola()
            bolla = modelBola.bolla
            originalPosition = bolla.position
            anchorEntity = AnchorEntity(plane: .horizontal)
            anchorEntity.addChild(modelEntity)
            anchorEntity.addChild(modelBola)
            self.parent.vm.arView.scene.addAnchor(anchorEntity)
            for _ in 0...3{
                let planeModel = buildPlane()
                plane.append(planeModel)
                self.anchorEntity.addChild(planeModel)
            }
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            self.parent.vm.arView.addGestureRecognizer(panGesture)
        }
        func buildPlane() -> ModelEntity{
            let plane = ModelEntity(mesh: .generateSphere(radius: 0.02), materials: [SimpleMaterial(color: UIColor.white, roughness: 0, isMetallic: false)])
            plane.position.y = bolla.position.y
            plane.position.x = bolla.position.x
            plane.position.z = bolla.position.z
            plane.isEnabled = false
            return plane
        }
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            var translation = gesture.translation(in: self.parent.vm.arView)
            let location = gesture.location(in: self.parent.vm.arView)
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
                for i in 0...3{
                    plane[i].isEnabled = false
                }
                translation = gesture.translation(in: self.parent.vm.arView)
                var counter = 0
                while counter < plane.count{
                    let translationX = (Float(translation.x) * 0.0008) * Float(counter+1)
                    let translationY = (Float(translation.y) * 0.0003) * Float(counter+1)
                    let translationZ = (Float(translation.y) * 0.0008) * Float(counter+1)
                    
                    plane[counter].position.x = bolla.position.x - translationX
                    plane[counter].position.y = bolla.position.y + translationY
                    plane[counter].position.z = bolla.position.z - translationZ
                    
                    plane[counter].isEnabled = true
                    counter += 1
                }
                
                
            } else if gesture.state == .ended {
                for i in 0...3{
                    plane[i].isEnabled = false
                }
                if let physicsEntity = bolla as? Entity & HasPhysics {
                    physicsEntity.applyLinearImpulse([-Float(translation.x) * 0.0008, -Float(translation.y) * 0.0003, -Float(translation.y) * 0.0008], relativeTo: physicsEntity.parent)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4){
                        self.bolla.removeFromParent()
                        let modelBola = try! ModelFix.loadBola()
                        self.bolla = modelBola.bolla
                        self.anchorEntity.addChild(self.bolla)
                    }
                    
                }
            }
        }
            
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
}
#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
