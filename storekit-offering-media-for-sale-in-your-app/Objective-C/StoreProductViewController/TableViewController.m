/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The table view controller for presenting the App Store when the user selects
 an iTunes product available for sale from its UI.
*/

@import StoreKit;
#import "Product.h"
#import "TableViewController.h"
#import "NSString+Additions.h"

@interface TableViewController () <SKStoreProductViewControllerDelegate>
@property (strong) NSMutableArray *products;
@end

@implementation TableViewController
#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Fetch all the products.
    NSURL *plistURL = [[NSBundle mainBundle] URLForResource:@"Products" withExtension:@"plist"];
    NSArray *temp = [NSArray arrayWithContentsOfURL:plistURL];
    
    self.products = [[NSMutableArray alloc] initWithCapacity:0];
    Product *item;
    
    for (NSDictionary *dictionary in temp) {
        NSString *title = dictionary[@"title"];
        NSString *productIdentifier = dictionary[@"productIdentifier"];
        
        
        // Provide these data as the README file explains.
        if (title.length > 0 && productIdentifier.length > 0) {
            // Create a product object to store all its properties.
            item = [[Product alloc] initWithTitle:title
                                productIdentifier:productIdentifier
                                    isApplication:dictionary[@"isApplication"]
                                    campaignToken:dictionary[@"campaignToken"]
                                    providerToken:dictionary[@"providerToken"]];
            
            // Keep track of all the products.
            [self.products addObject:item];
        } else {
            NSLog(@"The title and productIdentifier properties cannot be set to an empty string. Update their value in Products.plist.");
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.products.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [tableView dequeueReusableCellWithIdentifier:@"productID" forIndexPath:indexPath];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    Product *item = (Product *)(self.products)[indexPath.row];
    cell.textLabel.text = item.title;
}

/// Loads and launches a store product view controller with a selected product.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Product *item = (Product *)(self.products)[indexPath.row];
    [self showStoreForProduct:item];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/// Presents a page where users can purchase the specified `product` from the App Store.
-(void)showStoreForProduct:(Product *)product {
    // Create a product dictionary using the selected product's iTunes identifier.
    NSMutableDictionary *parametersDictionary = [[NSMutableDictionary alloc] init];
    [parametersDictionary setValue:@((product.productIdentifier).intValue) forKey:SKStoreProductParameterITunesItemIdentifier];
    
    /*
        Update `parametersDictionary` with the `campaignToken` and `providerToken`
        values if they exist and the specified `product` is an app.
    */
    if(product.isApplication && product.campaignToken.exists && product.providerToken.exists) {
        [parametersDictionary setValue:product.campaignToken forKey:SKStoreProductParameterCampaignToken];
        [parametersDictionary setValue:product.providerToken forKey:SKStoreProductParameterProviderToken];
    }
    
    // Create a store product view controller.
    SKStoreProductViewController* storeProductViewController = [[SKStoreProductViewController alloc] init];
    storeProductViewController.delegate = self;
    
    /*
        Attempt to load the selected product from the App Store. Display the
        store product view controller if successful. Print an error message,
        otherwise.
    */
    [storeProductViewController loadProductWithParameters:parametersDictionary completionBlock:^(BOOL result, NSError *error) {
        if(result) {
            [self presentViewController:storeProductViewController animated:YES completion:^{
                NSLog(@"The store view controller was presented.");
            }];
        } else {
            if (error != nil) {
                NSLog(@"Error message: %@",error.localizedDescription);
            }
        }
    }];
}

#pragma mark - SKStoreProductViewControllerDelegate

/// Use this method to dismiss the store view controller.
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [viewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
        NSLog(@"The store view controller was dismissed.");
    }];
}
@end
