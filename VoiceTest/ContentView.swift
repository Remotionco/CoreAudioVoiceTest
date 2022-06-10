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
    @State private var selectedOutputDevice: AudioDeviceID?
    
    @State private var voiceProcessing = true
    
    var body: some View {
        VStack {
            HStack {
                VStack {
                    Text("Input")
                    List(audioManager.listedDevices.filter { $0.deviceType.isMicrophone }, id: \.id, selection: $selectedInputDevice) { device in
                        Text(device.0).onTapGesture {
                            selectedInputDevice = device.id
                        }
                    }
                }
                
                VStack {
                    Text("Output")
                    List(audioManager.listedDevices.filter { $0.deviceType.isSpeaker }, id: \.id, selection: $selectedOutputDevice) { device in
                        Text(device.0).onTapGesture {
                            selectedOutputDevice = device.id
                        }
                    }
                }
            }
            
            Toggle("VPIO", isOn: $voiceProcessing)
            
            Button("Setup") {
                guard let selectedInputDevice = selectedInputDevice else {
                    print("Select a device!")
                    return
                }
                guard let selectedOutputDevice = selectedOutputDevice else {
                    print("Select a device!")
                    return
                }

                audioManager.setupAudio(inputDeviceID: selectedInputDevice,
                                        outputDeviceID: selectedOutputDevice,
                                        subType: voiceProcessing ? .VPIO : .HAL)
            }
            .disabled(selectedInputDevice == nil)
            
            Button(audioManager.isRunning ? "Stop" : "Start") {
                audioManager.toggleAudio()
            }
            .disabled(!audioManager.isSetup)
        }
        .padding()
        .onAppear {
            audioManager.getPermissions()
            audioManager.listDevices()
        }
    }
}
