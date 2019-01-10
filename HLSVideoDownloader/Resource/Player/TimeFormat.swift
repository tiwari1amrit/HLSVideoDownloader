//
//  TimeFormat.swift
//  ATVideoPlayer
//
//  Created by Amrit Tiwari on 4/19/18.
//  Copyright © 2018 tiwariammit@gmail.com. All rights reserved.
//

import UIKit

//MARK:- Time format for displaying current time and total time
class TimeFormat{
    
    //    var movieTime : Double
    //
    //    init(movieTime : Double) {
    //        self.movieTime = movieTime
    //    }
    
    class func getHoursMinutesSecondsFrom(_ time: Double) -> (hours: Int, minutes: Int, seconds: Int) {
        
        let secs = Int(time)//Int(self)
        let hours = secs / 3600
        let minutes = (secs % 3600) / 60
        let seconds = (secs % 3600) % 60
        return (hours, minutes, seconds)
    }
    
    class func formatTimeFor(_ time: Double) -> String{
        
        let result = self.getHoursMinutesSecondsFrom(time)
        let hoursString = "\(result.hours)"
        var minutesString = "\(result.minutes)"
        if minutesString.count == 1 {
            minutesString = "0\(result.minutes)"
        }
        var secondsString = "\(result.seconds)"
        if secondsString.count == 1 {
            secondsString = "0\(result.seconds)"
        }
        var time = "\(hoursString):"
        if result.hours >= 1 {
            time.append("\(minutesString):\(secondsString)")
        }
        else {
            time = "\(minutesString):\(secondsString)"
        }
        return time
    }
}
