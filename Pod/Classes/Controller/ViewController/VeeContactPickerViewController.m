//
//  Created by Andrea Cipriani on 14/12/15.
//  Copyright © 2015 Code Atlas SRL. All rights reserved.
//

#import "VeeContactPickerViewController.h"

#import "VeeContactPickerAppearanceConstants.h"
#import "VeeContactPickerOptions.h"
#import "VeeContactPickerStrings.h"

#import "VeeAddressBook.h"
#import "VeeCommons.h"

#import "VeeContactProtFactoryProducer.h"

#import "VeeContactCellConfiguration.h"
#import "VeeContactProtFactoryProducer.h"
#import "VeeContactUITableViewCell.h"
#import "VeeSectionedArrayDataSource.h"
#import "VeeTableViewSearchDelegate.h"
#import "ContactPickerCell.h"

@interface VeeContactPickerViewController ()<UICollectionViewDataSource,UICollectionViewDelegateFlowLayout, UICollectionViewDelegate>

#pragma mark - Outlets

@property (weak, nonatomic) IBOutlet UINavigationBar* navigationBar;
@property (weak, nonatomic) IBOutlet UIView* statusBarCoverView;
@property (weak, nonatomic) IBOutlet UISearchBar* searchBar;
@property (weak, nonatomic) IBOutlet UICollectionView *selectedContactsCollectionView;

#pragma mark - Constraints

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewBottomMarginConstraint;

#pragma mark - Dependencies

@property (nonatomic, strong) VeeContactPickerOptions* veeContactPickerOptions;
@property (nonatomic) ABAddressBookRef addressBookRef;
@property (nonatomic, strong) VeeAddressBook* veeAddressBook;

#pragma mark - Model

@property (nonatomic, strong) NSArray<id<VeeContactProt> >* veeContacts;
@property (nonatomic, strong) NSMutableArray<id<VeeContactProt> >* nonSelectedContacts;
@property (nonatomic, strong) VeeSectionedArrayDataSource* veeSectionedArrayDataSource;

#pragma mark - Search

@property (nonatomic, strong) VeeTableViewSearchDelegate* veeTableViewSearchDelegate;

#pragma mark - Style

@property (nonatomic, strong) VeeContactCellConfiguration* veeContactCellConfiguration;

#pragma mark - Bundle

@property (nonatomic, strong) NSBundle * podBundle;

@property (weak, nonatomic) IBOutlet UIScrollView *selectedContactsView;
@property (weak, nonatomic) IBOutlet UIView *scrollContentView;

@property (strong, nonatomic) NSMutableArray *selectedContactsArray;
@property (strong, nonatomic) NSMutableArray *selectedContactsIndexArray;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *selectedContactViewHeightConstraint;

@property (nonatomic, assign) BOOL isRemovingFromHeader;
@property (nonatomic, assign) BOOL isAddingFromSearchController;

@end

@implementation VeeContactPickerViewController

#pragma mark - Initializers

- (instancetype)initWithDefaultConfiguration
{
    self = [self initWithOptions:[VeeContactPickerOptions defaultOptions] andVeeContacts:nil];
    return self;
}

- (instancetype)initWithOptions:(VeeContactPickerOptions*)veeContactPickerOptions
{
    self = [self initWithOptions:veeContactPickerOptions andVeeContacts:nil];
    return self;
}

- (instancetype)initWithVeeContacts:(NSArray<id<VeeContactProt> >*)veeContacts
{
    self = [self initWithOptions:[VeeContactPickerOptions defaultOptions] andVeeContacts:veeContacts];
    return self;
}

- (instancetype)initWithOptions:(VeeContactPickerOptions*)veeContactPickerOptions andVeeContacts:(NSArray<id<VeeContactProt> >*)veeContacts
{
    self = [super init];
    if (!self) {
        return nil;
    }
    [self loadBundleOfPod];
    NSAssert(_podBundle,@"Bundle can't be nil");
    
    self = [[VeeContactPickerViewController alloc] initWithNibName:NSStringFromClass(self.class) bundle:_podBundle];
    _veeContactPickerOptions = veeContactPickerOptions;
    _veeContacts = veeContacts;
    _nonSelectedContacts = [NSMutableArray arrayWithArray:_veeContacts];
    _veeAddressBook = [[VeeAddressBook alloc] initWithVeeABDelegate:self];
    _veeContactCellConfiguration = [[VeeContactCellConfiguration alloc] initWithVeePickerOptions:_veeContactPickerOptions];
    _selectedContactsArray = [[NSMutableArray alloc]init];
    
    return self;
}

-(void)loadBundleOfPod
{
    NSString *bundlePath = [[NSBundle bundleForClass:[VeeContactPickerViewController class]] pathForResource:@"VeeContactPicker" ofType:@"bundle"];
    _podBundle = [NSBundle bundleWithPath:bundlePath];
    if ([_podBundle isLoaded] == NO){
        [_podBundle load];
    }
}

#pragma mark - ViewController lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _selectedContactsIndexArray = [NSMutableArray new];
    
    [self loadStrings];
    [self loadPickerAppearance];
    _addressBookRef = ABAddressBookCreate();
    [self.selectedContactsCollectionView registerClass:[ContactPickerCell class] forCellWithReuseIdentifier:@"cell"];
    //  [self.selectedContactsCollectionView registerClass:[ class] forCellWithReuseIdentifier:@"cell"];
    [self.selectedContactsCollectionView setPagingEnabled:YES];
    
    [self loadVeeContacts];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - DidLoad Utils

- (void)loadStrings {
    _titleNavigationItem.title = [_veeContactPickerOptions.veeContactPickerStrings navigationBarTitle];
    _cancelBarButtonItem.title = [_veeContactPickerOptions.veeContactPickerStrings cancelButtonTitle];
}

- (void)loadPickerAppearance {
    _cancelBarButtonItem.tintColor = [[VeeContactPickerAppearanceConstants sharedInstance] cancelBarButtonItemTintColor];
    _rightBarButtonItem.tintColor = [[VeeContactPickerAppearanceConstants sharedInstance] cancelBarButtonItemTintColor];
    [_rightBarButtonItem setTitle:@"Next"];
    [_rightBarButtonItem  setTarget:self];
    [_rightBarButtonItem setAction:@selector(nextButtonTapped:)];
    _navigationBar.tintColor = [[VeeContactPickerAppearanceConstants sharedInstance] navigationBarTintColor];
    _navigationBar.barTintColor = [[VeeContactPickerAppearanceConstants sharedInstance] navigationBarBarTintColor];
    _navigationBar.translucent = [[VeeContactPickerAppearanceConstants sharedInstance] navigationBarTranslucent];
    _statusBarCoverView.backgroundColor = [[VeeContactPickerAppearanceConstants sharedInstance] navigationBarBarTintColor];
    _tableViewBottomMarginConstraint.constant = [[VeeContactPickerAppearanceConstants sharedInstance] veeContactPickerTableViewBottomMargin];
    if (_selectedContactsArray.count <= 0)
        _selectedContactViewHeightConstraint.constant = 10;
    else
        _selectedContactViewHeightConstraint.constant = 90;
    _groupHederViewHeightConstraint.constant = 0;
    [self hideEmptyView];
}

- (void)loadVeeContacts {
    
    BOOL shouldLoadVeecontactsFromAB = _veeContacts == nil;
    if (shouldLoadVeecontactsFromAB) {
        BOOL hasAlreadyABPermission = [VeeAddressBook hasABPermissions];
        if (hasAlreadyABPermission == YES) {
            [self loadVeeContactsFromAddressBook];
        }
        else {
            [_veeAddressBook askABPermissionsWithDelegate:_addressBookRef];
        }
    }
    else {
        [self loadCustomVeecontacts];
    }
}

- (void)loadCustomVeecontacts {
    
    if ([VeeCommons vee_isEmpty:_veeContacts]) {
        [self showEmptyView];
    }
    else {
        _veeContacts = [_veeContacts sortedArrayUsingSelector:@selector(compare:)];
        [self setupTableView];
    }
}

- (void)loadVeeContactsFromAddressBook {
    
    id<VeeContactFactoryProt> veeContactFactoryProt = [VeeContactProtFactoryProducer veeContactProtFactory];
    _veeContacts = [[veeContactFactoryProt class] veeContactProtsFromAddressBook:_addressBookRef];
    _veeContacts = [_veeContacts sortedArrayUsingSelector:@selector(compare:)];
    _nonSelectedContacts = [NSMutableArray arrayWithArray:_veeContacts];
    [self setupTableView];
}

- (void)setupTableView {
    
    [self registerCellsForReuse];
    ConfigureCellBlock veeContactConfigureCellBlock = ^(VeeContactUITableViewCell* cell, id<VeeContactProt> veeContact) {
        [_veeContactCellConfiguration configureCell:cell forVeeContact:veeContact];
    };
    NSString* cellIdentifier = [[VeeContactPickerAppearanceConstants sharedInstance] veeContactCellIdentifier];
    _veeSectionedArrayDataSource = [[VeeSectionedArrayDataSource alloc] initWithItems:_veeContacts cellIdentifier:cellIdentifier allowedSortedSectionIdentifiers:_veeContactPickerOptions.sectionIdentifiers sectionIdentifierWildcard:_veeContactPickerOptions.sectionIdentifierWildcard configurationCellBlock:veeContactConfigureCellBlock];
    
    _contactsTableView.dataSource =  _veeSectionedArrayDataSource;
    _contactsTableView.delegate = self;
    [_contactsTableView reloadData];
    [self setupSearchDisplayController];
}

- (void)setupSearchDisplayController {
    
    _veeTableViewSearchDelegate = [[VeeTableViewSearchDelegate alloc] initWithSearchDisplayController:self.searchDisplayController dataToFiler:_nonSelectedContacts withPredicate:[self predicateToFilterVeeContactProt] andSearchResultsDelegate:self];
    
    [self.searchDisplayController setDelegate:_veeTableViewSearchDelegate];
    [self setupSearchTableView];
}

- (NSPredicate*)predicateToFilterVeeContactProt {
    
    if ([_veeContacts count] > 0 == NO) {
        return nil;
    }
    NSPredicate* searchPredicate = [[[_veeContacts firstObject] class] searchPredicateForSearchString];
    return searchPredicate;
}

- (void)setupSearchTableView {
    
    self.searchDisplayController.searchResultsTableView.dataSource = _veeSectionedArrayDataSource;
    self.searchDisplayController.searchResultsTableView.delegate = self;
}

- (void)registerCellsForReuse {
    
    NSString* cellIdentifier = [[VeeContactPickerAppearanceConstants sharedInstance] veeContactCellIdentifier];
    [_contactsTableView registerClass:[VeeContactUITableViewCell class] forCellReuseIdentifier:cellIdentifier];
    [self.searchDisplayController.searchResultsTableView registerClass:[VeeContactUITableViewCell class] forCellReuseIdentifier:cellIdentifier];
}

#pragma mark - VeeABDelegate

- (void)abPermissionsGranted
{
    [self performSelectorOnMainThread:@selector(loadVeeContactsFromAddressBook) withObject:nil waitUntilDone:YES];
}

-(void)abPermissionsNotGranted
{
    NSLog(@"Warning - address book permissions not granted");
    [self showEmptyView];
    [_contactPickerDelegate didFailToAccessAddressBook];
}

#pragma mark - UI

- (void)showEmptyView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _emptyViewLabel.hidden = NO;
        _contactsTableView.hidden = YES;
        _searchBar.hidden = YES;
    });
}

-(void)hideEmptyView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _emptyViewLabel.hidden = YES;
        _contactsTableView.hidden = NO;
        _searchBar.hidden = NO;
        
    });
}

-(void)showGroupHeaderView {
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationCurveEaseIn
                     animations:^{
                         _groupHederViewHeightConstraint.constant = 150;
                     }
                     completion:nil];
}

-(void)hideGroupHeaderView {
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationCurveEaseIn
                     animations:^{
                         _groupHederViewHeightConstraint.constant = 0;
                     }
                     completion:nil];
}
-(void)hideSelectedContactsView {
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationCurveEaseIn
                     animations:^{
                         _selectedContactViewHeightConstraint.constant = 10;
                         [weakSelf hideGroupHeaderView];
                     }
                     completion:nil];
}

#pragma mark - TableView delegate


- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return [[VeeContactPickerAppearanceConstants sharedInstance] veeContactCellHeight];
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    
    _isRemovingFromHeader = NO;
    [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    _selectedContactViewHeightConstraint.constant = 90;
    id<VeeContactProt> veeContact = [_veeSectionedArrayDataSource tableView:tableView itemAtIndexPath:indexPath];
    if (self.searchDisplayController.active) {
        _isAddingFromSearchController = YES;
    	indexPath = [_veeSectionedArrayDataSource indexPathForItem:veeContact];
    }else
        _isAddingFromSearchController = NO;    
    
    [self checkContactIsSelected:veeContact forOperation:Insert indexPath:indexPath];
    if (_contactPickerDelegate) {
        [_contactPickerDelegate didSelectContact:veeContact];
    }
    if (_contactSelectionHandler) {
        _contactSelectionHandler(veeContact);
    }
    if ([self.searchDisplayController isActive]) {
        [self.searchDisplayController setActive:NO animated:YES];
    }
    
    //  [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    _isRemovingFromHeader = NO;
    id<VeeContactProt> veeContact = [_veeSectionedArrayDataSource tableView:tableView itemAtIndexPath:indexPath];
    
    [self checkContactIsSelected:veeContact forOperation:Remove indexPath:indexPath];
    
}
#pragma mark - VeeSearchResultDelegate

- (void)handleSearchResults:(NSArray*)searchResults forSearchTableView:(UITableView*)searchTableView
{
    [_veeSectionedArrayDataSource setSearchResults:searchResults forSearchTableView:searchTableView];
}

#pragma mark - CollectionView Delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return _selectedContactsArray.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    ContactPickerCell * cell = (ContactPickerCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    [cell setIndex:indexPath.row];
    __block typeof(self) weakSelf = self;
    [cell setRemoveContactClickedBlock:^(int itemIndex, VeeContact *contactToRemove) {
        self.isRemovingFromHeader = YES;
        
        NSIndexPath *indexPathCorrespondingToTable = [self.selectedContactsIndexArray objectAtIndex:indexPath.item];
        id<VeeContactProt> veeContact = [self.veeSectionedArrayDataSource tableView:self.contactsTableView itemAtIndexPath:indexPathCorrespondingToTable];
        [self checkContactIsSelected:veeContact forOperation:Remove indexPath:indexPathCorrespondingToTable];
    }];
    [cell setContact:[self.selectedContactsArray objectAtIndex:indexPath.row]];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return CGSizeMake(60, 90);
}
#pragma mark - Private Methods

-(void)removeSelectedContactFromHeaderViewAtIndex:(int)index indexPathCorrespondingToTable:(NSIndexPath *)indexPathCorrespondingToTable {
    
    [_selectedContactsArray removeObjectAtIndex:index];
    [_selectedContactsCollectionView reloadData];
    if (_selectedContactsArray.count == 0)
        [self hideSelectedContactsView];
    if (_isRemovingFromHeader)
        [_contactsTableView reloadRowsAtIndexPaths:@[indexPathCorrespondingToTable] withRowAnimation:UITableViewRowAnimationAutomatic];
}

-(void)addSelectedContactToHeaderView:(VeeContact *)contact {
    
    [_selectedContactsArray addObject:contact];
    NSIndexPath *index =  [NSIndexPath indexPathForRow:_selectedContactsArray.count-1 inSection:0];
    [_selectedContactsCollectionView reloadData];
    [_selectedContactsCollectionView layoutIfNeeded];
    [_selectedContactsCollectionView scrollToItemAtIndexPath:index atScrollPosition:UICollectionViewScrollPositionRight animated:YES];
}

-(void)checkContactIsSelected:(VeeContact *)contact forOperation:(OperationType)operation indexPath:(NSIndexPath *)indexPath {
    
    __block NSInteger foundIndex = NSNotFound;
    
    switch (operation) {
        case Insert:{
            [self addSelectedContactToHeaderView:contact];
            [_nonSelectedContacts removeObject:contact];
            [_selectedContactsIndexArray addObject:indexPath];
            if (_isAddingFromSearchController) {
                __block typeof(self) weakSelf = self;
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSMutableArray *selectedCellsIndexArray;
                    
                    if ([_contactsTableView indexPathsForSelectedRows] != nil)
                        selectedCellsIndexArray = [[_contactsTableView indexPathsForSelectedRows] mutableCopy];
                    else
                        selectedCellsIndexArray  = [NSMutableArray array];
                    
                    [selectedCellsIndexArray addObject:indexPath];
                    [_contactsTableView reloadData];
                    for (NSIndexPath *index in selectedCellsIndexArray) {
                        [_contactsTableView selectRowAtIndexPath:index animated:YES scrollPosition:UITableViewRowAnimationAutomatic];
                    }
                });
            }
        }
            break;
        case Remove: {
            [_selectedContactsArray enumerateObjectsUsingBlock:^(VeeContact *obj, NSUInteger idx, BOOL *stop) {
                if ([obj.firstName isEqualToString:contact.firstName]  ) {
                    foundIndex = idx;
                    [_nonSelectedContacts addObject:obj];
                    // stop the enumeration
                    *stop = YES;
                }
            }];
            [_selectedContactsIndexArray removeObject:indexPath];
        }
            break;
        default:
            break;
    }
    
    if (foundIndex != NSNotFound) {
        [self removeSelectedContactFromHeaderViewAtIndex:foundIndex indexPathCorrespondingToTable:indexPath];
    }
}

#pragma mark - IBActions

- (IBAction)cancelBarButtonItemPressed:(id)sender
{
    [_contactPickerDelegate didCancelContactSelection];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)nextButtonTapped:(id)sender {
    [_rightBarButtonItem setTitle:@"Continue"];
    [_rightBarButtonItem setAction:@selector(continueButtonTapped:)];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [UIView animateWithDuration:20.0f
                              delay:0.0f
                            options:UIViewAnimationOptionTransitionFlipFromTop
                         animations:^{
                             _groupHederViewHeightConstraint.constant = 150;
                         }
                         completion:nil];
        
    });
}

-(void)continueButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
