//
//  ActivityManager.swift
//  NetNewsWire-iOS
//
//  Created by Maurice Parker on 8/23/19.
//  Copyright © 2019 Ranchero Software. All rights reserved.
//

import Foundation
import CoreSpotlight
import CoreServices
import Account
import Articles
import Intents

class ActivityManager {
	
	public static var shared = ActivityManager()
	
	private var selectingActivity: NSUserActivity? = nil
	private var readingActivity: NSUserActivity? = nil

	func selectingToday() {
		let title = NSLocalizedString("See articles for Today", comment: "Today")
		selectingActivity = makeSelectingActivity(type: ActivityType.selectToday, title: title, identifier: "smartfeed.today")
		selectingActivity!.becomeCurrent()
	}
	
	func selectingAllUnread() {
		let title = NSLocalizedString("See articles in All Unread", comment: "All Unread")
		selectingActivity = makeSelectingActivity(type: ActivityType.selectAllUnread, title: title, identifier: "smartfeed.allUnread")
		selectingActivity!.becomeCurrent()
	}
	
	func selectingStarred() {
		let title = NSLocalizedString("See articles in Starred", comment: "Starred")
		selectingActivity = makeSelectingActivity(type: ActivityType.selectStarred, title: title, identifier: "smartfeed.starred")
		selectingActivity!.becomeCurrent()
	}
	
	func selectingFolder(_ folder: Folder) {
		let localizedText = NSLocalizedString("See articles in  “%@”", comment: "See articles in Folder")
		let title = NSString.localizedStringWithFormat(localizedText as NSString, folder.nameForDisplay) as String
		selectingActivity = makeSelectingActivity(type: ActivityType.selectFolder, title: title, identifier: "folder.\(folder.nameForDisplay)")
	 
		selectingActivity!.userInfo = [
			ActivityID.accountID.rawValue: folder.account?.accountID ?? "",
			ActivityID.accountName.rawValue: folder.account?.name ?? "",
			ActivityID.folderName.rawValue: folder.nameForDisplay
		]

		selectingActivity!.becomeCurrent()
	}
	
	func selectingFeed(_ feed: Feed) {
		let localizedText = NSLocalizedString("See articles in  “%@”", comment: "See articles in Feed")
		let title = NSString.localizedStringWithFormat(localizedText as NSString, feed.nameForDisplay) as String
		selectingActivity = makeSelectingActivity(type: ActivityType.selectFeed, title: title, identifier: feed.url)
		
		selectingActivity!.userInfo = [
			ActivityID.accountID.rawValue: feed.account?.accountID ?? "",
			ActivityID.accountName.rawValue: feed.account?.name ?? "",
			ActivityID.feedID.rawValue: feed.feedID
		]

		selectingActivity!.becomeCurrent()
	}
	
	func reading(_ article: Article?) {
		readingActivity?.invalidate()
		readingActivity = nil
		guard let article = article else { return }
		readingActivity = makeReadArticleActivity(article)
		readingActivity?.becomeCurrent()
	}
	
}

// MARK: Private

private extension ActivityManager {
	
	func makeSelectingActivity(type: ActivityType, title: String, identifier: String) -> NSUserActivity {
		let activity = NSUserActivity(activityType: type.rawValue)
		activity.title = title
		activity.suggestedInvocationPhrase = title
		activity.keywords = Set(makeKeywords(title))
		activity.isEligibleForPrediction = true
		activity.isEligibleForSearch = true
		activity.persistentIdentifier = identifier
		return activity
	}
	
	func makeReadArticleActivity(_ article: Article) -> NSUserActivity {
		let activity = NSUserActivity(activityType: ActivityType.readArticle.rawValue)

		activity.title = article.title
		
		let feedNameKeywords = makeKeywords(article.feed?.nameForDisplay)
		let articleTitleKeywords = makeKeywords(article.title)
		let keywords = feedNameKeywords + articleTitleKeywords
		activity.keywords = Set(keywords)
		
		activity.userInfo = [
			ActivityID.accountID.rawValue: article.accountID,
			ActivityID.accountName.rawValue: article.account?.name ?? "",
			ActivityID.feedID.rawValue: article.feedID,
			ActivityID.articleID.rawValue: article.articleID
		]
		activity.isEligibleForSearch = true
		activity.isEligibleForPrediction = false
		activity.isEligibleForHandoff = true
		
		// CoreSpotlight
		let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeCompositeContent as String)
		attributeSet.title = article.title
		attributeSet.contentDescription = article.summary
		attributeSet.keywords = keywords
		attributeSet.relatedUniqueIdentifier = article.url
		
		if let image = article.avatarImage() {
			attributeSet.thumbnailData = image.pngData()
		}
		
		activity.contentAttributeSet = attributeSet
		
		return activity
	}
	
	func makeKeywords(_ value: String?) -> [String] {
		return value?.components(separatedBy: " ").filter { $0.count > 2 } ?? []
	}
	
}
