//
//  ViewController.swift
//  GloryDays
//
//  Created by Andres on 23/11/17.
//  Copyright © 2017 Andres. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Speech

class ViewController: UIViewController {

    @IBOutlet var infoLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func askPermissions(_ sender: Any) {
        self.requestPhotoPermission()
        self.requestRecordPermission()
        self.requestSpeechRecognizerPermission()
    }
    
    func requestPhotoPermission(){
        PHPhotoLibrary.requestAuthorization { [unowned self](AuthorizationStatus) in
            DispatchQueue.main.async {
                if(AuthorizationStatus == .authorized){
                }
                else {
                    self.infoLabel.text = "No se ha concedido el permiso de fotos"
                }
            }
        }
    }
    func requestRecordPermission(){
        AVAudioSession.sharedInstance().requestRecordPermission { [unowned self](allowed) in
            DispatchQueue.main.async {
                if allowed{
                }
                else{
                    self.infoLabel.text = "No se ha concedido el permiso de grabación de voz"
                }
            }

        }
    }
    func requestSpeechRecognizerPermission(){
        SFSpeechRecognizer.requestAuthorization { [unowned self](AuthorizationStatus) in
            DispatchQueue.main.async {
                if(AuthorizationStatus == .authorized){
                    
                }else{
                    self.infoLabel.text = "No se ha concedido el permiso de transcripciòn de texto"
                }
            }
        }
    }
    func authorizationCompleted(){
        dismiss(animated: true)
    }
}

