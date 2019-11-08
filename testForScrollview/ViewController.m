//
//  ViewController.m
//  testForScrollview
//
//  Created by Qu,Ke on 2019/10/24.
//  Copyright © 2019 baidu. All rights reserved.
//

#import "ViewController.h"
#import "MCDragView.h"
#import "TestTableView.h"

@interface ViewController ()<MCDragViewLayoutDelegate,UITableViewDataSource>

@property(nonatomic,strong)UIView * headView;
@property(nonatomic,strong)MCDragView * dragView;
@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.dragView = [[MCDragView alloc] initWithFrame:CGRectMake(0,
                                                                 self.view.bounds.size.height - 200,
                                                                 self.view.bounds.size.width,
                                                                 self.view.bounds.size.height)];
    self.dragView.dragLayoutDelegate = self;
    self.dragView.dataSource = self;
    [self.view addSubview:self.dragView];
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
    [self.view addGestureRecognizer:tap];
    self.headView = [[UIView alloc] initWithFrame:CGRectMake(0, self.dragView.frame.origin.y, self.view.bounds.size.width, 100)];
    self.headView.backgroundColor = [UIColor redColor];
    [self.view insertSubview:self.headView belowSubview:self.dragView];
    
}

- (void)tapGesture:(UITapGestureRecognizer *)tapges{
    [self.dragView changeToBottomScreen:^(BOOL finished) {
        
    }];
}

- (CGFloat)mcdragViewbottomSpace{
    return 14.f;
}

- (CGFloat)mcdragViewtopSpace{
    return 200;
}

- (void)mcdragViewDragPer:(CGFloat)per{
    NSLog(@"xxxxx %f",per);
    CGRect rect = self.headView.frame;
    rect.origin.y = self.dragView.frame.origin.y - rect.size.height * per;
    self.headView.frame = rect;
    self.headView.alpha = per;
}

#pragma mark - Test
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"CELL"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CELL"];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"index is %ld",indexPath.row];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath{
    NSLog(@"Tap");
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    
}
@end
