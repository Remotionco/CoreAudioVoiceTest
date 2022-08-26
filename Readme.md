# VoiceProcessingIO sample project

> As discussed in WWDC 2022 Lab ID VP9N6MT8SX with Apple Engineer Julian Y from Core Audio.

## Primary issue:
- `kAudioUnitSubType_VoiceProcessingIO` does not lead to "Mic Mode" getting enabled (see scenario 1) with built-in input/output

I've tried to shorten the code as much as possible, but CoreAudio requires a reasonable amount of boilerplate -
`Audio.swift` should contain relevant code to the question, with some of that boilerplate separated out into files like `Devices`, `Formats`, `Types`, etc.

## Instructions:

1) Scenario 1:
- Build and run the sample project with no headphones connected
- Select default mac input and output. Verify that sample rates are correct
- Click "Setup"
- Click "Start"

Expected results at this point:
    - Sample app will play through input to output with `kAudioUnitSubType_VoiceProcessingIO` enabled (currently working)
    - "Mic Mode" control in Control Center should be enabled (**Not currently happening on Monterey 12.3.1 on MacBook Pro M1**)

2) Scenario 2:
    
- Switch to AirPods (for both input and output)
- Make sure that the sample rates are correct (24,000) 
- Click "Setup"
- Click "Start"
    
Expected results at this point: 
    - Sample app will play through input to output with `kAudioUnitSubType_VoiceProcessingIO` enabled (currently working)
    - "Mic Mode" control in Control Center should be enabled (**Not currently happening on Monterey 12.3.1 on MacBook Pro M1**)

