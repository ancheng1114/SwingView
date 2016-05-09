//
//  NavViewController.m
//  SwingView
//
//  Created by AnCheng on 4/18/16.
//  Copyright © 2016 AnCheng. All rights reserved.
//

#import "NavViewController.h"

@interface NavViewController ()
{
    BOOL _willTransitionToPortrait;
    UITraitCollection *_traitCollection_CompactRegular;
    UITraitCollection *_traitCollection_AnyAny;
}

@end

@implementation NavViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setUpReferenceSizeClasses];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setUpReferenceSizeClasses {
    UITraitCollection *traitCollection_hCompact = [UITraitCollection traitCollectionWithVerticalSizeClass:UIUserInterfaceSizeClassCompact];
    //UITraitCollection *traitCollection_vRegular = [UITraitCollection traitCollectionWithVerticalSizeClass:UIUserInterfaceSizeClassRegular];
    //_traitCollection_CompactRegular = [UITraitCollection traitCollectionWithTraitsFromCollections:@[traitCollection_hCompact, traitCollection_vRegular]];
    _traitCollection_CompactRegular = [UITraitCollection traitCollectionWithTraitsFromCollections:@[traitCollection_hCompact]];
    
    UITraitCollection *traitCollection_hAny = [UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassUnspecified];
    UITraitCollection *traitCollection_vAny = [UITraitCollection traitCollectionWithVerticalSizeClass:UIUserInterfaceSizeClassUnspecified];
    _traitCollection_AnyAny = [UITraitCollection traitCollectionWithTraitsFromCollections:@[traitCollection_hAny, traitCollection_vAny]];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _willTransitionToPortrait = self.view.frame.size.height > self.view.frame.size.width;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    _willTransitionToPortrait = size.height > size.width;
}

-(UITraitCollection *)overrideTraitCollectionForChildViewController:(UIViewController *)childViewController {
    UITraitCollection *traitCollectionForOverride = _willTransitionToPortrait ? _traitCollection_AnyAny : _traitCollection_CompactRegular;
    return traitCollectionForOverride;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
