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
import AVFoundation

var audioPlayer : AVAudioPlayer?
struct ContentView : View {
    @StateObject var vm = ARViewModel()
    @State private var hasWon = false
    var body: some View {
        ZStack{
            ARViewContainer(hasWon: $hasWon).edgesIgnoringSafeArea(.all).environmentObject(vm).onAppear(perform: self.playSound)
            if hasWon { // Display overlay when hasWon is true
                CongratulationOverlay()
            } else{
                if vm.losedata.isLose == true {
                    LoseOverlay()
                }
            }
        }
    }
    func playSound(){
          
            //getting the resource path
            let resourcePath = Bundle.main.url(forResource: "stranger", withExtension: "mp3")
            
            do{
                //initializing audio player with the resource path
                audioPlayer = try AVAudioPlayer(contentsOf: resourcePath!)
                
                //play the audio
//                audioPlayer?.play()
            }
            catch{
              //error handling
                print(error.localizedDescription)
            }
        }
}
struct CongratulationOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.5) // Semi-transparent background
            VStack {
                Text("Congratulations!")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                Text("You won!")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}
struct LoseOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.5) // Semi-transparent background
            VStack {
                Text("Oops!")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                Text("You lost!")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}
struct ARViewContainer: UIViewRepresentable {
    @Binding var hasWon: Bool
    @EnvironmentObject var vm: ARViewModel
    typealias UIViewType = ARView
    func makeUIView(context: Context) -> ARView {
        context.coordinator.hasWon = $hasWon
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
        var fallingObjects: [Entity?] = []
        var hasWon: Binding<Bool>
        
        init(_ parent: ARViewContainer, hasWon: Binding<Bool>) {
            self.parent = parent
            self.hasWon = hasWon
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
            
            let loseData = self.parent.vm.losedata
                do {
                    let loseDataEncoded = try JSONEncoder().encode(loseData)
                    multipeerSession.sendToAllPeers(loseDataEncoded, reliably: true) // You can adjust reliability as needed
                } catch let error {
                    print("Error encoding 'isLost' data: \(error)")
                }
        }
        func placeSceneObject(named entityName: String, for anchor: ARAnchor){
            let modelEntity = try! ModelFix.loadBox()
            let modelBola = try! ModelFix.loadBola()
            for x in 0...7{
                let boxIndex = "box\(x+1)"
                    if let boxModel = modelEntity.findEntity(named: boxIndex) {
                        fallingObjects.append(boxModel)
                    }
            }
            bolla = modelBola.bolla
            originalPosition = bolla.position
            anchorEntity = AnchorEntity(plane: .horizontal)
            anchorEntity.addChild(modelEntity)
            anchorEntity.addChild(modelBola)
            self.parent.vm.arView.scene.addAnchor(anchorEntity)
            for _ in 0...2{
                let planeModel = buildPlane()
                plane.append(planeModel)
                self.anchorEntity.addChild(planeModel)
            }
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            self.parent.vm.arView.addGestureRecognizer(panGesture)
        }
//        func sendImpulseData(_ impulse: SIMD3<Float>) {
//            guard let multipeerSession = self.parent.vm.multipeerSession else { return }
//
//            let impulseData = try! NSKeyedArchiver.archivedData(withRootObject: impulse, requiringSecureCoding: true)
//            multipeerSession.sendToAllPeers(impulseData, reliably: true) // Ubah menjadi true jika data ini kritis.
//        }
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
                for i in 0...2{
                    plane[i].isEnabled = false
                }
                translation = gesture.translation(in: self.parent.vm.arView)
                var counter = 0
                while counter < plane.count{
                    let translationX = (Float(translation.x) * 0.0008) * Float(counter+1)
                    let translationY = (Float(translation.y) * 0.00008) * Float(counter+1)
                    let translationZ = (Float(translation.y) * 0.0008) * Float(counter+1)
                    
                    plane[counter].position.x = bolla.position.x - translationX
                    plane[counter].position.y = bolla.position.y + translationY
                    plane[counter].position.z = bolla.position.z - translationZ
                    
                    plane[counter].isEnabled = true
                    counter += 1
                }
                
                
            } else if gesture.state == .ended {
                for i in 0...2{
                    plane[i].isEnabled = false
                }
                if let physicsEntity = bolla as? Entity & HasPhysics {
                    physicsEntity.applyLinearImpulse([-Float(translation.x) * 0.0008, -Float(translation.y/2) * 0.0005, -Float(translation.y) * 0.0008], relativeTo: physicsEntity.parent)
//                    sendImpulseData([-Float(translation.x) * 0.0008, -Float(translation.y/2) * 0.0008, -Float(translation.y) * 0.0008])
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4){
//                        for x in 0..<self.fallingObjects.count {
//                            if let fallingObject = self.fallingObjects[x] {
//                                if x <= 3{
//                                    if fallingObject.position.y < -0.1{
//                                        self.fall += 1
//                                    }
//                                } else if x > 3 && x <= 6 {
//                                    if fallingObject.position.y < 0.02{
//                                        self.fall += 1
//                                    }
//                                }else{
//                                    if fallingObject.position.y < -0.1{
//                                        self.fall += 1
//                                    }
//                                }
//
//                                if self.fall == 8 {
//                                    self.hasWon = true
//                                    print("Congratulations! You win!")
//                                }
//                                print("posisibox \(fallingObject.position.y)")
//                            }
//                        }
                        
                        if let fallingObject = self.fallingObjects[6] {
                            print("posisibox \(fallingObject.position.y)")
                            if fallingObject.position.y < 0.0 || fallingObject.position.y > 0.3{
                                if self.parent.vm.losedata.isLose == false{
                                    self.hasWon.wrappedValue = true
                                    self.parent.vm.losedata.isLose = true
                                }
                            }
                        }
                        
                        
                        
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
        return Coordinator(self, hasWon: $hasWon)
    }
}
#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
