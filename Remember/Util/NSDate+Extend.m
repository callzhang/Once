//
//  NSDate+Extend.m
//  EarlyWorm
//
//  Created by shenslu on 13-8-9.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import "NSDate+Extend.h"
#import "EWUtil.h"

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
    if ([self earlierDate:date] == self) {
        return TRUE;
    }else{
        return FALSE;
    }
}

- (NSInteger)weekdayNumber{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSInteger weekdayOfDate = [cal ordinalityOfUnit:NSCalendarUnitWeekday inUnit:NSCalendarUnitWeekOfYear forDate:self];
    return weekdayOfDate - 1; //0:sunday ... 6:saturday
}

- (NSDate *)nextOccurTimeInWeeks:(NSInteger)n withExtraSeconds:(float)seconds{
    NSDate *time = self;
    //bring to past
    while ([time timeIntervalSinceNow] > -seconds) {
        time = [time lastWeekTime];
    }
    
    //bring to the first occurance of future
    while ([time timeIntervalSinceNow] < -seconds) {
        time = [time nextWeekTime];
    }
    
    //further n weeks
    while (n>0) {
        n--;
        time = [time nextWeekTime];
    }
    
    NSAssert([time timeIntervalSinceNow] >3600*24*7*n-seconds && [time timeIntervalSinceNow] < 3600*24*7*(n+1)-seconds, @"Error in getting %ld next time %@", (long)n, time);
    return time;
}

- (NSDate *)nextOccurTimeInWeeks:(NSInteger)n{
    return [self nextOccurTimeInWeeks:n withExtraSeconds:kMaxWakeTime];
}

- (NSDate *)nextOccurTime{
    return [self nextOccurTimeInWeeks:0];
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

- (BOOL)isUpToDated{
    BOOL upToDate = self.timeElapsed < kServerUpdateInterval;
    return upToDate;
}

- (NSDate *)nextAlarmIntervalTime{
    NSDateComponents* delta = [[NSDateComponents alloc] init];
    delta.second = alarmInterval;
    return [[NSCalendar currentCalendar] dateByAddingComponents:delta toDate:self options:0];
}


- (NSInteger)HHMM{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comp = [cal components:(NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitWeekday) fromDate:self];
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
    NSDateComponents* deltaComps = [cal components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:self];
    deltaComps.minute = minutes % 60;
    deltaComps.hour = 5 + (NSInteger)minutes/60;
    
    NSDate *time = [cal dateFromComponents:deltaComps];
    return time;
}

- (NSInteger)minutesFrom5am{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents* deltaComps = [cal components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:self];
    NSInteger min = deltaComps.hour * 60 + deltaComps.minute;
    if (min % 10 != 0) {
        DDLogError(@"Something wrong with the time input: %@", self.date2detailDateString);
    }
    return min;
}

- (NSDateComponents *)dateComponents{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents* deltaComps = [cal components:(NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitDay | NSCalendarUnitSecond | NSCalendarUnitYear | NSCalendarUnitMonth) fromDate:self];
    return deltaComps;
}

- (NSString *)timeLeft{
    NSTimeInterval left = [self timeIntervalSinceNow];
    NSString *postFix = left > 0 ? @" left" : @" past";
    return [[NSDate getStringFromTime:left] stringByAppendingString:postFix];
}

+ (NSString *)getStringFromTime:(NSTimeInterval)time{
    
    NSString *timeStr;
    time = fabs(time);
    NSInteger t = (NSInteger)time;
    CGFloat days = time / 3600 / 24;
    CGFloat hours = (t % (3600*24)) / 3600;
    CGFloat minutes = floor((t % 3600)/60);
    CGFloat seconds = t % 60;
    
    if (days >=2) {
        timeStr = [NSString stringWithFormat:@"%ld days", (long)days];
    }else if (days >=1) {
        timeStr = [NSString stringWithFormat:@"1 day %ld hours", (long)hours-24];
    }else if (hours > 10) {
        timeStr = [NSString stringWithFormat:@"%ld hours", (long)(hours)];
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
    NSDateComponents* deltaComps = [cal components:(NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:self];
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

- (NSDate *)nextNoon{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *com = self.dateComponents;
    com.hour = 12;
    com.minute = 0;
    com.second = 0;
    com.day++;
    NSDate *next = [cal dateFromComponents:com];
    return next;
}

@end
