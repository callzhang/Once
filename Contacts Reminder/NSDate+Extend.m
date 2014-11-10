//
//  NSDate+Extend.m
//  EarlyWorm
//
//  Created by shenslu on 13-8-9.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import "NSDate+Extend.h"

@implementation NSDate (Extend)

- (NSString *)date2String {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateFormat:@"hh:mm a"];

    NSString *string = [formatter stringFromDate:self];
    return string;
}

- (NSString *)date2timeShort{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
//    [formatter setDateFormat:@"h:mm"];
//    
//    NSString *string = [formatter stringFromDate:self];
    NSMutableString *string;
    
    NSDateComponents *compt = [self dateComponents];
    if (compt.hour == 0) {
        [formatter setDateFormat:@":mm"];
        string = [NSMutableString stringWithString:@"0"];
       [string appendString: [formatter stringFromDate:self]];
    }
    else
    {
        [formatter setDateFormat:@"h:mm"];
        string = [[formatter stringFromDate:self] mutableCopy];
    }
    return string;
}

- (NSString *)date2am{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateFormat:@"a"];
    
    NSString *string = [formatter stringFromDate:self];
    return string;
}

- (NSString *)date2detailDateString{
    NSDateFormatter *parseFormatter = [[NSDateFormatter alloc] init];
    parseFormatter.timeZone = [NSTimeZone defaultTimeZone];
    parseFormatter.dateFormat = @"EEE, dd MMM yyyy HH:mm";
    return [parseFormatter stringFromDate:self];
}

- (NSString *)date2dayString{
    NSDateFormatter *parseFormatter = [[NSDateFormatter alloc] init];
    parseFormatter.timeZone = [NSTimeZone defaultTimeZone];
    parseFormatter.dateFormat = @"EEE, MM/dd/yy";
    return [parseFormatter stringFromDate:self];

}
-(NSString *)dateToParseDateString{
    NSDateFormatter *parseFormatter = [[NSDateFormatter alloc] init];
    parseFormatter.timeZone = [NSTimeZone defaultTimeZone];
    parseFormatter.dateFormat = @"yyyy-MM-ddTHH:mm:ssZ";
    NSString *str = [parseFormatter stringFromDate:self];
    
    return str;
}

- (NSString *)date2YYMMDDString{
    NSDateFormatter *parseFormatter = [[NSDateFormatter alloc] init];
    parseFormatter.timeZone = [NSTimeZone defaultTimeZone];
    parseFormatter.dateFormat = @"YYYYMMdd";
    return [parseFormatter stringFromDate:self];
}

- (NSString *)date2numberDateString{
    NSDateFormatter *parseFormatter = [[NSDateFormatter alloc] init];
    parseFormatter.timeZone = [NSTimeZone defaultTimeZone];
    parseFormatter.dateFormat = @"YYYYMMddHHmm";
    return [parseFormatter stringFromDate:self];
}

- (NSString *)date2numberLongString{
    NSDateFormatter *parseFormatter = [[NSDateFormatter alloc] init];
    parseFormatter.timeZone = [NSTimeZone defaultTimeZone];
    parseFormatter.dateFormat = @"YYYYMMddHHmmssSSSS";
    return [parseFormatter stringFromDate:self];
}

- (NSString *)date2MMDD{
    NSDateFormatter *parseFormatter = [[NSDateFormatter alloc] init];
    parseFormatter.timeZone = [NSTimeZone defaultTimeZone];
    parseFormatter.dateFormat = @"MM/dd";
    return [parseFormatter stringFromDate:self];
}

- (NSString *)time2HMMSS{
    NSDateFormatter *parseFormatter = [[NSDateFormatter alloc] init];
    parseFormatter.timeZone = [NSTimeZone defaultTimeZone];
    parseFormatter.dateFormat = @"h:mm:ss";
    return [parseFormatter stringFromDate:self];
}

- (BOOL)isEarlierThan:(NSDate *)date{
    NSTimeInterval t1 = [self timeIntervalSinceReferenceDate];
    NSTimeInterval t2 = [date timeIntervalSinceReferenceDate];
    if (t2-t1>1) {
        return TRUE;
    }else{
        return FALSE;
    }
}

- (NSInteger)weekdayNumber{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSInteger weekdayOfDate = [cal ordinalityOfUnit:NSWeekdayCalendarUnit inUnit:NSWeekCalendarUnit forDate:self];
    return weekdayOfDate - 1; //0:sunday ... 6:saturday
}

- (NSDate *)nextOccurTime:(NSInteger)n withExtraSeconds:(NSInteger)seconds{
    NSDate *time = self;
    //bring to past
    while ([time timeIntervalSinceNow]>seconds) {
        time = [time lastWeekTime];
    }
    
    //bring to the first occurance of future
    while ([time timeIntervalSinceNow]<seconds) {
        time = [time nextWeekTime];
    }
    
    //further n weeks
    while (n>0) {
        n--;
        time = [time nextWeekTime];
    }
    
    NSAssert([time timeIntervalSinceNow] >3600*24*7*n+seconds && [time timeIntervalSinceNow] < 3600*24*7*(n+1)+seconds, @"Error in getting %ld next time %@", (long)n, time);
    return time;
}

- (NSDate *)nextOccurTime:(NSInteger)n{
    return [self nextOccurTime:n withExtraSeconds:0];
}

- (NSDate *)nextOccurTime{
    return [self nextOccurTime:0];
}

- (NSDate *)nextWeekTime{
    NSDateComponents* deltaComps = [[NSDateComponents alloc] init];
    deltaComps.day = 7;
    NSDate *time = [[NSCalendar currentCalendar] dateByAddingComponents:deltaComps toDate:self options:0];
    return time;
}

- (NSDate *)lastWeekTime{
    NSDateComponents* deltaComps = [[NSDateComponents alloc] init];
    deltaComps.day = -7;
    NSDate *time = [[NSCalendar currentCalendar] dateByAddingComponents:deltaComps toDate:self options:0];
    return time;
}


- (NSString *)timeInString{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comp = [cal components:(NSHourCalendarUnit | NSMinuteCalendarUnit | NSWeekdayCalendarUnit) fromDate:self];
    NSString *HHMM = [NSString stringWithFormat:@"%ld:%ld", (long)comp.hour, (long)comp.minute];
    return HHMM;
}


- (NSInteger)HHMM{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comp = [cal components:(NSHourCalendarUnit | NSMinuteCalendarUnit | NSWeekdayCalendarUnit) fromDate:self];
    NSInteger hhmm = comp.hour*100 + comp.minute;
    return hhmm;
}

- (NSDate *)timeByAddingMinutes:(NSInteger)minutes{
    NSDateComponents* deltaComps = [[NSDateComponents alloc] init];
    deltaComps.minute = minutes;
    NSDate *time = [[NSCalendar currentCalendar] dateByAddingComponents:deltaComps toDate:self options:0];
    return time;
}

- (NSDate *)timeByAddingSeconds:(NSInteger)seconds{
    NSDateComponents* deltaComps = [[NSDateComponents alloc] init];
    deltaComps.second = seconds;
    NSDate *time = [[NSCalendar currentCalendar] dateByAddingComponents:deltaComps toDate:self options:0];
    return time;
}

- (NSDate *)timeByMinutesFrom5am:(NSInteger)minutes{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents* deltaComps = [cal components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:self];
    deltaComps.minute = minutes % 60;
    deltaComps.hour = 5 + (NSInteger)minutes/60;
    
    NSDate *time = [cal dateFromComponents:deltaComps];
    return time;
}

- (NSInteger)minutesFrom5am{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents* deltaComps = [cal components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:self];
    NSInteger min = deltaComps.hour * 60 + deltaComps.minute;
    if (min % 10 != 0) {
        NSLog(@"Something wrong with the time input: %@", self.date2detailDateString);
    }
    return min;
}

- (NSDateComponents *)dateComponents{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents* deltaComps = [cal components:(NSHourCalendarUnit | NSMinuteCalendarUnit | NSDayCalendarUnit | NSSecondCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit) fromDate:self];
    return deltaComps;
}

- (NSString *)timeLeft{
    NSInteger left = [self timeIntervalSinceNow];
    if (left<0) {
        return @"";
    }
    
    return [NSDate getStringFromTime:left];
}

+ (NSString *)getStringFromTime:(float)time{
    
    NSString *timeStr;
    time = abs(time);
    NSInteger t = (NSInteger)time;
    float days = time / 3600 / 24;
    float hours = (t % (3600*24)) / 3600;
    float minutes = floor((t % 3600)/60);
    float seconds = t % 60;
    
    if (days >=2) {
        timeStr = [NSString stringWithFormat:@"%d days", (NSInteger)days];
//    }else if (days >=1) {
//        timeStr = [NSString stringWithFormat:@"1 day %d hours", (NSInteger)hours];
    }else if (hours > 10) {
        timeStr = [NSString stringWithFormat:@"%d hours", (NSInteger)hours + (NSInteger)days*24];
    }else if (hours >= 1){
        timeStr = [NSString stringWithFormat:@"%.1f hours", hours + minutes/60];
    }else if(minutes >= 1){
        timeStr = [NSString stringWithFormat:@"%ld minutes",(long)minutes];
    }else{
        timeStr = [NSString stringWithFormat:@"%ld seconds",(long)seconds];
    }
    return timeStr;
}


-(NSString *)time2MonthDotDate
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents* deltaComps = [cal components:(NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:self];
    NSArray *monthArray = monthShort;
    NSString *str = [monthArray[deltaComps.month] stringByAppendingFormat:@"%ld", (long)deltaComps.day];
    
    return str;
}

- (double)timeElapsed{
    double t = -[self timeIntervalSinceNow];
    return t;
    
}

- (NSString *)timeElapsedString{
    return [NSDate getStringFromTime:self.timeElapsed];
}


- (NSDate *)beginingOfDay{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *com = self.dateComponents;
    com.hour = 0;
    com.minute = 0;
    com.second = 0;
    NSDate *BOD = [cal dateFromComponents:com];
    return BOD;
}

- (NSDate *)endOfDay{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *com = self.dateComponents;
    com.hour = 23;
    com.minute = 59;
    com.second = 59;
    NSDate *EOD = [cal dateFromComponents:com];
    return EOD;
}

@end
