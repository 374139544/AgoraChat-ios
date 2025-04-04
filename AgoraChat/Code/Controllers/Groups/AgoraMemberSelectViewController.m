/************************************************************
 *  * Hyphenate
 * __________________
 * Copyright (C) 2016 Hyphenate Inc. All rights reserved.
 *
 * NOTICE: All information contained herein is, and remains
 * the property of Hyphenate Inc.
 */

#import "AgoraMemberSelectViewController.h"
#import "AgoraUserModel.h"
#import "AgoraRealtimeSearchUtils.h"
#import "NSArray+AgoraSortContacts.h"
#import "AgoraGroupMemberCell.h"
#import "ACDMemberCollectionCell.h"


#define NEXT_TITLE   NSLocalizedString(@"common.next", @"Next")

#define DONE_TITLE   @"Done"

#define kSearchBarHeight 32.0

@interface AgoraMemberSelectViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate>
@property (strong, nonatomic) IBOutlet UIView *headerView;

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;

@property (strong, nonatomic) IBOutlet UICollectionView *selectConllection;

@property (strong, nonatomic) IBOutlet AgoraChatBaseTableview *tableView;


@property (strong, nonatomic) NSMutableArray<AgoraUserModel *> *selectContacts;

@property (strong, nonatomic) NSMutableArray<NSMutableArray *> *unselectedContacts;

@property (nonatomic) NSInteger maxInviteCount;

@end

@interface AgoraSectionTitleHeader : UIView

@property (nonatomic, strong) NSString *title;

+ (CGFloat)sectionHeight;

@end

@implementation AgoraMemberSelectViewController
{
    UIButton *_doneBtn;
    NSMutableArray *_hasInvitees;
    NSMutableArray *_sectionTitles;
    NSMutableArray *_searchSource;
    NSMutableArray *_searchResults;
    BOOL _isSearchState;
}

- (instancetype)initWithInvitees:(NSArray *)aHasInvitees
                  maxInviteCount:(NSInteger)aCount
{
    self = [super initWithNibName:@"AgoraMemberSelectViewController" bundle:nil];
    if (self) {
        _selectContacts = [NSMutableArray array];
        _unselectedContacts = [NSMutableArray array];
        _hasInvitees = [NSMutableArray arrayWithArray:aHasInvitees];
        _maxInviteCount = aCount;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
//    [self.selectConllection registerNib:[UINib nibWithNibName:@"AgoraMemberCollection_Edit_Cell" bundle:nil] forCellWithReuseIdentifier:@"AgoraMemberCollection_Edit_Cell"];
    
    [self.selectConllection registerClass:[ACDMemberCollectionCell class] forCellWithReuseIdentifier:[ACDMemberCollectionCell reuseIdentifier]];
    
    
    self.tableView.tableFooterView = [UIView new];
    self.selectConllection.backgroundColor = UIColor.whiteColor;
    self.tableView.backgroundColor = UIColor.whiteColor;
    self.tableView.sectionIndexColor = SectionIndexTextColor;
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle  = UITableViewCellSeparatorStyleNone;

    [self setupNavBar];
    [self loadUnSelectContacts];
    [self setupSearchBar];
}
    
- (void)setupSearchBar {
    CGRect frame = _searchBar.frame;
    frame.size.height = kSearchBarHeight;
    _searchBar.frame = frame;
    _searchBar.placeholder = NSLocalizedString(@"common.search", @"Search");
    _searchBar.showsCancelButton = NO;
    _searchBar.backgroundImage = [UIImage imageWithColor:[UIColor whiteColor] size:_searchBar.bounds.size];
    [_searchBar setSearchFieldBackgroundPositionAdjustment:UIOffsetMake(0, 0)];
    _searchBar.tintColor = AlmostBlackColor;
    
    UITextField *searchField = [_searchBar valueForKey:@"searchField"];
      if (searchField) {
              if (@available(iOS 13.0, *)){
                  _searchBar.searchTextField.backgroundColor= COLOR_HEX(0xF2F2F2);
              }else{
                  searchField.backgroundColor = COLOR_HEX(0xF2F2F2);
              }

          searchField.layer.cornerRadius = kSearchBarHeight * 0.5;
          searchField.layer.masksToBounds = YES;
      }
}


- (void)setupNavBar {
    UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    leftBtn.frame = CGRectMake(0, 0, 20, 20);
    [leftBtn setImage:[UIImage imageNamed:@"gray_goBack"] forState:UIControlStateNormal];
    [leftBtn setImage:[UIImage imageNamed:@"gray_goBack"] forState:UIControlStateHighlighted];
    [leftBtn addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftBar = [[UIBarButtonItem alloc] initWithCustomView:leftBtn];
    [self.navigationItem setLeftBarButtonItem:leftBar];
    
    _doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _doneBtn.frame = CGRectMake(0, 0, 44, 44);
    [self updateDoneUserInteractionEnabled:NO];
    NSString *title = @"Create";
    if (_style == AgoraContactSelectStyle_Invite) {
        title = DONE_TITLE;
    }

    [_doneBtn setTitle:title forState:UIControlStateNormal];
    [_doneBtn setTitle:title forState:UIControlStateHighlighted];
    _doneBtn.titleLabel.font = [UIFont systemFontOfSize:16.0];
    [_doneBtn setTitleColor:TextLabelBlueColor forState:UIControlStateNormal];
    
    [_doneBtn addTarget:self action:@selector(selectDoneAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rightBar = [[UIBarButtonItem alloc] initWithCustomView:_doneBtn];
    [self.navigationItem setRightBarButtonItem:rightBar];
}

- (void)updateHeaderView:(BOOL)isAdd {
    if (_selectContacts.count > 0 && self.selectConllection.hidden) {
        CGFloat height = self.selectConllection.frame.size.height;
        CGRect frame = self.headerView.frame;
        frame.size.height += height;
        self.headerView.frame = frame;
        
        frame = self.tableView.frame;
        frame.origin.y += height;
        frame.size.height -= height;
        self.tableView.frame = frame;
        [_selectConllection reloadData];
        self.selectConllection.hidden = NO;
        
        return;
    }
    if (_selectContacts.count == 0 && !self.selectConllection.hidden) {
        self.selectConllection.hidden = YES;
        CGFloat height = self.selectConllection.frame.size.height;
        CGRect frame = self.headerView.frame;
        frame.size.height -= height;
        self.headerView.frame = frame;
        
        frame = self.tableView.frame;
        frame.origin.y -= height;
        frame.size.height += height;
        self.tableView.frame = frame;
        [_selectConllection reloadData];
        return;
    }
    if (isAdd) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:_selectContacts.count - 1 inSection:0];
        [_selectConllection insertItemsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil]];
    }
}

- (void)updateDoneUserInteractionEnabled:(BOOL)userInteractionEnabled {
    _doneBtn.userInteractionEnabled = userInteractionEnabled;
    if (userInteractionEnabled) {
        [_doneBtn setTitleColor:TextLabelBlueColor forState:UIControlStateNormal];
        [_doneBtn setTitleColor:TextLabelBlueColor forState:UIControlStateHighlighted];
    }
    else {
        [_doneBtn setTitleColor:CoolGrayColor forState:UIControlStateNormal];
        [_doneBtn setTitleColor:CoolGrayColor forState:UIControlStateHighlighted];
    }
}

- (void)loadUnSelectContacts {
    NSMutableArray *contacts = [NSMutableArray arrayWithArray:[[AgoraChatClient sharedClient].contactManager getContacts]];
    NSArray *blockList = [[AgoraChatClient sharedClient].contactManager getBlackList];
    [contacts removeObjectsInArray:blockList];
    [contacts removeObjectsInArray:_hasInvitees];
    [_hasInvitees removeAllObjects];
    
    NSMutableArray *sectionTitles = nil;
    NSMutableArray *searchSource = nil;
    NSArray *sortArray = [NSArray sortContacts:contacts
                                 sectionTitles:&sectionTitles
                                  searchSource:&searchSource];
    [self.unselectedContacts addObjectsFromArray:sortArray];
    _sectionTitles = [NSMutableArray arrayWithArray:sectionTitles];
    _searchSource = [NSMutableArray arrayWithArray:searchSource];
}

- (void)removeOccupantsFromDataSource:(NSArray<AgoraUserModel *> *)modelArray {
    __block NSMutableArray *array = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;
    __weak NSMutableArray *weakHasInvitees = _hasInvitees;
    [modelArray enumerateObjectsUsingBlock:^(AgoraUserModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([weakSelf.selectContacts containsObject:obj]) {
            NSUInteger index = [weakSelf.selectContacts indexOfObject:obj];
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
            [array addObject:indexPath];
            [weakHasInvitees removeObject:obj.hyphenateId];
            [weakSelf.selectContacts removeObjectsInArray:modelArray];
        }
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (array.count > 0) {
            [weakSelf.selectConllection deleteItemsAtIndexPaths:array];
        }
        if (weakSelf.selectContacts.count == 0) {
            [self updateDoneUserInteractionEnabled:NO];
        }
        [weakSelf updateHeaderView:NO];
    });
}

#pragma mark - Action

- (void)backAction {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)selectDoneAction {
    if (_delegate && [_delegate respondsToSelector:@selector(addSelectOccupants:)]) {
        [_delegate addSelectOccupants:_selectContacts];
    }
    [self backAction];

    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (_isSearchState) {
        return 1;
    }
    return _sectionTitles.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_isSearchState) {
        return _searchResults.count;
    }
    return [(NSArray *)_unselectedContacts[section] count];
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (_isSearchState) {
        return @[];
    }
    return _sectionTitles;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"AgoraGroupMember_Invite_Cell";
    AgoraGroupMemberCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[AgoraGroupMemberCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
   
    
    AgoraUserModel *model = nil;
    if (_isSearchState) {
        model = _searchResults[indexPath.row];
    }
    else {
        NSMutableArray *array = _unselectedContacts[indexPath.section];
        model = array[indexPath.row];
    }
    cell.isSelected = [_hasInvitees containsObject:model.hyphenateId];
    cell.isEditing = YES;
    cell.model = model;
    cell.delegate = self;
    
    ACD_WS
    cell.tapCellBlock = ^{
        if ([_hasInvitees containsObject:model.hyphenateId]) {
            [weakSelf removeOccupant:model];
        }else {
            [weakSelf addOccupant:model];
        }
        
        NSIndexPath *indexPath = nil;
        if (_isSearchState) {
            indexPath = [weakSelf.tableView indexPathForCell:cell];
        }else {
            indexPath = [weakSelf.tableView indexPathForCell:cell];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        });
    };
    
    return cell;
}

- (void)addOccupant:(AgoraUserModel *)userModel {
    NSInteger maxCount = _hasInvitees.count + 1;
    if (maxCount > _maxInviteCount) {
        [self showHint:KACDGroupCreateMemberLimit];
        return;
    }
    
    [self.selectContacts addObject:userModel];
    [_hasInvitees addObject:userModel.hyphenateId];
    
    [self updateDoneUserInteractionEnabled:YES];
    [self updateHeaderView:YES];
}

- (void)removeOccupant:(AgoraUserModel *)userModel {
    [self removeOccupantsFromDataSource:@[userModel]];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 54.0f;
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.tableView && scrollView.contentOffset.y < 0) {
        [scrollView setContentOffset:CGPointMake(0, 0)];
    }
    if (scrollView == self.selectConllection && scrollView.contentOffset.x < 0) {
        [scrollView setContentOffset:CGPointMake(0, 0)];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _selectContacts.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ACDMemberCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[ACDMemberCollectionCell reuseIdentifier] forIndexPath:indexPath];
    cell.model = _selectContacts[indexPath.row];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    AgoraUserModel *model = _selectContacts[indexPath.row];
    [self removeOccupantsFromDataSource:@[model]];
    [self.tableView reloadData];
}


#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(collectionView.frame.size.width / 5, collectionView.frame.size.height + 10.0);
}


#pragma mark - UISearchBarDelegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
    _isSearchState = YES;
    self.tableView.scrollEnabled = !_isSearchState;
    return YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    self.tableView.scrollEnabled = YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchBar.text.length == 0) {
        _isSearchState = NO;
        self.tableView.scrollEnabled = NO;
        [_searchResults removeAllObjects];
        [self.tableView reloadData];
        return;
    }
    _isSearchState = YES;
    __weak typeof(self) weakSelf = self;
    [[AgoraRealtimeSearchUtils defaultUtil] realtimeSearchWithSource:_searchSource searchString:searchText resultBlock:^(NSArray *results) {
        if (results) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _searchResults = [NSMutableArray arrayWithArray:results];
                [weakSelf.tableView reloadData];
            });
        }
    }];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:NO animated:NO];
    self.tableView.scrollEnabled = YES;
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = @"";
    [searchBar setShowsCancelButton:NO animated:NO];
    [searchBar resignFirstResponder];
    [[AgoraRealtimeSearchUtils defaultUtil] realtimeSearchDidFinish];
    _isSearchState = NO;
    self.tableView.scrollEnabled = !_isSearchState;
    [self.tableView reloadData];
}

@end


@implementation AgoraSectionTitleHeader
{
    UILabel *_titleLabel;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        CGRect screenFrame = [UIScreen mainScreen].bounds;
        self.frame = CGRectMake(0, 0, screenFrame.size.width, [AgoraSectionTitleHeader sectionHeight]);
        self.backgroundColor = CoolGrayColor;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!_titleLabel) {
        CGFloat x = 15;
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, self.frame.size.width - x, self.frame.size.height)];
        _titleLabel.font = [UIFont systemFontOfSize:13];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        [self addSubview:_titleLabel];
    }
    _titleLabel.text = _title;
}

+ (CGFloat)sectionHeight {
    return 20;
}
    
@end

#undef kSearchBarHeight

