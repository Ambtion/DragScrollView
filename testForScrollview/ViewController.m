//
//  ViewController.m
//  testForScrollview
//
//  Created by Qu,Ke on 2019/10/24.
//  Copyright © 2019 baidu. All rights reserved.
//

#import "ViewController.h"
#import "MCDragTableView.h"

#import "TestTableView.h"

@interface ViewController ()<MCDragViewLayoutDelegate,MCDragTableViewDataSource>

@property(nonatomic,strong)UIView * headView;
@property(nonatomic,strong)MCDragTableView * dragView;
@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.dragView = [[MCDragTableView alloc] initWithFrame:CGRectMake(0,
                                                                 self.view.bounds.size.height - 200,
                                                                 self.view.bounds.size.width,
                                                                 self.view.bounds.size.height)];
    self.dragView.dragLayoutDelegate = self;
    self.dragView.dataSource = self;
    self.dragView.delegate = self;
    [self.view addSubview:self.dragView];
    
}


- (CGFloat)mcdragViewbottomSpace{
    return 14.f;
}

- (CGFloat)mcdragViewtopSpace{
    return 200;
}

- (void)mcdragViewDragPer:(CGFloat)per{
    
}

#pragma mark - Test
- (NSInteger)numberOfRowsInMCDragTableView:(MCDragTableView *)tableView {
    return 100;
}

- (CGFloat)mcTableView:(MCDragTableView *)tableView heightForRowAtIndex:(NSInteger)index {
    return 40;
}

- (UITableViewCell *)mcTableView:(MCDragTableView *)tableView cellForRowAtIndex:(NSInteger)index {
    
    UITableViewCell * cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CELL"];
  
    cell.textLabel.text = [NSString stringWithFormat:@"index is %ld",index];
    cell.backgroundColor = [UIColor redColor];
    if (index == 2) {
        cell.backgroundColor = [UIColor greenColor];
    }
    return cell;
}

- (BOOL)mcTableView:(MCDragTableView *)tableView rowAtIndexChangeFrame:(NSInteger)index {
    if (index == 2 || index == 4) {
        return YES;
    }
    return NO;
}

-(void)mcTableView:(MCDragTableView *)tableView didSelectRowAtIndex:(NSInteger)index {
    NSLog(@"Tap %d",index);
    NSLog(@"%@",[tableView visibleCells]);
    UITableViewCell * cell = [tableView cellForRowAtIndex:index];
    NSLog(@"Tap %d",cell.tag);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    
}
@end
