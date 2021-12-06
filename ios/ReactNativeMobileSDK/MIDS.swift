//
//  MIDS.swift
//  ConnectMe
//
//  Created by evernym on 28/07/21.
//  Copyright © 2021 Facebook. All rights reserved.
//

import Foundation
import UIKit
import MIDSAssistSDK


@objc(MIDSDocumentVerification)
class MIDSDocumentVerification: NSObject {
  static var enrollmentManagerInstance: MIDSEnrollmentManager!
  static var enrollmentManager: MIDSEnrollmentManager = getEnrollmentManagerInstance()
  var resolve: RCTResponseSenderBlock!
  var reject: RCTResponseSenderBlock!
  var currentScanView: MIDSCustomScanViewController?
  var verifyInfoView : ConfirmScannedImageView!
  // Swift doesn't have synthesize, so we are writing it here directly as variable
  var bridge: RCTBridge!
  
  static func getEnrollmentManagerInstance() -> MIDSEnrollmentManager {
      if enrollmentManagerInstance == nil {
          enrollmentManagerInstance = MIDSEnrollmentManager.shared()
      }
      return enrollmentManagerInstance
  }
  
  @objc func initMIDSSDK(_ token: String,
                         withDataCenter dataCenter: String,
                         resolver resolve: @escaping RCTResponseSenderBlock,
                         rejecter reject: @escaping RCTResponseSenderBlock) -> Void {
      DispatchQueue.main.async {
        MIDSDocumentVerification.enrollmentManager.enrollmentDelegate = self
        self.resolve = resolve
        self.reject = reject
        let dataCenter = self.getDataCenter(dataCenter: dataCenter)
        MIDSDocumentVerification.enrollmentManager.initializeMIDSVerifySDK(sdkToken: token, dataCenter: dataCenter)
      }
  }
  
  @objc func getCountryList(_ resolve: @escaping RCTResponseSenderBlock,
                            rejecter reject: @escaping RCTResponseSenderBlock) -> Void {
    let countryList = MIDSDocumentVerification.enrollmentManager.getCountryList()
    var countries = [String: String]()
    for country in countryList {
      if let countryName = country.countryName, let countryCode = country.countryCode {
        countries[countryName] = countryCode
      }
    }

    resolve([countries])
  }
  
  @objc func terminateSDK(_ resolve: @escaping RCTResponseSenderBlock,
                            rejecter reject: @escaping RCTResponseSenderBlock) -> Void {
    
    if MIDSDocumentVerification.enrollmentManager.isMIDSVerifySDKInitialized() {
      MIDSDocumentVerification.enrollmentManager.terminateSDK()
    }

    resolve([])
  }

  @objc func getDocumentTypes(_ countryCode: String,
                              resolver resolve: @escaping RCTResponseSenderBlock,
                              rejecter reject: @escaping RCTResponseSenderBlock) -> Void {
    let documentType = MIDSDocumentVerification.enrollmentManager.getDocumentTypes(countryCode: countryCode)
    resolve([documentType])
  }
  
  @objc func startMIDSSDKScan(_ documentType: String,
                              policyVersion version: String,
                              resolver resolve: @escaping RCTResponseSenderBlock,
                              rejecter reject: @escaping RCTResponseSenderBlock) -> Void {
    self.resolve = resolve
    self.reject = reject
    DispatchQueue.main.async {
      MIDSDocumentVerification.enrollmentManager.startScan(document: documentType, privacyPolicyVersion: version, userBiometricConsent: true)
    }
  }
    
    @objc func dispatchEvent( eventName: String ) {
        self.bridge.eventDispatcher.sendAppEventWithName( eventName, body: "" )
    }

  func getDataCenter(dataCenter: String) -> MIDSDataCenter {
    switch dataCenter {
    case "SG":
      return .MIDSDataCenterSG;
    case "US":
      return .MIDSDataCenterUS;
    case "EU":
      return .MIDSDataCenterEU
    default:
      return .MIDSDataCenterSG;
    }
  }
  
  func handleMIDSError(error: MIDSVerifyError) {
    if self.reject != nil {
      self.reject([error.errorCode, error.errorMessage])
      self.reject = nil
      self.resolve = nil
      if MIDSDocumentVerification.enrollmentManager.isMIDSVerifySDKInitialized() {
        MIDSDocumentVerification.enrollmentManager.terminateSDK()
      }
    }
  }
    
    func terminate() {
        if MIDSDocumentVerification.enrollmentManager.isMIDSVerifySDKInitialized() {
          MIDSDocumentVerification.enrollmentManager.terminateSDK()
        }
    }
}

extension MIDSDocumentVerification: MIDSEnrollmentDelegate {
  
  func midsEnrollmentManager(scanViewController: MIDSCustomScanViewController, shouldDisplayNoUSAddressFoundHint message: String, confirmation: @escaping () -> Void) {
      NSLog("no US address")
  }

  func midsEnrollmentManager(didFinishInitializationSuccess status: Bool) {
    if self.resolve != nil {
      self.resolve([])
      self.resolve = nil
      self.reject = nil
    }
  }
  
  func midsEnrollmentManager(didFinishInitializationWithError error: MIDSVerifyError) {
      handleMIDSError(error: error)
  }
  
  func midsEnrollmentManager(didDetermineNextScanViewController scanViewController: MIDSCustomScanViewController, isFallback: Bool) {
    self.currentScanView = scanViewController
    // disable swipe down
    scanViewController.customScanViewController?.isModalInPresentation = true
    // Add close button
    // Create UIButton
    let myButton = UIButton(type: .close)
    
    // Position Button
    myButton.frame = CGRect(x: 20, y: 20, width: 100, height: 50)
    // Set text on button
    myButton.setTitle("X", for: .normal)
    // Set button background color
    myButton.backgroundColor = UIColor.lightGray
    
    // Set button action
      myButton.addTarget(self, action: #selector(resetScanner(_:)), for: .touchUpInside)
    
    // TODO:KS figure out the position handling
    // we need to use SwiftUI or UIKit alignment
    // this is the hard part
    scanViewController.customScanViewController?.addSubview(myButton)

    if  scanViewController.customScanViewController?.currentScanMode() == .faceCapture || scanViewController.customScanViewController?.currentScanMode() == .faceIProov {
      UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true, completion:{ () -> Void in
        UIApplication.shared.windows.first?.rootViewController?.present(scanViewController, animated: true)
      })
        
      return
    }

    UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: false)
    UIApplication.shared.windows.first?.rootViewController?.present(scanViewController, animated: false)
  }
    
    @objc func resetScanner(_ sender:UIButton!)
    {
        // terminate SDK
        terminate()
        // raise event to react-native
        dispatchEvent(eventName: "DESTROY")
    }


  func midsEnrollmentManager(didFinishScanningWith reference: String, accountID: String?, authenticationResult: Bool?)  {
    MIDSDocumentVerification.enrollmentManager.terminateSDK()
    if self.resolve != nil {
      self.resolve([reference])
      self.resolve = nil
      self.reject = nil
      UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true)
    }
  }

  func midsEnrollmentManager(didCancelWithError error: MIDSVerifyError) {
    handleMIDSError(error: error)
  }

  func midsEnrollmentManager(scanViewController: MIDSCustomScanViewController, shouldDisplayHelpWithText message: String, animationView: UIView) {
    scanViewController.customScanViewController?.retryScan()
  }
  
  func midsEnrollmentManager(shouldDisplayConfirmationWith view: UIView, text: String, currentStep: Int, totalSteps: Int, retryEnabled: Bool, confirmEnabled: Bool, confirmation: (() -> Void)?, retake: (() -> Void)?) {
    
    if confirmEnabled {
        if (verifyInfoView != nil){
            self.verifyInfoView.removeFromSuperview()
        }
        verifyInfoView = Bundle.main.loadNibNamed(ConfirmScannedImage.identifier,
                                                  owner: self,
                                                  options: nil)?.first as? ConfirmScannedImageView
        
        
        currentScanView?.view.addSubview(verifyInfoView)
        verifyInfoView.scannedImagePreviewView.addSubview(view)
        verifyInfoView.backgroundColor = UIColor.white
        
        
        if let frame = currentScanView?.view.bounds {
            verifyInfoView.frame = frame
        }
        verifyInfoView.addConfirmationHandler(action: confirmation, confirm: confirmEnabled)
        verifyInfoView.addRetakeHandler(action: retake, retake: retryEnabled)
        verifyInfoView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["view":view]))
        verifyInfoView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["view":view]))
    }
  }
  
  func midsEnrollmentManager(didStartBiometricAnalysis scanViewController: MIDSCustomScanViewController) {}
  
  func midsEnrollmentManager(customScanViewControllerWillPresentIProovController scanViewController: MIDSCustomScanViewController) {}
  
  func midsEnrollmentManager(customScanViewControllerWillPrepareIProovController scanViewController: MIDSCustomScanViewController) {
      // add loading logic here
      DispatchQueue.main.async {
          guard let appDelegate = UIApplication.shared.delegate,
              let window = appDelegate.window else {
                  return
          }
          let loadingView = LoadingView(frame: window!.frame)
          loadingView.tag  = LoadingViewConstants.tag
          // we can set a message as well, but for now, we are just showing loader
          // so we show view without the message
          loadingView.loadingWithoutMessageView.isHidden = false
          loadingView.loaderImageView.prepareForAnimation(withGIFNamed: LoadingViewConstants.imageName)
          loadingView.loaderImageView.startAnimatingGIF()
          if let view = scanViewController.customOverlayLayer {
              view.addSubview(loadingView)
          } else {
              window?.addSubview(loadingView)
          }
      }
  }
  
  func midsEnrollmentManager(didCaptureAllParts status: Bool) {
    currentScanView = nil
  }
}
