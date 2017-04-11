/*
 Copyright 2017 Vector Creations Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "PeopleViewController.h"

#import "UIViewController+RiotSearch.h"

#import "RageShakeManager.h"

#import "AppDelegate.h"

#import "RecentsDataSource.h"
#import "RecentTableViewCell.h"
#import "InviteRecentTableViewCell.h"

#import "ContactTableViewCell.h"

@interface PeopleViewController ()
{
    NSInteger          directRoomsSectionNumber;
    
    ContactsDataSource *contactsDataSource;
    NSInteger          contactsSectionNumber;
}

@end

@implementation PeopleViewController

- (void)finalizeInit
{
    [super finalizeInit];
    
    directRoomsSectionNumber = 0;
    contactsSectionNumber = 0;
    
    self.screenName = @"People";
    
    // Prepare its contacts data source
    contactsDataSource = [[ContactsDataSource alloc] init];
    contactsDataSource.contactCellAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
    contactsDataSource.delegate = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view.accessibilityIdentifier = @"PeopleVCView";
    self.recentsTableView.accessibilityIdentifier = @"PeopleVCTableView";
    
    // Add room creation button programmatically
    [self addRoomCreationButton];
    
    // Register table view cell for contacts.
    [self.recentsTableView registerClass:ContactTableViewCell.class forCellReuseIdentifier:ContactTableViewCell.defaultReuseIdentifier];
    
    // Redirect table data source
    self.recentsTableView.dataSource = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)destroy
{
    contactsDataSource.delegate = nil;
    [contactsDataSource destroy];
    contactsDataSource = nil;
    
    [super destroy];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [AppDelegate theDelegate].masterTabBarController.navigationItem.title = NSLocalizedStringFromTable(@"title_people", @"Vector", nil);
    
    if ([self.dataSource isKindOfClass:RecentsDataSource.class])
    {
        // Take the lead on the shared data source.
        RecentsDataSource *recentsDataSource = (RecentsDataSource*)self.dataSource;
        recentsDataSource.areSectionsShrinkable = NO;
        [recentsDataSource setDelegate:self andRecentsDataSourceMode:RecentsDataSourceModePeople];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    if ([cellData isKindOfClass:MXKContact.class])
    {
        return ContactTableViewCell.class;
    }
    
    return [super cellViewClassForCellData:cellData];
}

- (void)dataSource:(MXKDataSource *)dataSource didCellChange:(id)changes
{
    // Refresh the full table
    [self refreshRecentsTable];
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Retrieve the current number of sections related to the direct rooms.
    // Sanity check: check whether the recents data source is correctly configured.
    directRoomsSectionNumber = 0;
    if ([self.dataSource isKindOfClass:RecentsDataSource.class])
    {
        RecentsDataSource *recentsDataSource = (RecentsDataSource*)self.dataSource;
        if (recentsDataSource.recentsDataSourceMode == RecentsDataSourceModePeople)
        {
            directRoomsSectionNumber = [self.dataSource numberOfSectionsInTableView:self.recentsTableView];
        }
    }
    
    // Retrieve the current number of sections related to the contacts
    contactsSectionNumber = [contactsDataSource numberOfSectionsInTableView:self.recentsTableView];
    
    return (directRoomsSectionNumber + contactsSectionNumber);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    if (section < directRoomsSectionNumber)
    {
        count = [self.dataSource tableView:tableView numberOfRowsInSection:section];
    }
    else
    {
        section -= directRoomsSectionNumber;
        if (section < contactsSectionNumber)
        {
            count = [contactsDataSource tableView:tableView numberOfRowsInSection:section];
        }
    }
    
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    
    if (section < directRoomsSectionNumber)
    {
        return [self.dataSource tableView:tableView cellForRowAtIndexPath:indexPath];
    }
    else
    {
        section -= directRoomsSectionNumber;
        if (section < contactsSectionNumber)
        {
            return [contactsDataSource tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:section]];
        }
    }
    
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    
    if (section < directRoomsSectionNumber)
    {
        return [self.dataSource tableView:tableView canEditRowAtIndexPath:indexPath];
    }
    else
    {
        section -= directRoomsSectionNumber;
        if (section < contactsSectionNumber)
        {
            return [contactsDataSource tableView:tableView canEditRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:section]];
        }
    }
    
    return NO;
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section >= directRoomsSectionNumber)
    {
        // Let the contact dataSource provide the height of the section header.
        section -= directRoomsSectionNumber;
        if (section < contactsSectionNumber)
        {
            return [contactsDataSource heightForHeaderInSection:section];
        }
        else
        {
            return 0.0;
        }
    }
    
    return [super tableView:tableView heightForHeaderInSection:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section >= directRoomsSectionNumber)
    {
        // Let the contact dataSource provide the section header.
        CGRect frame = [tableView rectForHeaderInSection:section];
        section -= directRoomsSectionNumber;
        if (section < contactsSectionNumber)
        {
            return [contactsDataSource viewForHeaderInSection:section withFrame:frame];
        }
        else
        {
            return nil;
        }
    }
    
    return [super tableView:tableView viewForHeaderInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    if (section >= directRoomsSectionNumber)
    {
        section -= directRoomsSectionNumber;
        if (section < contactsSectionNumber)
        {
            // Return the default height of the contact cell
            return 74.0;
        }
        else
        {
            return 0.0;
        }
    }
    
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    if (section >= directRoomsSectionNumber)
    {
        section -= directRoomsSectionNumber;
        if (section < contactsSectionNumber)
        {
            MXKContact *mxkContact = [contactsDataSource contactAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:section]];
            
            if (mxkContact)
            {
                [[AppDelegate theDelegate].masterTabBarController selectContact:mxkContact];
                
                // Keep selected the cell by default.
                return;
            }
        }
        else
        {
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
            return;
        }
    }
    
    return [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark -

- (void)refreshCurrentSelectedCell:(BOOL)forceVisible
{
    // Update here the index of the current selected cell (if any) - Useful in landscape mode with split view controller.
    NSIndexPath *currentSelectedCellIndexPath = nil;
    MasterTabBarController *masterTabBarController = [AppDelegate theDelegate].masterTabBarController;
    if (masterTabBarController.currentContactDetailViewController)
    {
        // Look for the rank of this selected contact
        currentSelectedCellIndexPath = [contactsDataSource cellIndexPathWithContact:masterTabBarController.selectedContact];
        
        if (currentSelectedCellIndexPath)
        {
            // Select the right row
            currentSelectedCellIndexPath = [NSIndexPath indexPathForRow:currentSelectedCellIndexPath.row inSection:(directRoomsSectionNumber + currentSelectedCellIndexPath.section)];
            [self.recentsTableView selectRowAtIndexPath:currentSelectedCellIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            
            if (forceVisible)
            {
                // Scroll table view to make the selected row appear at second position
                NSInteger topCellIndexPathRow = currentSelectedCellIndexPath.row ? currentSelectedCellIndexPath.row - 1: currentSelectedCellIndexPath.row;
                NSIndexPath* indexPath = [NSIndexPath indexPathForRow:topCellIndexPathRow inSection:currentSelectedCellIndexPath.section];
                [self.recentsTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
            }
        }
        else
        {
            NSIndexPath *indexPath = [self.recentsTableView indexPathForSelectedRow];
            if (indexPath)
            {
                [self.recentsTableView deselectRowAtIndexPath:indexPath animated:NO];
            }
        }
    }
    else
    {
        [super refreshCurrentSelectedCell:forceVisible];
    }
}

#pragma mark - Actions

- (void)onRoomCreationButtonPressed
{
    [self performSegueWithIdentifier:@"presentStartChat" sender:self];
}

@end