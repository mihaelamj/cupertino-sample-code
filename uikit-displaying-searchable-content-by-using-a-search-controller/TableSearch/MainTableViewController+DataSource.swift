/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The data model for the main table view controller.
*/

import UIKit

extension MainTableViewController {
    
    enum Localization: String {
        case ginger = "GingerTitle"
        case gladiolus = "Gladiolus"
        case orchid = "Orchid"
        case geranium = "Geranium"
        case daisy = "Daisy"
        case poinsettiaRed = "Poinsettia Red"
        case poinsettiaPink = "Poinsettia Pink"
        case redRose = "Red Rose"
        case whiteRose = "White Rose"
        case tulip = "Tulip"
        case carnationRed = "Carnation Red"
        case carnationWhite = "Carnation White"
        case sunFlower = "Sunflower"
        case gardenia = "Gardenia"
        case daffodil = "Daffodil"
        
        func localized(args: CVarArg...) -> String {
            let localizedString = NSLocalizedString(self.rawValue, comment: "")
            return withVaList(args, { (args) -> String in
                return NSString(format: localizedString, locale: Locale.current, arguments: args) as String
            })
        }
    }
    
    func quantity(forType: Product.ProductType) -> Int {
        var quantity = 0
        for product in products
            where product.type == forType.rawValue {
                quantity += 1
        }
        return quantity
    }
    
    func product(forIndexPath: IndexPath) -> Product {
        var product: Product!
                
        let quantityForBirthdays = quantity(forType: Product.ProductType.birthdays)

        // The table section index matches the product type.
        switch forIndexPath.section {
        case Product.ProductType.birthdays.rawValue - 1:
            product = products[forIndexPath.row]
        case Product.ProductType.weddings.rawValue - 1:
            product = products[forIndexPath.row + quantityForBirthdays]
        case Product.ProductType.funerals.rawValue - 1:
            let quantityForWeddings = quantity(forType: Product.ProductType.weddings)
            product = products[forIndexPath.row + quantityForBirthdays + quantityForWeddings]
        default: break
        }
        
        return product
    }
    
    func setupDataSource() {
        products = [
            Product(title: Localization.ginger.localized(), yearIntroduced: 2007, introPrice: 49.98, type: .birthdays),
            Product(title: Localization.gladiolus.localized(), yearIntroduced: 2001, introPrice: 51.99, type: .birthdays),
            Product(title: Localization.orchid.localized(), yearIntroduced: 2007, introPrice: 16.99, type: .birthdays),
            Product(title: Localization.geranium.localized(), yearIntroduced: 2006, introPrice: 16.99, type: .birthdays),
            Product(title: Localization.daisy.localized(), yearIntroduced: 2006, introPrice: 16.99, type: .birthdays),
            
            Product(title: Localization.tulip.localized(), yearIntroduced: 1997, introPrice: 39.99, type: .weddings),
            Product(title: Localization.carnationRed.localized(), yearIntroduced: 2006, introPrice: 23.99, type: .weddings),
            Product(title: Localization.carnationWhite.localized(), yearIntroduced: 2007, introPrice: 23.99, type: .weddings),
            Product(title: Localization.sunFlower.localized(), yearIntroduced: 2008, introPrice: 25.00, type: .weddings),
            Product(title: Localization.gardenia.localized(), yearIntroduced: 2006, introPrice: 25.00, type: .weddings),
            Product(title: Localization.daffodil.localized(), yearIntroduced: 2008, introPrice: 24.99, type: .weddings),
            
            Product(title: Localization.poinsettiaRed.localized(), yearIntroduced: 2010, introPrice: 31.99, type: .funerals),
            Product(title: Localization.poinsettiaPink.localized(), yearIntroduced: 2011, introPrice: 31.99, type: .funerals),
            Product(title: Localization.redRose.localized(), yearIntroduced: 2010, introPrice: 24.99, type: .funerals),
            Product(title: Localization.whiteRose.localized(), yearIntroduced: 2012, introPrice: 24.99, type: .funerals)
        ]
    }
    
}

