//
//  SpeechRecognizer.swift
//  SpeechRecognition
//
//  Created by Sam Symons on 14/06/16.
//  Copyright © 2016 Sam Symons. All rights reserved.
//

import Foundation
import Speech

typealias SpeechRecognizerResultHandler = ((String?, Bool, NSError?) -> Swift.Void)

class SpeechRecognizer {
  private let speechRecognizer = SFSpeechRecognizer(locale: Locale(localeIdentifier: "en-US"))!
  private let audioEngine = AVAudioEngine()
  
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
  private var recognitionTask: SFSpeechRecognitionTask?
  
  internal func startRecording(resultHandler: SpeechRecognizerResultHandler) throws {
    guard let inputNode = audioEngine.inputNode else { return }
    
    if let recognitionTask = recognitionTask {
      recognitionTask.cancel()
      self.recognitionTask = nil
    }
    
    // Set up the recognition request:
    
    recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    guard let recognitionRequest = recognitionRequest else { return }
    recognitionRequest.shouldReportPartialResults = true
    
    // Set up the audio session:
    
    try configureAudioSession()
    
    // Configure the recognition task:
    
    recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
      var stopRecording = false
      
      if let result = result {
        let transcript = result.bestTranscription.formattedString
        print("Transcript: \(transcript)")
        
        resultHandler(transcript, result.isFinal, error)
        stopRecording = result.isFinal
      }
      
      if (error != nil) || stopRecording {
        self.stopRecording()
        resultHandler(nil, true, error)
      }
    }
    
    let recordingFormat = inputNode.outputFormat(forBus: 0)
    
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, _) in
      self.recognitionRequest?.append(buffer)
    }
    
    audioEngine.prepare()
    try audioEngine.start()
  }
  
  private func configureAudioSession() throws {
    let audioSession = AVAudioSession.sharedInstance()
    try audioSession.setCategory(AVAudioSessionCategoryRecord)
    try audioSession.setMode(AVAudioSessionModeMeasurement)
    try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
  }
  
  private func stopRecording() {
    self.audioEngine.stop()
    audioEngine.inputNode?.removeTap(onBus: 0)
    
    self.recognitionRequest = nil
    self.recognitionTask = nil
  }
}
