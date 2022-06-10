//
//  ContentView.swift
//  VoiceTest
//
//  Created by John Nastos on 6/10/22.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()
    
    var body: some View {
        VStack {
            Button("Setup") {
                audioManager.setupAudio()
            }
            
            Button(audioManager.isRunning ? "Stop" : "Start") {
                audioManager.toggleAudio()
            }
            .disabled(!audioManager.isSetup)
        }
        .padding()
    }
}
