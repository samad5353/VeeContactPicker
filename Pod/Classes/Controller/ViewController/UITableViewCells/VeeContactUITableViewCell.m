//
//  Created by Andrea Cipriani on 14/12/15.
//  Copyright © 2015 Code Atlas SRL. All rights reserved.
//

#import "VeeContactPickerAppearanceConstants.h"
#import "VeeContactUITableViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "FLKAutoLayout.h"
#import "VeeContactPickerAppearanceConstants.h"

@interface VeeContactUITableViewCell ()

@end

@implementation VeeContactUITableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (!self) {
        return nil;
    }
    
    self.backgroundColor = [UIColor clearColor]; // [[VeeContactPickerAppearanceConstants sharedInstance] veeContactCellBackgroundColor];
    [self setCellSelectedBackgroundColor];
    
    [self addContactImageViewToSubView];
    [self addPrimaryLabelToSubView];
    [self addselctionCheckButtonToSubView];
    return self;
}

-(void)setCellSelectedBackgroundColor
{
    UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:self.bounds];
    //[selectedBackgroundView setBackgroundColor:[[VeeContactPickerAppearanceConstants sharedInstance] veeContactCellBackgroundColorWhenSelected]];
    [selectedBackgroundView setBackgroundColor:[UIColor clearColor]];
    self.selectedBackgroundView = selectedBackgroundView;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    //Avoid background color disappering when selecting cell, see http://stackoverflow.com/questions/5222736/uiview-backgroundcolor-disappears-when-uitableviewcell-is-selected
    
    UIColor* backgroundColor = _contactImageView.backgroundColor;
    [super setSelected:selected animated:animated];
    _contactImageView.backgroundColor = backgroundColor;
  
    [super setSelected:selected animated:animated];
    [self.backgroundView setBackgroundColor:[UIColor clearColor]];
    if (selected) {
        [_checkmarkImageView setBackgroundColor:[UIColor greenColor]];
    }else{
        [_checkmarkImageView setBackgroundColor:[UIColor clearColor]];
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    //Avoid background color disappering when selecting cell, see http://stackoverflow.com/questions/5222736/uiview-backgroundcolor-disappears-when-uitableviewcell-is-selected
    
    UIColor* backgroundColor = _contactImageView.backgroundColor;
    [super setHighlighted:highlighted animated:animated];
    _contactImageView.backgroundColor = backgroundColor;
}

-(void)prepareForReuse
{
    _primaryLabel.text = @"";
    _contactImageView.image = nil;
}

#pragma mark - Private

/*
 I personally don't like to code the UI, but I'm not able to load the nib of a UITableViewCell from the bundle of a Pod, see:
 https://github.com/CocoaPods/CocoaPods/issues/2408
 */

-(void)addContactImageViewToSubView
{
    CGFloat contactImageViewDiameter = [[[VeeContactPickerAppearanceConstants sharedInstance] veeContactCellImageDiameter] floatValue];
    _contactImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, contactImageViewDiameter, contactImageViewDiameter)];
    [self addSubview:_contactImageView];
    _contactImageView.layer.cornerRadius = [[[VeeContactPickerAppearanceConstants sharedInstance] veeContactCellImageDiameter] floatValue] / 2;
    _contactImageView.contentMode = UIViewContentModeScaleAspectFill;
    _contactImageView.clipsToBounds = YES;
    [self setConstraintsForContactImageView];
}

-(void)addPrimaryLabelToSubView
{
    _primaryLabel = [UILabel new];
    [self addSubview:_primaryLabel];
    _primaryLabel.font = [[VeeContactPickerAppearanceConstants sharedInstance] veeContactCellPrimaryLabelFont];
    [self setConstraintsForPrimaryLabel];
}

-(void)addselctionCheckButtonToSubView {
    _checkmarkImageView = [UIImageView new];
    [_checkmarkImageView setBackgroundColor:[UIColor clearColor]];
    [self addSubview:_checkmarkImageView];
    [self setConstraintsForCheckMarkImage];
    [_checkmarkImageView.layer setCornerRadius:_checkmarkImageView.bounds.size.width/2];
    _checkmarkImageView.layer.borderColor = [UIColor grayColor].CGColor;
    _checkmarkImageView.layer.borderWidth = 2.0;
    [_checkmarkImageView setClipsToBounds:YES];
}

-(void)setConstraintsForContactImageView
{
    NSString* contactImageViewDiameterString = [[[VeeContactPickerAppearanceConstants sharedInstance] veeContactCellImageDiameter] stringValue];
    [_contactImageView constrainWidth:contactImageViewDiameterString height:contactImageViewDiameterString];
    
    NSString* contactImageViewMarginString = [[self contactImageViewMargin] stringValue];
    [_contactImageView alignTop:contactImageViewMarginString leading:contactImageViewMarginString bottom:contactImageViewMarginString trailing:@"0" toView:self.contentView];
}

-(void)setConstraintsForPrimaryLabel
{
    [_primaryLabel alignCenterYWithView:_contactImageView predicate:@"0"];
    CGFloat horizontalMarginFromContactImageView = 16;
    [_primaryLabel constrainLeadingSpaceToView:_contactImageView predicate:[@(horizontalMarginFromContactImageView) stringValue]];
    [_primaryLabel constrainWidth:[[self cellWidthWithoutPrimaryLabelWithHorizontalMarginFromContactImageView:horizontalMarginFromContactImageView andHorizontalTrailingSpaceToSuperView:16] stringValue]];
}

-(void)setConstraintsForCheckMarkImage {
    [_checkmarkImageView alignCenterYWithView:_contactImageView predicate:@"0"];
    [_checkmarkImageView constrainWidth:@"30"];
    [_checkmarkImageView constrainHeight:@"30"];
    NSString* selectioButtonXpos = [[self checkmarkImageXposition] stringValue];
    [_checkmarkImageView alignTrailingEdgeWithView:self.contentView predicate:selectioButtonXpos];
}
-(NSNumber *)checkmarkImageXposition {
    return @(self.frame.size.width - _contactImageView.frame.size.width);
}

-(NSNumber*)contactImageViewMargin
{
    CGFloat cellHeight = [[VeeContactPickerAppearanceConstants sharedInstance] veeContactCellHeight];
    NSNumber* contactImageViewDiameter = [[VeeContactPickerAppearanceConstants sharedInstance] veeContactCellImageDiameter];
    return @((cellHeight - [contactImageViewDiameter integerValue]) / 2);
}

-(NSNumber*)cellWidthWithoutPrimaryLabelWithHorizontalMarginFromContactImageView:(CGFloat)horizontalMarginFromContactImageView andHorizontalTrailingSpaceToSuperView:(CGFloat)horizontalTrailingSpaceToSuperView
{
    CGFloat cellWidth = self.contentView.frame.size.width;
    return @(cellWidth - [[self contactImageViewMargin] floatValue] - [[[VeeContactPickerAppearanceConstants sharedInstance] veeContactCellImageDiameter] floatValue] - horizontalTrailingSpaceToSuperView);
}
@end
