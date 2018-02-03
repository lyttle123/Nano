//
//  proController.swift
//  redditwatch
//
//  Created by Will Bishop on 3/2/18.
//  Copyright © 2018 Will Bishop. All rights reserved.
//

import UIKit
import SwiftyStoreKit
import StoreKit

enum RegisteredPurchase: String {
	case proNinetyNine = "Pro"
	
}
var sharedSecret = "82aa45026f5b4a07b34d20e3df60b317"

class NetworkActivityIndicatorManager: NSObject {
	private static var loadingCount = 0
	
	class func networkOperationStarted(){
		if loadingCount == 0{
			UIApplication.shared.isNetworkActivityIndicatorVisible = true
		}
		loadingCount += 1
	}
	class func networkOperationFinished(){
		if loadingCount > 0{
			loadingCount -= 1
		}
		if loadingCount == 0{
			UIApplication.shared.isNetworkActivityIndicatorVisible = false
		}
		
	}
}

class proController: UIViewController {
	
	let bundleId = "com.willbishop.redditwatch"
	
	@IBOutlet weak var proNinetyNine: UIButton!
	var ProUnlock = RegisteredPurchase.proNinetyNine
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	@IBAction func proNinetyNine(_ sender: Any) {
		purchase(purchase: ProUnlock)
	}
	
	func getInfo(purchase: RegisteredPurchase){
		NetworkActivityIndicatorManager.networkOperationStarted()
		SwiftyStoreKit.retrieveProductsInfo([bundleId + "." + purchase.rawValue], completion: {
			result in
			NetworkActivityIndicatorManager.networkOperationFinished()
			self.showAlert(alert: self.alertForProductRetrievalInfo(result: result))
			
		})
	}
	
	func purchase(purchase: RegisteredPurchase){
		NetworkActivityIndicatorManager.networkOperationStarted()
		SwiftyStoreKit.purchaseProduct(bundleId + "." + purchase.rawValue, completion: {
			result in
			NetworkActivityIndicatorManager.networkOperationFinished()
			if case .success(let product) = result{
				if product.needsFinishTransaction{
					SwiftyStoreKit.finishTransaction(product.transaction)
				}
				self.showAlert(alert: self.alertForProductResult(result: result))
			}
			print(result)
		})
	}
	
	func restorePurchase(){
		SwiftyStoreKit.restorePurchases(atomically: true, completion: {
			result in
			NetworkActivityIndicatorManager.networkOperationFinished()
			for product in result.restoredPurchases{
				if product.needsFinishTransaction{
					SwiftyStoreKit.finishTransaction(product.transaction)
				}
				
			}
			self.showAlert(alert: self.alertForRestorePurchases(result: result))
		})
	}
	
	func verifyReceipt(){
		NetworkActivityIndicatorManager.networkOperationStarted()
		let appleValidator = AppleReceiptValidator(service: .sandbox, sharedSecret: sharedSecret)
		
		SwiftyStoreKit.verifyReceipt(using: appleValidator, completion: {
			result in
			NetworkActivityIndicatorManager.networkOperationFinished()
			self.showAlert(alert: self.alertForVerifyReceipt(result: result))
			
		})
	}
	
	func verifyPurchase(product: RegisteredPurchase){
		NetworkActivityIndicatorManager.networkOperationStarted()
		let appleValidator = AppleReceiptValidator(service: .sandbox, sharedSecret: sharedSecret)
		
		SwiftyStoreKit.verifyReceipt(using: appleValidator, completion: {
			result in
			NetworkActivityIndicatorManager.networkOperationFinished()
			switch result{
			case .error(let error):
				print(error.localizedDescription)
			case .success(let receipt):
				let myProductId = self.bundleId + "." + product.rawValue
				if product == .proNinetyNine{
					let purchaseResult = SwiftyStoreKit.verifyPurchase(productId: myProductId, inReceipt: receipt)
					self.showAlert(alert: self.alertForVerifyPurchase(result: purchaseResult))
				}
			}
		})
	}
	
	
}

extension proController{
	func alertWithTitle(title: String, message: String) -> UIAlertController{
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
		return alert
	}
	func showAlert(alert: UIAlertController){
		guard let _ = self.presentedViewController else{
			self.present(alert, animated: true, completion: nil)
			return
		}
	}
	
	func alertForProductRetrievalInfo(result: RetrieveResults) -> UIAlertController{
		if let product = result.retrievedProducts.first{
			let myPriceString = product.localizedPrice
			return alertWithTitle(title: product.localizedPrice!, message: "\(product.localizedDescription) - \(myPriceString)")
		} else if let invalidProductId = result.invalidProductIDs.first{
			return alertWithTitle(title: "Could not retrieve product info", message: "Invalid product identifier: \(invalidProductId)")
		}
		else{
			let errorString = result.error?.localizedDescription ?? "Unknown Error. Please contact developer"
			return alertWithTitle(title: "Could not retrieve product info", message: errorString)
			
		}
	}
	
	func alertForProductResult(result: PurchaseResult) -> UIAlertController{
		switch result{
		case .success(let product):
			print("Purchase Successful: \(product.productId)")
			return alertWithTitle(title: "Thank you", message: "Thank you for supporting indie development")
		case .error(let error):
			print("Purchase Failed: \(error)")
			switch error.code {
			case .unknown: return alertWithTitle(title: "Purchase Failed", message: "Unknown error. Please contact support")
			case .clientInvalid: return alertWithTitle(title: "Purchase Failed", message: "Not allowed to make the payment")
			case .paymentCancelled: break
			case .paymentInvalid: return alertWithTitle(title: "Purchase Failed", message: "The purchase identifier was invalid")
			case .paymentNotAllowed: return alertWithTitle(title: "Purchase Failed", message: "The device is not allowed to make the payment")
			case .storeProductNotAvailable: return alertWithTitle(title: "Purchase Failed", message: "The product is not available in the current storefront")
			case .cloudServicePermissionDenied: return alertWithTitle(title: "Purchase Failed", message: "Access to cloud service information is not allowed")
			case .cloudServiceNetworkConnectionFailed: return alertWithTitle(title: "Purchase Failed", message: "Could not connect to the network")
			case .cloudServiceRevoked: return alertWithTitle(title: "Purchase Failed", message: "Cloud Service Revoked")
			}
		}
		return UIAlertController()
		
	}
	
	func alertForRestorePurchases(result: RestoreResults) -> UIAlertController{
		if result.restoreFailedPurchases.count > 0{
			print("Restore Failed: \(result.restoreFailedPurchases)")
			return alertWithTitle(title: "Restore Failed", message: "Unkown Error. Please contact developer")
		} else if result.restoredPurchases.count > 0{
			return alertWithTitle(title: "Purchases Restored!", message: "Hazzah!")
		} else{
			return alertWithTitle(title: "Waiiit a seccond", message: "You haven't bought anything")
		}
	}
	
	func alertForVerifyReceipt(result: VerifyReceiptResult) -> UIAlertController{
		switch result{
		case .success(let receipt):
			return alertWithTitle(title: "Receipt Verified", message: "Receipt Verified Remotely")
		case .error(let error):
			return alertWithTitle(title: "Verify Failed", message: error.localizedDescription)
		}
	}
	
	func alertForVerifySubscription(result: VerifySubscriptionResult) -> UIAlertController{
		switch result{
		case .purchased(let expiryDate):
			return alertWithTitle(title: "Purchases!", message: "Product is valid until: \(expiryDate.expiryDate)")
		case .notPurchased:
			return alertWithTitle(title: "Product is not purchased", message: "This product has never been purchased")
		case .expired(let expiryDate):
			return alertWithTitle(title: "Product expired", message: "Product expired since: \(expiryDate.expiryDate)")
		}
	}
	func alertForVerifyPurchase(result: VerifyPurchaseResult) -> UIAlertController{
		switch result{
		case .notPurchased:
			return alertWithTitle(title: "Product Not Purchaed", message: "Product was not purchased")
		case .purchased(let item):
			return alertWithTitle(title: "Purchased", message: "Thank you for purchasing")
		}
	}
}
