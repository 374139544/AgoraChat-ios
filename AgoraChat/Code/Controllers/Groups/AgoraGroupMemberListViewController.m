/************************************************************
 *  * Hyphenate
 * __________________
 * Copyright (C) 2016 Hyphenate Inc. All rights reserved.
 *
 * NOTICE: All information contained herein is, and remains
 * the property of Hyphenate Inc.
 */

#import "AgoraGroupMemberListViewController.h"
#import "AgoraUserModel.h"
#import "AgoraNotificationNames.h"
#import "AgoraGroupMemberCell.h"

@interface AgoraGroupMemberListViewController ()<AgoraGroupUIProtocol>

@property (nonatomic, strong) NSArray *occupants;

@property (nonatomic, strong) AgoraChatGroup *group;

@property (nonatomic, strong) NSMutableArray *selectMembers;

@end

@implementation AgoraGroupMemberListViewController
{
    NSString *_cellIdentifier;
    UIButton *_leftButton;
    UIButton *_rightButton;
    BOOL _isEditing;
}

- (instancetype)initWithOccupants:(NSArray<AgoraUserModel *> *)occupants {
    self = [super initWithNibName:@"AgoraGroupMemberListViewController" bundle:nil];
    if (self) {
        _occupants = [NSArray arrayWithArray:occupants];
        _cellIdentifier = @"AgoraGroupMemberCell";
        _group = nil;
        _isEditing = NO;
        _selectMembers = [NSMutableArray array];
    }
    return self;
}

- (instancetype)initWithGroup:(AgoraChatGroup *)group occupants:(NSArray<AgoraUserModel *> *)occupants {
    self = [self initWithOccupants:occupants];
    if (self) {
        _group = group;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"title.memberList", @"Member List");
    self.tableView.tableFooterView = [UIView new];
    [self setupNavBar];
}

- (void)setupNavBar {
    _leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _leftButton.frame = CGRectMake(0, 0, 20, 20);
    [_leftButton setImage:[UIImage imageNamed:@"Icon_Back"] forState:UIControlStateNormal];
    [_leftButton setImage:[UIImage imageNamed:@"Icon_Back"] forState:UIControlStateHighlighted];
    [_leftButton addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftBar = [[UIBarButtonItem alloc] initWithCustomView:_leftButton];
    [self.navigationItem setLeftBarButtonItem:leftBar];
    if ([self isGroupOwner]) {
        
        _leftButton.titleLabel.font = [UIFont systemFontOfSize:13];
        [_leftButton setTitleColor:KermitGreenTwoColor forState:UIControlStateNormal];
        [_leftButton setTitleColor:KermitGreenTwoColor forState:UIControlStateHighlighted];
        
        _rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _rightButton.frame = CGRectMake(0, 0, 50, 44);
        _rightButton.titleLabel.font = [UIFont systemFontOfSize:13];
        [_rightButton setTitleColor:KermitGreenTwoColor forState:UIControlStateNormal];
        [_rightButton setTitleColor:KermitGreenTwoColor forState:UIControlStateHighlighted];
        [_rightButton setTitle:NSLocalizedString(@"common.edit", @"Edit") forState:UIControlStateNormal];
        [_rightButton setTitle:NSLocalizedString(@"common.edit", @"Edit") forState:UIControlStateHighlighted];
        [_rightButton addTarget:self action:@selector(editAction) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *rightBar = [[UIBarButtonItem alloc] initWithCustomView:_rightButton];
        [self.navigationItem setRightBarButtonItem:rightBar];
    }
}

- (BOOL)isGroupOwner {
    return [_group.owner isEqualToString:[AgoraChatClient sharedClient].currentUsername];
}

- (void)updateNavBarItemStyle {
    if (![self isGroupOwner]) {
        return;
    }
    
    if (_isEditing) {
        _leftButton.frame = CGRectMake(0, 0, 44, 44);
        [_leftButton setTitle:NSLocalizedString(@"common.cancel", @"Cancel") forState:UIControlStateNormal];
        [_leftButton setTitle:NSLocalizedString(@"common.cancel", @"Cancel") forState:UIControlStateHighlighted];
        [_leftButton setImage:nil forState:UIControlStateNormal];
        [_leftButton setImage:nil forState:UIControlStateHighlighted];
        [_leftButton removeTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
        [_leftButton addTarget:self action:@selector(cancelAction) forControlEvents:UIControlEventTouchUpInside];
        
        [_rightButton setTitle:NSLocalizedString(@"common.remove", @"Remove") forState:UIControlStateNormal];
        [_rightButton setTitle:NSLocalizedString(@"common.remove", @"Remove") forState:UIControlStateHighlighted];
        [_rightButton removeTarget:self action:@selector(editAction) forControlEvents:UIControlEventTouchUpInside];
        [_rightButton addTarget:self action:@selector(removeAction) forControlEvents:UIControlEventTouchUpInside];
    }
    else {
        _leftButton.frame = CGRectMake(0, 0, 20, 20);
        [_leftButton setImage:[UIImage imageNamed:@"Icon_Back"] forState:UIControlStateNormal];
        [_leftButton setImage:[UIImage imageNamed:@"Icon_Back"] forState:UIControlStateHighlighted];
        [_leftButton setTitle:@"" forState:UIControlStateNormal];
        [_leftButton setTitle:@"" forState:UIControlStateHighlighted];
        [_leftButton removeTarget:self action:@selector(cancelAction) forControlEvents:UIControlEventTouchUpInside];
        [_leftButton addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
        
        [_rightButton setTitle:NSLocalizedString(@"common.edit", @"Edit") forState:UIControlStateNormal];
        [_rightButton setTitle:NSLocalizedString(@"common.edit", @"Edit") forState:UIControlStateHighlighted];
        [_rightButton removeTarget:self action:@selector(removeAction) forControlEvents:UIControlEventTouchUpInside];
        [_rightButton addTarget:self action:@selector(editAction) forControlEvents:UIControlEventTouchUpInside];
    }
}

#pragma mark - Action
- (void)backAction {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)cancelAction {
    _isEditing = NO;
    [self.tableView reloadData];
    [self performSelector:@selector(updateNavBarItemStyle) withObject:nil afterDelay:0.1];
}

- (void)editAction {
    _isEditing = YES;
    [self.tableView reloadData];
    [self performSelector:@selector(updateNavBarItemStyle) withObject:nil afterDelay:0.1];
}

- (void)removeAction {
    _isEditing = NO;
    [self.tableView reloadData];
    [self performSelector:@selector(updateNavBarItemStyle) withObject:nil afterDelay:0.1];
    if (_selectMembers.count == 0 || ![self isGroupOwner]) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [[AgoraChatClient sharedClient].groupManager removeMembers:_selectMembers fromGroup:self.group.groupId completion:^(AgoraChatGroup *aGroup, AgoraChatError *aError) {
        if (!aError) {
            NSMutableArray *array = [NSMutableArray arrayWithArray:weakSelf.occupants];
            __block NSMutableArray *removeModels = [NSMutableArray array];
            [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:[AgoraUserModel class]]) {
                    AgoraUserModel *model = (AgoraUserModel *)obj;
                    if ([weakSelf.selectMembers containsObject:model.hyphenateId]) {
                        [array removeObject:obj];
                        [removeModels addObject:obj];
                    }
                }
            }];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"group.removeSuccess", @"Remove group members successfully")  delegate:nil cancelButtonTitle:NSLocalizedString(@"common.ok", @"OK") otherButtonTitles:nil, nil];
            [alertView show];
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(removeSelectOccupants:)]) {
                [weakSelf.delegate removeSelectOccupants:removeModels];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:KAgora_REFRESH_GROUPLIST_NOTIFICATION object:nil];
            [weakSelf.navigationController popViewControllerAnimated:YES];
        }
        else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"group.removeFailure", @"Remove group members failure")  delegate:nil cancelButtonTitle:NSLocalizedString(@"common.ok", @"OK") otherButtonTitles:nil, nil];
            [alertView show];
        }
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _occupants.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AgoraGroupMemberCell *cell = [tableView dequeueReusableCellWithIdentifier:_cellIdentifier];
    if (!cell) {
        cell = [[[NSBundle mainBundle] loadNibNamed:_cellIdentifier owner:self options:nil] lastObject];
    }
    cell.delegate = self;
    AgoraUserModel *model = _occupants[indexPath.row];
    cell.isGroupOwner = [model.hyphenateId isEqualToString:_group.owner];
    cell.isEditing = _isEditing;
    cell.isSelected = [_selectMembers containsObject:model.hyphenateId];
    cell.model = model;
    return cell;
}
#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50.0f;
}

#pragma mark - AgoraGroupUIProtocol

- (void)addSelectOccupants:(NSArray<AgoraUserModel *> *)modelArray {
    for (AgoraUserModel *model in modelArray) {
        [_selectMembers addObject:model.hyphenateId];
    }
}

- (void)removeSelectOccupants:(NSArray<AgoraUserModel *> *)modelArray {
    for (AgoraUserModel *model in modelArray) {
        [_selectMembers removeObject:model.hyphenateId];
    }
}

@end
