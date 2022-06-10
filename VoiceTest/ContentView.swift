//
//  ContentView.swift
//  VoiceTest
//
//  Created by John Nastos on 6/10/22.
//

import SwiftUI
import AudioToolbox

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()
    
    @State private var selectedInputDevice: AudioDeviceID?
    
    var body: some View {
        VStack {
            List(audioManager.listedDevices, id: \.id, selection: $selectedInputDevice) { device in
                Text(device.0).onTapGesture {
                    selectedInputDevice = device.id
                }
            }
            
            Button("List") {
                audioManager.getPermissions()
                audioManager.listDevices()
            }
            
            Button("Setup") {
                audioManager.setupAudio(deviceID: selectedInputDevice ?? 0)
            }
            .disabled(selectedInputDevice == nil)
            
            Button(audioManager.isRunning ? "Stop" : "Start") {
                audioManager.toggleAudio()
            }
            .disabled(!audioManager.isSetup)
        }
        .padding()
    }
}
