//
//  ContentView.swift
//  VoiceTest
//
//  Created by John Nastos on 6/10/22.
//

import SwiftUI
import AudioToolbox
import AVFoundation

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()
    
    @State private var selectedInputDevice: AudioObjectID?
    @State private var selectedOutputDevice: AudioObjectID?
    
    @State private var inputSampleRate: Float64 = 44100.0
    @State private var outputSampleRate: Float64 = 44100.0
    
    var body: some View {
        VStack {
            HStack {
                VStack {
                    Text("Input")
                    List(audioManager.listedDevices.filter { $0.deviceType.isMicrophone }, id: \.id, selection: $selectedInputDevice) { device in
                        Text(device.name).onTapGesture {
                            selectedInputDevice = device.id
                            inputSampleRate = device.sampleRate
                        }
                    }
                }
                
                VStack {
                    Text("Output")
                    List(audioManager.listedDevices.filter { $0.deviceType.isSpeaker }, id: \.id, selection: $selectedOutputDevice) { device in
                        Text(device.name).onTapGesture {
                            selectedOutputDevice = device.id
                            outputSampleRate = device.sampleRate
                        }
                    }
                }
            }
            Button("Setup") {
                guard let selectedInputDevice = selectedInputDevice else {
                    print("Select a device!")
                    return
                }
                guard let selectedOutputDevice = selectedOutputDevice else {
                    print("Select a device!")
                    return
                }
                
                var inputDevice = DeviceManager.getDevice(selectedInputDevice)
                var outputDevice = DeviceManager.getDevice(selectedOutputDevice)

                inputDevice.sampleRate = inputSampleRate
                outputDevice.sampleRate = outputSampleRate
                
                audioManager.setupAudio(inputDevice: inputDevice,
                                        outputDevice: outputDevice)
            }
            .disabled(selectedInputDevice == nil || audioManager.isRunning)
            
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

// UI-facing functions
extension AudioManager {
    func getPermissions() {
        AVCaptureDevice.requestAccess(for: .audio) { value in
            print("Permission: \(value)")
        }
    }
    
    func listDevices() {
        self.listedDevices = DeviceManager.allDevices()
    }
    
    
    func toggleAudio() {
        guard isSetup else {
            assertionFailure("Not setup")
            return
        }
        if isRunning {
            stopAudio()
        } else {
            startAudio()
        }
    }
}
