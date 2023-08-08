//import SwiftUI
import RealityKit
import ARKit
import UIKit

//struct ContentView : View {
//    var body: some View {
//        ARViewContainer().edgesIgnoringSafeArea(.all)
//    }
//}

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    override func viewDidAppear(_ animated: Bool){
        super.viewDidAppear(animated)
        
        setupARView()
        
        arView.session.delegate = self
        
        let tapGestureRognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        arView.addGestureRecognizer(tapGestureRognizer)
    }
    
    func setupARView(){
        arView.automaticallyConfigureSession = false
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        
        arView.session.run(config)
    }
    
    
    @objc func handleTap(recognizer: UITapGestureRecognizer){
        let anchor = ARAnchor(name: "cannonBall", transform: arView!.cameraTransform.matrix)
        arView.session.add(anchor: anchor)
    }
    
    func placeObject(named entityName: String, for anchor: ARAnchor){
        let cannonEntity = try! ModelEntity.load(named: entityName)
        let anchorEntity = try! AnchorEntity(anchor: anchor)
        anchorEntity.addChild(cannonEntity)
        arView.scene.addAnchor(anchorEntity)
    }
}

extension ViewController: ARSessionDelegate{
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]){
        for anchor in anchors {
            if let anchorName = anchor.name, anchorName == "cannonBall"{
                placeObject(named: anchorName, for: anchor)
            }
        }
    }
}
                        
                                
                                
#if DEBUG
//struct ContentView_Previews : PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
#endif
