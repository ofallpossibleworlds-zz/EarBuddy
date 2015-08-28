//
//  ViewController.swift
//  Earbuddy
//
//  Created by Connor Goggans, Robby Marshall, and Vicky Yao on 3/21/15.
//  Copyright (c) 2015 Connor Goggans, Robby Marshall, and Vicky Yao. All rights reserved.
//


//  Check to see if it pushes

import UIKit
import AVFoundation
import CoreData
import CoreLocation



class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AVAudioRecorderDelegate, CLLocationManagerDelegate {
    
    
    @IBOutlet weak var tableView: UITableView!
    var data = [NSManagedObject]()
    //var allowed = CLAuthorizationStatus.NotDetermined
    var locationManager = CLLocationManager()
    //var stateChecker: CustomObject = CustomObject(UIApplication)
    
    
    //let date = NSDate()
    
    
    
    /*var items: [String] = []
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.items.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    var cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell") as UITableViewCell
    
    cell.textLabel?.text = self.items[indexPath.row]
    
    return cell
    }
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
    //println("You selected cell #\(indexPath.row)!")
    }*/
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerClass(UITableViewCell.self,
            forCellReuseIdentifier: "Cell")
        
        var locationAllower = CLLocationManager.authorizationStatus()
        var locationAllowed = true
        if (locationAllower == CLAuthorizationStatus.Restricted || locationAllower == CLAuthorizationStatus.Denied) {
            locationAllowed = false
        } else if (locationAllower == CLAuthorizationStatus.NotDetermined) {
            locationManager.requestWhenInUseAuthorization()
        }
        if (locationAllower == CLAuthorizationStatus.AuthorizedAlways || locationAllower == CLAuthorizationStatus.AuthorizedWhenInUse) {
            locationManager.delegate = self;
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation();
        }
        
        //Audio
        let dirPaths =
        NSSearchPathForDirectoriesInDomains(.DocumentDirectory,
            .UserDomainMask, true)
        let docsDir = dirPaths[0] as! String
        let soundFilePath =
        docsDir.stringByAppendingPathComponent("sound.caf")
        let soundFileURL = NSURL(fileURLWithPath: soundFilePath)
        let recordSettings =
        [AVEncoderAudioQualityKey: AVAudioQuality.Max.rawValue,
            AVEncoderBitRateKey: 12800,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey: 44100.0]
        
        var error: NSError?
        
        let audioSession = AVAudioSession.sharedInstance()
        audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord,
            error: &error)
        
        if let err = error {
            println("audioSession error: \(err.localizedDescription)")
        }
        
        recorder = AVAudioRecorder(URL: soundFileURL,
            settings: recordSettings as [NSObject : AnyObject], error: &error)
        
        self.recorder?.meteringEnabled = true;
        
        if let err = error {
            println("audioSession error: \(err.localizedDescription)")
        } else {
            recorder?.prepareToRecord()
        }
        
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        var location:CLLocation = locations[locations.count-1] as! CLLocation

    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {

    }
    
    func tableView(tableView: UITableView,
        numberOfRowsInSection section: Int) -> Int {
            return data.count
    }
    
    func tableView(tableView: UITableView,
        cellForRowAtIndexPath
        indexPath: NSIndexPath) -> UITableViewCell {
            
            let cell =
            tableView.dequeueReusableCellWithIdentifier("Cell")
               as! UITableViewCell
            
            let storeData = data[indexPath.row]
            cell.textLabel!.text = storeData.valueForKey("data") as! String?
            
            return cell
    }
    
    func addData(sound: String) {
        self.saveData(sound)
        self.tableView.reloadData()
    }
    
    func saveData(name: String) {
        //1
        let appDelegate =
        UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext!
        
        //2
        let entity =  NSEntityDescription.entityForName("Data",
            inManagedObjectContext:
            managedContext)
        
        let storeData = NSManagedObject(entity: entity!,
            insertIntoManagedObjectContext:managedContext)
        
        //3
        storeData.setValue(name, forKey: "data")
        
        //4
        var error: NSError?
        if !managedContext.save(&error) {
            println("Could not save \(error), \(error?.userInfo)")
        }  
        //5
        data.insert(storeData, atIndex: 0)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //1
        let appDelegate =
        UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext!
        
        //2
        let fetchRequest = NSFetchRequest(entityName:"Data")
        
        //3
        var error: NSError?
        
        let fetchedResults =
        managedContext.executeFetchRequest(fetchRequest,
            error: &error) as! [NSManagedObject]?
        
        if let results = fetchedResults {
            data = results.reverse()
        } else {
            println("Could not fetch \(error), \(error!.userInfo)")
        }
    }
    
    var recorder: AVAudioRecorder?
    
    
    @IBAction func checkLevels() {
        if recorder?.recording == false{
            recorder?.recordForDuration(3.0)
        }
        
        recorder?.updateMeters()
        
        var dangerLevel:String
        
        var averageLevel = recorder?.averagePowerForChannel(0)
        var level = (0.625 * averageLevel! + 90.0)
        
        
        if level < 85{
            dangerLevel = "No Danger"
        }else if level <= 88{
            dangerLevel = "Damage in around 4 hours"
        }else if level <= 91{
            dangerLevel = "Damage in around 2 hours"
        }else if level <= 94{
            dangerLevel = "Damage in around 1 hour"
        }else if level <= 97{
            dangerLevel = "Damage in around 30 minutes"
        }else if level <= 100{
            dangerLevel = "Damage in around 15 minutes"
        }else{
            dangerLevel = "Damage very soon"
        }

        
        let levelOutput = NSString(format: "%.2f dB", (0.625) * averageLevel! + 100.0)
        let timestamp = NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .MediumStyle, timeStyle: .ShortStyle)
        
        addData("\(levelOutput) \t \(timestamp)")
        
        
        
        
        let alertController = UIAlertController(title: "Level", message: (levelOutput as String) + "\n" + dangerLevel, preferredStyle: UIAlertControllerStyle.Alert)
        
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
        
        if (level > 100) {
            // Reporting to database of noise level and location would occur here in presence of database.
            let reportActionHandler = { (action:UIAlertAction!) -> Void in
                let alertMessage = UIAlertController(title: "Service Unavailable", message: "Sorry, the database to handle noise complaints has not been set up yet.", preferredStyle: .Alert)
                alertMessage.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self.presentViewController(alertMessage, animated: true, completion: nil)
            }
            let callAction = UIAlertAction(title: "Report", style: .Default, handler: reportActionHandler)
            alertController.addAction(callAction)
        }
        self.presentViewController(alertController, animated: true, completion: nil)
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    /*
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    */
    @IBAction func moreInfo(sender: AnyObject) {
        if let url = NSURL(string: "http://www.dangerousdecibels.org/virtualexhibit/6measuringsound.html") {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    /*
    @IBAction func backGroundMode(sender: UISwitch) {
        if (sender.on) {
            NSNotificationCenter.defaultCenter().postNotificationName("Switch on", object: nil)
        } else {
            NSNotificationCenter.defaultCenter().postNotificationName("Switch off", object: nil)
        }
    }
    */
}







//NSNotificationCenter.defaultCenter().addObserver(self, selector:"drawAShape:", name: "actionOnePressed", object: nil)
//NSNotificationCenter.defaultCenter().addObserver(self, selector:"showAMessage:", name: "actionTwoPressed", object: nil)
/*
var dateComp:NSDateComponents = NSDateComponents()
dateComp.year = 2014;
dateComp.month = 06;
dateComp.day = 09;
dateComp.hour = 15;
dateComp.minute = 26;
dateComp.timeZone = NSTimeZone.systemTimeZone()

var calender:NSCalendar = NSCalendar(calendarIdentifier: NSGregorianCalendar)
var date:NSDate = calender.dateFromComponents(dateComp)


var notification:UILocalNotification = UILocalNotification()
notification.category = "FIRST_CATEGORY"
notification.alertBody = "Hi, I am a notification"
notification.fireDate = date

UIApplication.sharedApplication().scheduleLocalNotification(notification)
*/
