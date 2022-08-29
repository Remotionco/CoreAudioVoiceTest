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
    
    @State private var selectedInputDeviceID: AudioDevice.ID?
    @State private var selectedOutputDeviceID: AudioDevice.ID?
    
    @State private var selectedInputSampleRate: Float64 = 24000
    @State private var selectedOutputSampleRate: Float64 = 24000
    
    var body: some View {
        VStack {
            HStack {
                VStack {
                    Text("Input")
                    List(inputDevices, id: \.id, selection: $selectedInputDeviceID) { device in
                        Text(device.name).tag(device.id)
                    }
                    .onChange(of: selectedInputDeviceID) { deviceID in
                        guard let deviceID else {
                            selectedInputSampleRate = -1
                            return
                        }
                        selectedInputSampleRate = DeviceManager.getDevice(deviceID).sampleRate
                        runSampleRateReconciliation()
                    }
                    Picker(selection: $selectedInputSampleRate) {
                        ForEach(inputDeviceNominalRates, id: \.self) {
                            Text("\(Int($0))").tag($0)
                        }
                    } label: {
                        Text("")
                    }
                    .disabled(selectedInputDeviceID == nil)
                }
                
                VStack {
                    Text("Output")
                    List(outputDevices, id: \.id, selection: $selectedOutputDeviceID) { device in
                        Text(device.name).tag(device.id)
                    }
                    .onChange(of: selectedOutputDeviceID) { deviceID in
                        guard let deviceID else {
                            selectedOutputSampleRate = -1
                            return
                        }
                        selectedOutputSampleRate = DeviceManager.getDevice(deviceID).sampleRate
                        runSampleRateReconciliation()
                    }
                    Picker(selection: $selectedOutputSampleRate) {
                        ForEach(outputDeviceNominalRates, id: \.self) {
                            Text("\(Int($0))").tag($0)
                        }
                    } label: {
                        Text("")
                    }
                    .disabled(selectedOutputDeviceID == nil)
                }
            }
            
            Button("Setup") {
                guard let selectedInputDeviceID, let selectedOutputDeviceID else {
                    print("Select a device!")
                    return
                }
                
                var selectedInputDevice = DeviceManager.getDevice(selectedInputDeviceID)
                var selectedOutputDevice = DeviceManager.getDevice(selectedOutputDeviceID)
                
                selectedInputDevice.sampleRate = selectedInputSampleRate
                selectedOutputDevice.sampleRate = selectedOutputSampleRate
                
                print("Begin setup with selected devices: ")
                print("Input device: ", selectedInputDevice)
                print("Output device: ", selectedOutputDevice)
                
                audioManager.setupAudio(inputDevice: selectedInputDevice,
                                        outputDevice: selectedOutputDevice)
            }
            .disabled(selectedInputDeviceID == nil || selectedOutputDeviceID == nil || audioManager.isRunning)
            
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
    
    func runSampleRateReconciliation() {
        // If the selected input sample rate is available on the output side,
        // we should probably actively select it
        if let selectedOutputDeviceID,
           DeviceManager.getDevice(selectedOutputDeviceID).nominalSampleRates.contains(selectedInputSampleRate) {
            selectedOutputSampleRate = selectedInputSampleRate
        }
    }
}

// Device display functions
extension ContentView {
    private var inputDevices: [AudioDevice] {
        audioManager.listedDevices.filter { $0.deviceType.isMicrophone }
    }
    
    private var outputDevices: [AudioDevice] {
        audioManager.listedDevices.filter { $0.deviceType.isSpeaker }
    }
    
    private var inputDeviceNominalRates : [Float64] {
        guard let selectedInputDeviceID else { return [] }
        return DeviceManager.getDevice(selectedInputDeviceID).nominalSampleRates
    }
    
    private var outputDeviceNominalRates : [Float64] {
        guard let selectedOutputDeviceID else { return [] }
        return DeviceManager.getDevice(selectedOutputDeviceID).nominalSampleRates
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
