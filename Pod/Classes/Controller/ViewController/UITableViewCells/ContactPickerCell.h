//
//  ContactPickerCell.h
//  Pods
//
//  Created by Prasanth V S on 5/16/17.
//
//

#import <UIKit/UIKit.h>
#import "VeeContact.h"

typedef void (^RemoveContactClickedBlock)(int itemIndex);
@interface ContactPickerCell : UICollectionViewCell

@property (assign, nonatomic) NSInteger  *index;
@property (strong, nonatomic) VeeContact *contact;
@property (nonatomic, copy) RemoveContactClickedBlock removeContactClickedBlock;

@end
