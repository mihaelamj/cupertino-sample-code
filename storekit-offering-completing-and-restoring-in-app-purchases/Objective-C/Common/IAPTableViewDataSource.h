/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that adopts IAP tableview data source must reload its UI with the provided data.
*/

@import Foundation;

@protocol IAPTableViewDataSource <NSObject>
/// Tells the receiver to reload its UI with the provided data.
-(void)reloadWithData:(NSArray *)data;

@end
