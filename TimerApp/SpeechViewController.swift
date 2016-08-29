//
//  SpeechViewController.swift
//  TimerApp
//
//  Created by David Symhoven on 26.05.16.
//  Copyright © 2016 David Symhoven. All rights reserved.
//

import UIKit
import AVFoundation

class SpeechViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    // MARK: Properties
    var totalPause: Int?
    var timer = NSTimer()
    var timeElapsed : Int = 0
    var timeRemaining : Int = 0
    let audioSession = AVAudioSession.sharedInstance()
    var backgroundTaskIdentifier : UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    let speechSynthesizer = AVSpeechSynthesizer()
    let pickerData : [String] = ["30", "45", "60", "90", "120", "150", "180"]
    var startStopButton: UIButton? = nil
    
    // MARK: Outlets

    
    @IBAction func dismissView(segue: UIStoryboardSegue) {
        // needed to dismiss the about view in storyboard
    }
    
    @IBAction func toggleTimer(sender: UIButton) {
        if (sender.selected) {
            stopTimer()
            
        }else{
            startStopButton = sender
            startTimer()

        }
    }
    
    @IBOutlet weak var pickerView: UIPickerView!
    
    @IBOutlet weak var elapsedTimeLabel: UILabel!
    
    @IBOutlet weak var BannerView: UIView!
    
    // MARK: Delegate methods
    
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }

    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        totalPause = Int(pickerData[row])
        elapsedTimeLabel.text = "\(totalPause!) " + NSLocalizedString("SECONDS_SHORT", comment: "seconds")
    }
    
    
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        let pickerLabel = UILabel()
        let titleData = pickerData[row] + " " + NSLocalizedString("SECONDS_SHORT", comment: "seconds")
        let myTitle = NSAttributedString(string: titleData, attributes: [NSFontAttributeName:UIFont.systemFontOfSize(24), NSForegroundColorAttributeName:UIColor.whiteColor()])
        pickerLabel.attributedText = myTitle
        pickerLabel.textAlignment = .Center
        
        // hide picker view selection lines
        // pickerView.showsSelectionIndicator is pre iOS 7 only
        pickerView.subviews[1].hidden = true
        pickerView.subviews[2].hidden = true
        
        return pickerLabel
    }
    
    func pickerView(pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 46.0
    }
    

    
    // MARK: User functions
    
    func setupNotificationSetup(){
        
        let startTimerAction = UIMutableUserNotificationAction()
        startTimerAction.identifier = "startTimer"
        startTimerAction.title = "Start again"
        startTimerAction.activationMode = UIUserNotificationActivationMode.Background
        startTimerAction.destructive = false
        startTimerAction.authenticationRequired = false
        
        let resetTimerAction = UIMutableUserNotificationAction()
        resetTimerAction.identifier = "resetTimer"
        resetTimerAction.title = "Reset"
        resetTimerAction.activationMode = UIUserNotificationActivationMode.Foreground
        resetTimerAction.destructive = false
        resetTimerAction.authenticationRequired = true
        
        let actionArray : [UIUserNotificationAction] = [startTimerAction, resetTimerAction]
        
        let timerActionsCategory = UIMutableUserNotificationCategory()
        timerActionsCategory.identifier = "timerCategory"
        timerActionsCategory.setActions(actionArray, forContext: UIUserNotificationActionContext.Minimal)
        
        let categoriesForSettings : Set<UIUserNotificationCategory> = [timerActionsCategory]
        
        let notificationSettings = UIUserNotificationSettings(forTypes: [UIUserNotificationType.Alert, UIUserNotificationType.Sound, UIUserNotificationType.Badge], categories: categoriesForSettings)
        
        UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
    }
    
    func scheduleLocalNotification(){
        let localNotification = UILocalNotification()
        localNotification.fireDate = NSDate().dateByAddingTimeInterval(10)
        localNotification.alertBody = "Do you want to start or reset the timer ?"
        localNotification.category = "timerCategory"
        localNotification.soundName = UILocalNotificationDefaultSoundName
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
    }
    
    func cancelAllLocalNotifications(){
        UIApplication.sharedApplication().cancelAllLocalNotifications()
    }
    
    func handleResetTimerNotification(){
        print("ResetTimer Button pressed!")
    }
    
    func stopTimer() {
        resetTimer()
        elapsedTimeLabel.text = NSLocalizedString("TIMER_STOPPED", comment: "Stopped!")
        deactivateAudioSession()
        enablePickerView()
        startStopButton?.selected = false
        endBackgroundTask(backgroundTaskIdentifier)
    }
    
    func startTimer() {
        backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
            self.endBackgroundTask(self.backgroundTaskIdentifier)
        })
        timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(updateLabel), userInfo: nil, repeats: true)
        disablePickerView()
        cancelAllLocalNotifications()
        startStopButton?.selected = true
    }
    
    
    
    func vibrate(){
        AudioServicesPlaySystemSoundWithCompletion(kSystemSoundID_Vibrate, nil)
    }
    
    func endBackgroundTask(identifier: UIBackgroundTaskIdentifier){
        if identifier != UIBackgroundTaskInvalid{
            UIApplication.sharedApplication().endBackgroundTask(identifier)
            backgroundTaskIdentifier = UIBackgroundTaskInvalid
            print("background task stopped")
        }

    }
    
    func updateLabel(){
        if totalPause != nil{
            timeRemaining = totalPause! - timeElapsed
            elapsedTimeLabel.text = "\(timeRemaining) " + NSLocalizedString("SECONDS_SHORT", comment: "seconds")
            timeElapsed += 1
            switch(timeRemaining){
            case 15:
                tellUserToGetReady()
                vibrate()
            case 13: deactivateAudioSession()
            case 1...5:
                countDown()
            case 0:
                resetTimer()
                deactivateAudioSession()
                vibrate()
                scheduleLocalNotification()
                //endBackgroundTask(backgroundTaskIdentifier)
                elapsedTimeLabel.text = "Go!"
            default: break
            }
        }


    }
    
    func setUtteranceProperties(utterance: AVSpeechUtterance){
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
    }
    
    func tellUserToGetReady(){
        
        activateAudioSession()
        let utterance = AVSpeechUtterance(string: "get ready")
        setUtteranceProperties(utterance)
        speechSynthesizer.speakUtterance(utterance)
    }
    
    func countDown(){
        activateAudioSession()
        let utterance = AVSpeechUtterance(string: String(timeRemaining))
        setUtteranceProperties(utterance)
        speechSynthesizer.speakUtterance(utterance)
        
    }
    
    func resetTimer(){
        timer.invalidate()
        timeElapsed = 0
        enablePickerView()
        startStopButton?.selected = false
    }
    
    func deactivateAudioSession(){
        print("deactivate audioSession")
        do{
            try audioSession.setActive(false)
        }
        catch let error as NSError{
            print("An error occured while deactivating audioSession!")
            print(error)
        }
    }
    
    func activateAudioSession() {
        print("activate audioSession")
        do{
            try audioSession.setCategory(AVAudioSessionCategoryPlayback, withOptions: AVAudioSessionCategoryOptions.DuckOthers)
            try audioSession.setActive(true)
        }
        catch let error as NSError{
            print("An error occured while activating an audioSession")
            print(error)
        }
    }
    
    func disablePickerView(){
        pickerView.userInteractionEnabled = false
        pickerView.alpha = 0.6
    }
    
    func enablePickerView(){
        pickerView.userInteractionEnabled = true
        pickerView.alpha = 1.0
    }
    
    // MARK: Life Cylcle
    override func viewWillDisappear(animated: Bool) {
        
        print("View will unload")
        deactivateAudioSession()
        endBackgroundTask(backgroundTaskIdentifier)
        cancelAllLocalNotifications()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pickerView.delegate = self
        self.pickerView.dataSource = self
        
        totalPause = Int(pickerData[0])
        // set current selected pause as big label
        elapsedTimeLabel.text = "\(totalPause!) " + NSLocalizedString("SECONDS_SHORT", comment: "seconds")
        
        setupNotificationSetup()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SpeechViewController.startTimer), name: "startTimerNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SpeechViewController.handleResetTimerNotification), name: "resetTimerNotification", object: nil)

    }
    



}