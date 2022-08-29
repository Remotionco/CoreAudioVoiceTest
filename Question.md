I’m having difficulty getting Mic Mode(s) enabled in macOS 12.

Previously, this issue was discussed in Feedback FB10167689 and WWDC 2022 Lab ID VP9N6MT8SX with Apple Engineer Julian Y from Core Audio.

In my previous ticket, I was stuck getting AirPods working with `kAudioUnitSubType_VoiceProcessingIO`, but this seems to have been solved by having a single audio unit for input/output.

However, there’s an unresolved issue: 
- Despite running a single `kAudioUnitSubType_VoiceProcessingIO` audio unit, on macOS 12.3.1, the Mic Mode section of Control Center is not accessible/selectable.

I have been able to get Mic Mode running with AVAudioEngine, but have not been able to get many other aspects of our audio stack working reliably with AVAudioEngine, so that is not a tenable option at that time.

In summary: While running a `kAudioUnitSubType_VoiceProcessingIO` audio unit (not within AVAudioEngine, but rather created manually using CoreAudio/AudioUnits), what needs to take place for Mic Mode to become available in macOS 12?

A minimal reproducible example sample project is attached. Please see the Readme.md inside for specific steps, but it is a very straightforward process. All of the relevant code should be in Audio.swift
