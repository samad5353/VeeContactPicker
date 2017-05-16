//
//  ContactPickerCell.m
//  Pods
//
//  Created by Prasanth V S on 5/16/17.
//
//

#import "ContactPickerCell.h"
#import "UIImageView+AGCInitials.h"

@interface ContactPickerCell()
@property (strong, nonatomic) UIImageView *contactImageView;
@property (strong, nonatomic) UIButton *removeButton;
@property (strong, nonatomic) UILabel  *nameLabel;
@end

@implementation ContactPickerCell

-(id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        
        _contactImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        _nameLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 82, 90, 10)];
        _removeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [_removeButton setFrame:CGRectMake(50, 15, 20, 20)];
        [_removeButton setTitle:@"X" forState:UIControlStateNormal];
        [_removeButton setBackgroundColor:[UIColor grayColor]];
        [_removeButton.layer setCornerRadius:10];
        [_removeButton.layer setBorderColor:[UIColor whiteColor].CGColor];
        [_removeButton.layer setBorderWidth:1.0f];
        [_removeButton addTarget:self action:@selector(removeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_contactImageView];
        [self addSubview:_removeButton];
        _contactImageView.center = self.contentView.center;
        [_contactImageView.layer setCornerRadius:_contactImageView.bounds.size.width/2];
        [_contactImageView setClipsToBounds:YES];
        [_contactImageView setBackgroundColor:[UIColor purpleColor]];
        
    }
    return self;
}

-(void)setIndex:(NSInteger *)index {
    [_removeButton setTag:index];
}

-(void)setContact:(VeeContact *)contact {
    _contact = contact;
    [self populateUI];
}

-(void)populateUI {
    _nameLabel.text	=_contact.firstName;
    if (_contact.thumbnailImage != nil)
        [_contactImageView setImage:_contact.thumbnailImage];
    else
        [_contactImageView agc_setImageWithInitialsFromName:[_contact displayName] separatedByString:@" "];
}

- (IBAction)removeButtonTapped:(id)sender {
    if(_removeContactClickedBlock) {
        _removeContactClickedBlock([sender tag]);
    }
    
}

@end
