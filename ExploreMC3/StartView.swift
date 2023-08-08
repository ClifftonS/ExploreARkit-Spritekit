//
//  StartView.swift
//  ExploreMC3
//
//  Created by Cliffton S on 08/08/23.
//

import SwiftUI

struct StartView: View {
    @EnvironmentObject var rpsSession: MultipeerSession?
        
        @Binding var currentView: Int
        var logger = Logger()
            
        var body: some View {
            if (!rpsSession.paired) {
                HStack {
                    List(rpsSession.availablePeers, id: \.self) { peer in
                        Button(peer.displayName) {
                            rpsSession.serviceBrowser.invitePeer(peer, to: rpsSession.session, withContext: nil, timeout: 30)
                        }
                    }
                }
                .alert("Received an invite from \(rpsSession.recvdInviteFrom?.displayName ?? "ERR")!", isPresented: $rpsSession.recvdInvite) {
                    Button("Accept invite") {
                        if (rpsSession.invitationHandler != nil) {
                            rpsSession.invitationHandler!(true, rpsSession.session)
                        }
                    }
                    Button("Reject invite") {
                        if (rpsSession.invitationHandler != nil) {
                            rpsSession.invitationHandler!(false, nil)
                        }
                    }
                }
            } else {
                GameView(currentView: $currentView)
                    .environmentObject(rpsSession)
            }
        }
}

struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        StartView()
    }
}
