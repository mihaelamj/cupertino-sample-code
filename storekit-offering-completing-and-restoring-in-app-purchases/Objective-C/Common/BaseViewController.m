/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The base table view controller for sharing a table view between subclasses.
*/

#import "Section.h"
#import "BaseViewController.h"

@implementation BaseViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    
    if (self != nil) {
        _data = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Returns the number of sections.
    return self.data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    Section *model = (Section *)self.data[section];
    // Returns the number of rows in the section.
    return model.elements.count;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    Section *model = (Section *)self.data[section];
    // Returns the header title for this section.
    return model.name;
}

#pragma mark - IAPTableViewDataSource

-(void)reloadWithData:(NSArray *)data {
    self.data = [data copy];
    [self.tableView reloadData];
}

@end
