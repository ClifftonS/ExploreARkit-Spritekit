//
//  ContentView.swift
//  ExploreMC3
//
//  Created by Cliffton S on 30/07/23.
//

import SwiftUI
import RealityKit
import ARKit

struct ContentView : View {
    @State private var taprecog = false
    var body: some View {
        ARViewContainer(taprecog: $taprecog).onTapGesture {
            taprecog = true
        }
        
    }
}

struct ARViewContainer: UIViewRepresentable {
    @Binding var taprecog: Bool
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView()
        
        // Load the "Box" scene from the "Experience" Reality File
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        arView.session.run(config)
//        let boxAnchor = try! Experience.loadBall()
        // Add the box anchor to the scene
//        arView.scene.anchors.append(boxAnchor)
        let modelEntity = try! Boxtumpuk.loadBox()
        let anchorEntity = AnchorEntity()
        anchorEntity.addChild(modelEntity)
        arView.scene.addAnchor(anchorEntity)
        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        if taprecog == true{
            let ball = try! Experience.loadBall()
            
            let cameraAnchor = AnchorEntity(.camera)
            cameraAnchor.addChild(ball)
            uiView.scene.addAnchor(cameraAnchor)
//            let offsetFromCamera: SIMD3<Float> = [0, 0, -1] // Adjust the offset as needed
//            ball.transform.translation = offsetFromCamera
            
            
//            anchorEntity.addChild(modelEntity)
//            uiView.scene.addAnchor(cameraAnchor)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                uiView.scene.removeAnchor(cameraAnchor)
                taprecog = false
                
            }
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
