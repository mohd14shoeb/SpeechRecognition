//
//  ViewController.swift
//  SpeechRecognition
//
//  Created by Sam Symons on 14/06/16.
//  Copyright © 2016 Sam Symons. All rights reserved.
//

import UIKit
import Speech

enum SpeechRecognitionState {
  case requiresAuthorization
  case ready
  case recording
}

class ViewController: UIViewController {
  private let recognizer: SpeechRecognizer = SpeechRecognizer()
  private var recognitionState: SpeechRecognitionState
  
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    recognitionState = ViewController.currentSpeechRecognitionState()
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    recognitionState = ViewController.currentSpeechRecognitionState()
    super.init(coder: aDecoder)
  }
  
  private static func currentSpeechRecognitionState() -> SpeechRecognitionState {
    return (SFSpeechRecognizer.authorizationStatus() == .authorized) ? .ready : .requiresAuthorization
  }
  
  // MARK: - IBOutlets
  
  @IBOutlet var transcriptTextView: UITextView!
  @IBOutlet var recordButton: UIButton!
  
  // MARK: - Lifecycle
    
  override func viewDidLoad() {
    super.viewDidLoad()
    
    updateInterfaceState()
  }
  
  // MARK: - IBActions
  
  @IBAction func recordButtonTapped() {
    handleSpeechRecognitionState(state: recognitionState)
  }
  
  // MARK: - Private
  
  private func requestSpeechRecognitionAuthorization() {
    SFSpeechRecognizer.requestAuthorization { authStatus in
      OperationQueue.main().addOperation {
        switch authStatus {
        case .authorized:
          self.recognitionState = .ready
        default:
          self.recognitionState = .requiresAuthorization
        }
        
        self.updateInterfaceState()
      }
    }
  }
  
  private func updateInterfaceState() {
    displaySpeechRecognitionState(state: recognitionState)
  }
  
  private func displaySpeechRecognitionState(state: SpeechRecognitionState) {
    switch state {
    case .requiresAuthorization:
      recordButton.setTitle("Authorize", for: [])
    case .ready:
      recordButton.setTitle("Record", for: [])
    case .recording:
      recordButton.setTitle("Stop Recording", for: [])
    }
  }
  
  private func handleSpeechRecognitionState(state: SpeechRecognitionState) {
    switch state {
    case .requiresAuthorization:
      requestSpeechRecognitionAuthorization()
    case .ready:
      try! startRecording()
      self.recognitionState = .recording
      updateInterfaceState()
    case .recording:
      self.recognitionState = .ready
      updateInterfaceState()
    }
  }
  
  // MARK: Recording
  
  private func startRecording() throws {
    try recognizer.startRecording() { (result, stoppedRecording, error) in
      if let text = result {
        self.transcriptTextView.text = text
      }
      
      if stoppedRecording {
        self.stopRecording()
      }
    }
  }
  
  private func stopRecording() {
    self.recognitionState = .ready
    self.updateInterfaceState()
  }
}
