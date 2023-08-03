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
    @State private var taprecog = false
    var body: some View {
        ARViewContainer().edgesIgnoringSafeArea(.all)
        
    }
}

struct ARViewContainer: UIViewRepresentable {
    @State var taprecog = false
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView()
        
        // Start AR session
        let session = arView.session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        session.run(config)
        
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
            let ball = try! Experience.loadBall()

            let cameraAnchor = AnchorEntity(.camera)
            cameraAnchor.addChild(ball)
            uiView.scene.addAnchor(cameraAnchor)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                uiView.scene.removeAnchor(cameraAnchor)
                taprecog = false

            }
        }
            
            
            
//            let offsetFromCamera: SIMD3<Float> = [0, 0, -1] // Adjust the offset as needed
//            ball.transform.translation = offsetFromCamera
            
            
//            anchorEntity.addChild(modelEntity)
//            uiView.scene.addAnchor(cameraAnchor)
            
            
            
//        }
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(taprecog: $taprecog)
    }
    class Coordinator: NSObject, ARSessionDelegate {
        weak var view: ARView?
        var focusEntity: FocusEntity?
        var tapDetected = false
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
        }
        @objc func handleTap() {
            guard let view = self.view, let focusEntity = self.focusEntity else { return }
            
            if !tapDetected {
                let modelEntity = try! Boxtumpuk.loadBox()
                let anchorEntity = AnchorEntity(plane: .horizontal)
                        anchorEntity.addChild(modelEntity)
                        view.scene.addAnchor(anchorEntity)
                tapDetected = true
                focusEntity.removeFromParent()
            } else {
                taprecog = true
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
    }
    
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
