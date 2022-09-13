//
//  Audio.swift
//  VoiceTest
//
//  Created by John Nastos on 6/10/22.
//

import Foundation
import AudioToolbox
import AVFoundation
import SoundAnalysis

private var context = CustomAudioContext()
private let contextPointer = UnsafeMutablePointer(&context)

class AudioManager: ObservableObject {
    @Published var isSetup = false
    @Published var isRunning = false
    @Published var listedDevices: [AudioDevice] = []
    
    private var streamAnalyzer: SNAudioStreamAnalyzer!
    private let analysisQueue = DispatchQueue(label: "com.example.AnalysisQueue")
    private let resultsObserver = SoundResultsObserver()

    private var buffer: AVAudioPCMBuffer!
    let engine = AVAudioEngine()

    
    func analyze(data: [Float32], timeStamp: UnsafePointer<AudioTimeStamp>) {
        
        let magnitude = data.reduce(0) { partialResult, item in
            return partialResult + abs(item)
        }
        //print("Got data in: ", data.count, magnitude, timeStamp.pointee.mSampleTime)
        var data = data
        memcpy(buffer.floatChannelData![0], &data, 441 * 4) // 4 = sizeof(Float32)
        analysisQueue.async {
            self.streamAnalyzer.analyze(self.buffer, atAudioFramePosition: AVAudioFramePosition(timeStamp.pointee.mSampleTime))
        }
    }
    
    func setupAudio(inputDevice: AudioDevice, outputDevice: AudioDevice) {
        // Setup the audio units
        do {
            let audioUnit = try DeviceManager.makeUniversalAudioUnit(
                rawContext: contextPointer,
                inputAudioDeviceID: inputDevice.id,
                inputSampleRate: inputDevice.sampleRate,
                outputAudioDeviceID: outputDevice.id,
                outputSampleRate: outputDevice.sampleRate)
            
            contextPointer.pointee.audioUnit = audioUnit
                        
            var desc = FormatManager.makeAudioStreamBasicDescription(sampleRate: inputDevice.sampleRate)
            
            print(desc)
            
            let format = AVAudioFormat(streamDescription: &desc)!
            
            print("Input format: ", format)
            
            streamAnalyzer = SNAudioStreamAnalyzer(format: format)
            let request = try SNClassifySoundRequest(classifierIdentifier: SNClassifierIdentifier.version1)
            
            print(request.knownClassifications)
            
            try streamAnalyzer.add(request, withObserver: resultsObserver)
            buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 441)
            buffer.frameLength = 441
            
            let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
            
            let unsafe = UnsafeMutableRawPointer(mutating: observer)
            
            var callbacks = AudioCallbacks(
                audioData: { (data, inNumberFrames, timeStamp, observer) in
                    let float4Ptr = data.bindMemory(to: Float32.self, capacity: Int(inNumberFrames))
                    let float4Buffer = UnsafeBufferPointer(start: float4Ptr, count: Int(inNumberFrames))
                    let output = Array(float4Buffer)
                    
                    let mySelf = Unmanaged<AudioManager>.fromOpaque(observer).takeUnretainedValue()
                    mySelf.analyze(data: output, timeStamp: timeStamp)
                }, observer: unsafe
            )
            
            contextPointer.pointee.callbacks = callbacks
            
//            engine.inputNode.installTap(onBus: AVAudioNodeBus(0),
//                                             bufferSize: 8192,
//                                             format: format)
//                                        { (buffer, time) in
//                                            self.streamAnalyzer.analyze(buffer, atAudioFramePosition: time.sampleTime)
//            }
//            try engine.start()
        } catch {
            assertionFailure("Setup error: \(error)")
        }
        
        isSetup = true
        print("Setup success")
    }
    
    func startAudio() {
        guard let audioUnit = contextPointer.pointee.audioUnit else {
            assertionFailure()
            return
        }
        do {
            try startAudioUnit(audioUnit)
        } catch {
            assertionFailure("Start audioUnit error: \(error)")
        }
        
        self.isRunning = true
        print("Started")
    }
    
    private func startAudioUnit(_ audioUnit: AudioUnit) throws {
        var error: OSStatus = noErr
        error = AudioUnitInitialize(audioUnit)
        guard error == noErr else {
            throw CustomAudioPipelineError.couldNotInitialize(error: error)
        }
        
        error = AudioOutputUnitStart(audioUnit)
        guard error == noErr else {
            throw CustomAudioPipelineError.couldNotStart(error: error)
        }
    }
    
    func stopAudio() {
        guard let audioUnit = contextPointer.pointee.audioUnit else {
            assertionFailure()
            return
        }
        stopAudioUnit(audioUnit)
        self.isRunning = false
    }
    
    private func stopAudioUnit(_ audioUnit: AudioUnit) {
        var error: OSStatus = noErr
        
        error = AudioOutputUnitStop(audioUnit)
        
        if error != noErr {
            assertionFailure("Stop error: \(error)")
        }
    }
}

class SoundResultsObserver: NSObject, SNResultsObserving {
    
    func request(_ request: SNRequest, didProduce result: SNResult) { // Mark 1
        
        guard let result = result as? SNClassificationResult else { return } // Mark 2
        
        guard let classification = result.classifications.first else { return } // Mark 3
        
        let timeInSeconds = result.timeRange.start.seconds // Mark 4
        
        let formattedTime = String(format: "%.2f", timeInSeconds)
        print("Analysis result for audio at time: \(formattedTime)")
        
        let confidence = classification.confidence * 100.0
        let percentString = String(format: "%.2f%%", confidence)
        
        print("\(classification.identifier): \(percentString) confidence.\n") // Mark 5
    }
    
    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("The the analysis failed: \(error.localizedDescription)")
    }
    
    func requestDidComplete(_ request: SNRequest) {
        print("The request completed successfully!")
    }
}

class DeviceManager {
    var activeInputID: AudioObjectID?
    var activeOutputID: AudioObjectID?
    
    private class func makeAudioComponentDescription() -> AudioComponentDescription {
        var audioComponentDescription = AudioComponentDescription()
        audioComponentDescription.componentType = kAudioUnitType_Output
        audioComponentDescription.componentSubType = kAudioUnitSubType_VoiceProcessingIO
        audioComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple
        audioComponentDescription.componentFlags = 0
        audioComponentDescription.componentFlagsMask = 0
        
        return audioComponentDescription
    }
    
    class func makeUniversalAudioUnit(
        rawContext: UnsafeMutableRawPointer,
        inputAudioDeviceID: AudioObjectID,
        inputSampleRate: Float64,
        outputAudioDeviceID: AudioObjectID,
        outputSampleRate: Float64
    ) throws -> AudioUnit
    {
        var audioComponentDescription: AudioComponentDescription = makeAudioComponentDescription()
        
        guard let audioComponent = AudioComponentFindNext(nil, &audioComponentDescription) else {
            throw AudioUnitInputCreationError.cantFindAudioOutputComponent
        }
        
        var optionalAudioUnit: AudioUnit?
        var error = AudioComponentInstanceNew(audioComponent, &optionalAudioUnit)
        
        /*
         Note that by this point, even with devices that work (like the Macbook internal mic and speakers, we already
         see this in the console:
         
         Failed to set output device tap stream physical format =  2 ch,  48000 Hz, Float32, interleaved, err=1852797029
         */
        
        guard error == noErr else {
            throw AudioUnitInputCreationError.cantInstantiateOutputComponent(error: error)
        }
        
        guard let audioUnit: AudioUnit = optionalAudioUnit else {
            throw AudioUnitInputCreationError.audioUnitNil
        }
        
        // Enable IO on the input
        error = AudioUnitSetProperty(audioUnit,
                                     kAudioOutputUnitProperty_EnableIO,
                                     kAudioUnitScope_Input,
                                     inputBus,
                                     &enabled,
                                     size(of: enabled))
        guard error == noErr else {
            throw AudioUnitInputCreationError.cantEnableInputIO(error: error)
        }
        
//        error = AudioUnitSetProperty(audioUnit,
//                                     kAUVoiceIOProperty_BypassVoiceProcessing,
//                                     kAudioUnitScope_Input,
//                                     inputBus,
//                                     &enabled,
//                                     size(of: enabled))
//        guard error == noErr else {
//            throw AudioUnitInputCreationError.cantEnableInputIO(error: error)
//        }
        
        // Enable IO on the output
        error = AudioUnitSetProperty(audioUnit,
                                     kAudioOutputUnitProperty_EnableIO,
                                     kAudioUnitScope_Output,
                                     outputBus,
                                     &enabled,
                                     size(of: enabled))
        guard error == noErr else {
            throw AudioUnitInputCreationError.cantDisableOutputIO(error: error)
        }
        
        // Set the current device of the audio unit to the selected input device ID
        var inputAudioDeviceIDPassable: AudioObjectID = inputAudioDeviceID
        error = AudioUnitSetProperty(audioUnit,
                                     kAudioOutputUnitProperty_CurrentDevice,
                                     kAudioUnitScope_Global,
                                     inputBus,
                                     &inputAudioDeviceIDPassable,
                                     size(of: inputAudioDeviceID))
        guard error == noErr else {
            throw AudioUnitInputCreationError.cantSetInputDevice(error: error)
        }
        
        // Set the current device of the audio unit to the selected output device ID
        var outputAudioDeviceIDPassable: AudioObjectID = outputAudioDeviceID
        error = AudioUnitSetProperty(audioUnit,
                                     kAudioOutputUnitProperty_CurrentDevice,
                                     kAudioUnitScope_Global,
                                     outputBus,
                                     &outputAudioDeviceIDPassable,
                                     size(of: outputAudioDeviceID))
        guard error == noErr else {
            throw AudioUnitOutputCreationError.cantSetOutputDevice(error: error)
        }
        
        // Set the input callback
        var renderCallbackStruct = AURenderCallbackStruct()
        renderCallbackStruct.inputProc = AudioUnitRecordingCallback
        renderCallbackStruct.inputProcRefCon = rawContext
        
        error = AudioUnitSetProperty(audioUnit,
                                     kAudioOutputUnitProperty_SetInputCallback,
                                     kAudioUnitScope_Global,
                                     inputBus,
                                     &renderCallbackStruct,
                                     size(of: renderCallbackStruct))
        guard error == noErr else {
            throw AudioUnitInputCreationError.cantSetInputCallback(error: error)
        }
        
        // Set playback callback
        var playbackCallbackStruct = AURenderCallbackStruct()
        playbackCallbackStruct.inputProc = AudioUnitPlayoutCallback
        playbackCallbackStruct.inputProcRefCon = rawContext
        
        error = AudioUnitSetProperty(audioUnit,
                                     kAudioUnitProperty_SetRenderCallback,
                                     kAudioUnitScope_Input,
                                     outputBus,
                                     &playbackCallbackStruct,
                                     size(of: playbackCallbackStruct))
        guard error == noErr else {
            throw AudioUnitOutputCreationError.cantSetRenderCallback(error: error)
        }
                
        // Create the circular buffer used to send data from the
        // input to the output side
        CircularBuffer.destroy(contextPointer.pointee.inputBuffer)
        contextPointer.pointee.inputBuffer = CircularBuffer.makeCircularBuffer(
            sampleRate: inputSampleRate
        )
        
        contextPointer.pointee.bytesPerBlock = Int32(CircularBuffer.calculateSamplesPerBlock(sampleRate: outputSampleRate))
        
        try setAudioUnitBufferSize(audioUnit: audioUnit,
                                   bufferSize: CircularBuffer
                                        .calculateSamplesPerBlock(sampleRate: inputSampleRate)
                                    )
        
        return audioUnit
    }
}

// Buffer functions
extension DeviceManager {
    class func setAudioUnitBufferSize(audioUnit: AudioUnit?, bufferSize: Int) throws {
        guard bufferSize > 0, let audioUnit = audioUnit else {
            return
        }
        
        print("Set buffer to: \(bufferSize)")
        
        var bufferSize = UInt32(bufferSize)
        let error = AudioUnitSetProperty(audioUnit,
                                         kAudioDevicePropertyBufferFrameSize,
                                         kAudioUnitScope_Global,
                                         0,
                                         &bufferSize,
                                         size(of: bufferSize))
        guard error == noErr else {
            assertionFailure("Can't set buffer size")
            throw CustomAudioPipelineError.couldNotSetBufferSize(error: error)
        }
    }
}

extension DeviceManager {
    
    // Core Audio constants
    static let outputBus = UInt32(0) // stream to output hardware
    static let inputBus = UInt32(1) // stream from HAL input hardware
    static var enabled = UInt32(1)
    static var disabled = UInt32(0)
    
}
