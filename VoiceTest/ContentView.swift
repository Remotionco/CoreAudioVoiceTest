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
    
    @State private var selectedInputDevice: AudioObjectID?
    @State private var selectedOutputDevice: AudioObjectID?
    
    @State private var inputSampleRate: Float64 = 44100.0
    @State private var outputSampleRate: Float64 = 44100.0
    
    @State private var voiceProcessing = true
    
    private let sampleRateOptions: [Float64] = [16000.0,24000.0,32000.0,44100.0,48000]
    
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
                    Picker(selection: $inputSampleRate) {
                        ForEach(sampleRateOptions, id: \.self) {
                            Text("\(Int($0))").tag($0)
                        }
                    } label: {
                        Text("")
                    }
                    .disabled(selectedInputDevice == nil)
                }
                
                VStack {
                    Text("Output")
                    List(audioManager.listedDevices.filter { $0.deviceType.isSpeaker }, id: \.id, selection: $selectedOutputDevice) { device in
                        Text(device.name).onTapGesture {
                            selectedOutputDevice = device.id
                            outputSampleRate = device.sampleRate
                        }
                    }
                    Picker(selection: $outputSampleRate) {
                        ForEach(sampleRateOptions, id: \.self) {
                            Text("\(Int($0))").tag($0)
                        }
                    } label: {
                        Text("")
                    }
                    .disabled(selectedOutputDevice == nil)
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
                
                var inputDevice = DeviceManager.getDevice(selectedInputDevice)
                var outputDevice = DeviceManager.getDevice(selectedOutputDevice)

                inputDevice.sampleRate = inputSampleRate
                outputDevice.sampleRate = outputSampleRate
                
                audioManager.setupAudio(inputDevice: inputDevice,
                                        outputDevice: outputDevice,
                                        subType: voiceProcessing ? .VPIO : .HAL)
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
