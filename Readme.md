# VoiceProcessingIO sample project

> As discussed in WWDC 2022 Lab ID VP9N6MT8SX with Apple Engineer Julian Y from Core Audio.

## Primary issues:
1) `kAudioUnitSubType_VoiceProcessingIO` does not lead to "Mic Mode" getting enabled (see scenario 1) with built-in input/output
2) `kAudioUnitSubType_HALOutput` leads to errors once `AudioUnit` is started (see scenario 2) with AirPods
3) See Scenario 3 for results with wired headphones

The first two scenarios (built-in MacBook speakers/mic & AirPods Pro) are the most relevant

## Instructions:

1) Scenario 1:
- Build and run the sample project with no headphones connected
- Select default mac input and output. Verify that sample rates are correct
- Click "Setup"
- Click "Start"

Expected results at this point:
    - Sample app will play through input to output with `kAudioUnitSubType_VoiceProcessingIO` enabled (currently working)
    - "Mic Mode" control in Control Center should be enabled (**Not currently happening on Monterey 12.3.1 on MacBook Air M1**)

2) Scenario 2:

    - Build and run the sample project with AirPods Pro connected
    - Select AirPods for input and output
    - Change sample rate 24k for both input and output
    - Click "Setup"
    - **Uncheck "VOIP"**
    - Click "Start"

Results at this point: 
- Sample app will play through input to output with `kAudioUnitSubType_HALOutput` enabled (**currently working**)


    - Build and run the sample project with AirPods Pro connected
    - Select AirPods for input and output
    - Change sample rate 24k for both input and output
    - Click "Setup"
    - **Make sure "VOIP" is checked**
    - Click "Start"

Expected results at this point: 
    - Sample app will play through input to output with `kAudioUnitSubType_VoiceProcessingIO` enabled (**Not currently happening on Monterey 12.3.1 on MacBook Air M1**)
Actual result: 
    - `couldNotInitialize(error: -10875)`
    - `HALPlugIn::ObjectSetPropertyData: got an error from the plug-in routine, Error: 1852797029 (nope)`
    - `Failed to set output device tap stream physical format =  2 ch,  48000 Hz, Float32, interleaved, err=1852797029`


2) Scenario 3:

    - Build and run the sample project with Apple wired earbuds connected
    - Select External Microphone/External Headphones
    - Change sample rate 41.1k for both input and output
    - Click "Setup"
    - **Uncheck "VOIP"**
    - Click "Start"

Results at this point: 
- Sample app will play through input to output with `kAudioUnitSubType_HALOutput` enabled (**currently working**)


    - Build and run the sample project with Apple wired earbuds connected
    - Select External Microphone/External Headphones
    - Change sample rate 41.1k for both input and output
    - Click "Setup"
    - **Make sure "VOIP" is checked**
    - Click "Start"
    
Expected results at this point: 
    - Sample app will play through input to output with `kAudioUnitSubType_VoiceProcessingIO` enabled (**Not currently happening on Monterey 12.3.1 on MacBook Air M1**)
Actual result: 
    - Audio units run, but no audible input gets to headphones
Important note:
    - When we were on the WebEx call together, *I believe* this *did* work, leading me to believe something else had affected the audio setup at some point.
