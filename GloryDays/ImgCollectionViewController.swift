//
//  ImgCollectionViewController.swift
//  GloryDays
//
//  Created by Andres on 23/11/17.
//  Copyright © 2017 Andres. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Speech

private let reuseIdentifier = "imgCell"

class ImgCollectionViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate,AVAudioRecorderDelegate {
    var memories : [URL] = []
    var currentMemory : URL!
    
    
    var audioRecorder : AVAudioRecorder?
    var audioPlayer : AVAudioPlayer?
    var recordingURL : URL!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.recordingURL = try? getDocumentsDirectory().appendingPathComponent("memory-recording.m4a")

        self.loadMemories()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.onClickAddBarButton))
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.checkForGrantedPermissions()
    }
    func checkForGrantedPermissions(){
        let photosAuth = PHPhotoLibrary.authorizationStatus() == .authorized
        let speechAuth = SFSpeechRecognizer.authorizationStatus() == .authorized
        let recordingAuth = AVAudioSession.sharedInstance().recordPermission() == .granted
        
        let authorized = photosAuth && speechAuth && recordingAuth
        
        if (!authorized){
            if let vc = storyboard?.instantiateViewController(withIdentifier: "ShowTerms"){
                navigationController?.present(vc, animated: true)
            }
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func loadMemories(){
        self.memories.removeAll()
        guard let files  = try? FileManager.default.contentsOfDirectory(at: getDocumentsDirectory(), includingPropertiesForKeys: nil, options: []) else {
            return
        }
        
        for file in files{
            let fileName:String = file.lastPathComponent
            if fileName.hasSuffix(".thumb"){
                let noEtx = fileName.replacingOccurrences(of:".thumb", with:"")
                if let memoryPath = try? getDocumentsDirectory().appendingPathComponent(noEtx){
                    memories.append(memoryPath)
                }
            }
        }
        collectionView?.reloadSections(IndexSet(integer:1))
        
    }
    func getDocumentsDirectory()-> URL{
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        
        return documentsDirectory
        
    }
    @objc func onClickAddBarButton(){
        let vc = UIImagePickerController()
        vc.modalPresentationStyle = .pageSheet
        vc.delegate = self
        navigationController?.present(vc, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage{
            self.addImage(image: image)
            self.loadMemories()
        }
        
    }
    func addImage(image: UIImage)
    {
        let imgName = "memory-\(Date().timeIntervalSince1970).jpg"
        let thumbName = "\(imgName).thumb"
        
        do{
            let imagePath = try getDocumentsDirectory().appendingPathComponent(imgName)
            if let jpegData = UIImageJPEGRepresentation(image, 80.0){
                try jpegData.write(to: imagePath, options: [.atomicWrite])
            }
            if let thumbnail = resizeImg(image: image, width: 200){
                let thumbPath = try getDocumentsDirectory().appendingPathComponent(thumbName)
                if let jpegData = UIImageJPEGRepresentation(thumbnail,80.0){
                    try jpegData.write(to: thumbPath, options: [.atomicWrite])
                }
            }
        }catch{
            print("Ha fallado la escritura en el disco")
        }
    }
    
    func resizeImg(image: UIImage,width:CGFloat)->UIImage?{
        let scaleFactor = width/image.size.width
        let height = image.size.height * scaleFactor
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height),false,0)
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func imageURL(for memory: URL) -> URL{
        var mem = memory
        return  try! mem.appendingPathExtension("jpg")
        
    }
    func thumbnailURL(for memory: URL) -> URL{
        var mem = memory
        return  try! mem.appendingPathExtension("thumb")
        
    }
    func audioURL(for memory: URL) -> URL{
        var mem = memory
        return  try! mem.appendingPathExtension("m4a")
        
    }
    func transcriptionURL(for memory: URL) -> URL{
        var mem = memory
        return  try! mem.appendingPathExtension("txt")
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        if section == 0{
            return 0
        }
        else
        {
            return self.memories.count
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! imgCollectionViewCell
    
        let memory = self.memories[indexPath.row]
        let memoryName = self.thumbnailURL(for: memory).path
        let image = UIImage(contentsOfFile: memoryName)
        cell.imageView.image = image
        // Configure the cell
        if cell.gestureRecognizers == nil{
            let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.memoryLongPressed))
            recognizer.minimumPressDuration = 0.3
            cell.addGestureRecognizer(recognizer)
            
            cell.layer.borderColor = UIColor.white.cgColor
            cell.layer.borderWidth = 4.0
            cell.layer.cornerRadius = 8.0
            
        }
        return cell
    }

    @objc func memoryLongPressed(sender : UILongPressGestureRecognizer){
        if sender.state == .began{
            let cell = sender.view as! imgCollectionViewCell
            if let index = collectionView?.indexPath(for: cell){
                self.currentMemory = self.memories[index.row]
                self.startRecordingMemory()
            }
        }
        if sender.state == .ended{
            self.stopRecordingMemory(success: true)
        }
    }
    func startRecordingMemory(){
        audioPlayer?.stop()
        collectionView?.backgroundColor = UIColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 1.0)
        let recordingSession = AVAudioSession.sharedInstance()
        
        do{
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
            try recordingSession.setActive(true)
            let recordingSettings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: Int(44100),
                AVNumberOfChannelsKey : 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: recordingSettings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
        }catch let error {
            print(error)
            stopRecordingMemory(success: false)
        }
    }
    func stopRecordingMemory(success: Bool){
        collectionView?.backgroundColor = UIColor(red: 255.0/255.0, green: 219.0/255.0, blue: 99.0/255.0, alpha: 1.0)
        audioRecorder?.stop()
        if(success){
            do {
                let memoryAudioURL = try self.currentMemory.appendingPathExtension("m4a")
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: memoryAudioURL.path){
                    try fileManager.removeItem(at: memoryAudioURL)
                }
                try fileManager.moveItem(at: recordingURL, to: memoryAudioURL)
                
                self.transcribeAudio(memory: self.currentMemory)
            }catch let error{
                print (error)
            }
        }
    }
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if(!flag){
            stopRecordingMemory(success: false)
        }
        
    }
    func transcribeAudio(memory: URL){
        let audio = audioURL(for: memory)
        
        let transcription = transcriptionURL(for: memory)
        
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: audio)
        
        recognizer?.recognitionTask(with: request, resultHandler:{[unowned self](result, error) in
            guard let result = result else {
                print("Ha ocurrido un error : \(error)")
                return
            }
            
            if result.isFinal{
                let text = result.bestTranscription.formattedString
                
                do{
                    try text.write(to: transcription, atomically: true, encoding: String.Encoding.utf8)
                }catch{
                    print("Ha ocurrido un error de transcripción")
                }
            }
            
        })
    }
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "imgHeader", for: indexPath)
        return header
    }
    func collectionView(_ collectionView:UICollectionView, layout collectionViewLayout :UICollectionViewLayout, referenceSizeForHeaderInSection section : Int)->CGSize{
        if section == 0{
            return CGSize(width:0,height:50)
        }
        else{
            return CGSize.zero
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let memory = self.memories[indexPath.row]
        let fileManager = FileManager.default
        do{
            let audioName = audioURL(for: memory)
            let transcriptionName = transcriptionURL(for: memory)
            
            if(fileManager.fileExists(atPath: audioName.path)){
                self.audioPlayer = try AVAudioPlayer(contentsOf: audioName)
                self.audioPlayer?.play()
            }
            if fileManager.fileExists(atPath: transcriptionName.path){
                let contents = try String(contentsOf:transcriptionName)
                print (contents)
            }
        }
        catch{
            print("Error al reproducir el archivo")
        }
    }
    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
