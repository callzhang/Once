//
//  NSDate+Extend.h
//  EarlyWorm
//
//  Created by shenslu on 13-8-9.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#define weekdays                        @[@"Sunday", @"Monday",@"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturday"]
#define weekdayshort                    @[@"Sun", @"Mon",@"Tue", @"Wed", @"Thur", @"Fri", @"Sat"]
#define monthShort                      @[@"Jan.",@"Feb.",@"Mar.",@"Apr.",@"May.",@"Jun.",@"Jul.",@"Aug.",@"Sept.",@"Oct.",@"Nov.",@"Dec."]


@interface NSDate (Extend)
/**
 Returns HH:MM AM
 */
- (NSString *)date2String;

/**
 Returns HH:MM
 */
- (NSString *)date2timeShort;

/**
 Return AM or PM
 */
- (NSString *)date2am;

/**
 Returns Weekday, date and time
 */
- (NSString *)date2detailDateString;
/**
 Returns Weekday and date
 */
- (NSString *)date2dayString;

/**
 Returns string YYMMDD
 */
- (NSString *)date2YYMMDDString;
/**
 return YYYYMMddHHmm
 */
- (NSString *)date2numberDateString;
/**
 return YYYYMMddHHmmssSSSS
 */
- (NSString *)date2numberLongString;

//
-(NSString *)dateToParseDateString;
/**
 Compares two dates
 */
- (BOOL)isEarlierThan:(NSDate *)date;
- (NSInteger)weekdayNumber;
/**
 Returns a future time in n weeks from now that has the same weekday and time of the input date.
 @param n Weeks in the future from this time
 @param seconds the time adjustments for with Extra Seconds. Nagetive value means move the split point to the past. For searching alarm purpose, use -kMaxWakeTime as the extra time.
 @discussion The time originally used for deviding future and past is the time of now. 
 *
 * If use 0 extra time to schedule a task it causes a bug, when a task just passed and scheduleTasks is called, that task will be moved to past, which is undesireable.
 *
 * Therefore, I used current-kMaxWakeTime instead, to be consistant with all other places that determine if the task has pasted.
 *
 * However, this method is flawed. Just after we finished the most recent task, that task will be moved to past. But a new task with identical time will created becuase it is still not considered past time.
 */
- (NSDate *)nextOccurTime:(NSInteger)n withExtraSeconds:(NSInteger)seconds;
- (NSDate *)nextOccurTime:(NSInteger)n;
- (NSDate *)nextOccurTime;
/**
 Weekday in long format
 */
- (NSString *)weekday;

/**
 Weekday in short format
 */
- (NSString *)weekdayShort;

/**
 Time in string format HHMM
 */
- (NSString *)timeInString;

/**
 Tells if time interval since the receiver is less than serverUpdateInterval
 */
- (BOOL)isUpToDated;

/**
 In setting alarm, the interval is determined by alarmInterval. This method returns the time from the receiver with that interval.
 */
- (NSDate *)nextAlarmIntervalTime;

/**
 HHMM in interger format
 */
- (NSInteger)HHMM;

/**
 
 */
- (NSString *)time2HMMSS;

/**
 add minutes to the receiver
 */
- (NSDate *)timeByAddingMinutes:(NSInteger)minutes;
- (NSDate *)timeByAddingSeconds:(NSInteger)seconds;

/**
 get time from minutes from 5AM
 */
- (NSDate *)timeByMinutesFrom5am:(NSInteger)minutes;

/**
 Get minutes distance from 5AM to now
 */
- (NSInteger)minutesFrom5am;
/**
 Return MM/DD format
 */
- (NSString *)date2MMDD;

- (NSDateComponents *)dateComponents;

/**
 Time left to next alarm
 */
- (NSString *)timeLeft;


/**
 *
 *  Jan.27
 *
 */
-(NSString *)time2MonthDotDate;

/**
 Time elapsed since last update
 */
- (double)timeElapsed;
- (NSString *)timeElapsedString;

- (NSDate *)beginingOfDay;
- (NSDate *)endOfDay;

+ (NSString *)getStringFromTime:(float)time;

- (NSDate *)nextNoon;
@end
