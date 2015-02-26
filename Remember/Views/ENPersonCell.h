//
//  ENPersonCell.h
//  
//
//  Created by Lee on 2/26/15.
//
//

#import <UIKit/UIKit.h>

@interface ENPersonCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *profile;
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *detail;
@property (weak, nonatomic) IBOutlet UIButton *disclosure;

@end
