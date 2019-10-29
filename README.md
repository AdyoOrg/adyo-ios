![logo](https://i.imgur.com/wyiLPdE.png)



# Adyo iOS SDK

The Adyo iOS SDK makes it easy to integrate Adyo ads into your iOS app. We provide a pre-built UI element to easily serve ads out of the box. We also expose our APIs to provide you with more control on the serving experience.
<br/>

## Requirements

* iOS 9 or later
* XCode 9 or later

## Installation

Installation can be done manually by building and copying the framework into your project or automatically via CocoaPods.

### CocoaPods

1. Add the following to your Podfile: `pod 'Adyo', '~> 1.6.3'`
2. Run `pod install` and open the resulting Xcode workspace.

## Usage

### Includes

Simply import Adyo to get started:

```objective-c
@import Adyo; // If using framework

// or

#import "Adyo.h"
```

### Create an AYZoneView

The Adyo iOS provides you with an `AYZoneView` that handles requesting of ads, ad presentation and automatic refreshing. An `AYZoneView` can be constructed either programmatically or via the interface builder.

#### Method 1: Interface Builder

An `AYZoneView` can be added to a storyboard or xib file by using a normal `UIView` object which uses a custom class of `AYZoneView`. Remember to set the width and height constraints of the view to the size of your zone.

#### Method 2: Programatically

Creating an `AYZoneView` programatically is as simple as instantiating a normal `UIView`:

```objective-c
@import Adyo;

AYZoneView *zoneView = [[AYZoneView alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];

// .. Configuration omitted

[self.view addSubview:zoneView];
```

### Configuration

In order for the `AYZoneView` to request placements (ads), an `AYPlacementRequestParams` object is required:

```objective-c
// Multiple constructors are available
AYPlacementRequestParams *params = [[AYPlacementRequestParams alloc] initWithNetworkId:1 zoneId:1 userId:@"user234-11" keywords:@[@"keyword1", @"keyword2", @"keyword3"]];

// or without constructor

AYPlacementRequestParams *params = [AYPlacementRequestParams alloc] init];
params.networkId = 1;
params.zoneId = 1;
params.userId = @"user234-11";
params.keywords = @["keyword1", @"keyword2", @"keyword3"];
```

The following attributes are available:

| Parameter   | Required/Optional | Description                              |
| ----------- | ----------------- | ---------------------------------------- |
| `networkId` | **Required**      | Your Adyo network ID which has been provided to you. |
| `zoneId`    | **Required**      | The ID of the zone you want to request a placement for. |
| `userId`    | *Optional*        | A unique identifier for a user. Used for frequency capping. If no `userId` is provided, the SDK automatically uses the `ASIdentifierManager` [(more info)](https://developer.apple.com/documentation/adsupport/asidentifiermanager) to request an identifier. If the user has opted for limited ad tracking, we simply create a unique identifier for each ad request. |
| `keywords`  | *Optional*        | An array of keywords used for keyword targeting. |
| `width`     | *Optional*        | Manual width override. Explained below.  |
| `height`    | *Optional*        | Manual height override. Explained below. |
| `custom`    | *Optional*        | NSDictionary of custom properties that can be used later when querying using the Adyo Analytics API. Values can only be string, number or boolean. |


### Requesting a Placement

To instruct the `AYZoneView` to request a placement (ad), we simply call the `requestPlacement:` method which takes an `AYPlacementRequestParams` object as an argument:

```
[_zoneView requestPlacement:params];
```

Once the placement is requested, the `AYZoneView` will automatically display the ad.

**Note:** The `AYZoneView` will automatically track clicks and impressions for you. For manual tracking, please see below.


### Banner Events

Using the `AYZoneViewDelegate`, you can listen to specific events. To register for events:

```objective-c
// Before requesting a placement
_zoneView.delegate = self;
```

The following event methods are available:

**Successful Request**

```objective-c
- (void)zoneView:(AYZoneView *)zoneView didReceivePlacement:(BOOL)found placement:(Placement *)placement {
	
	// If the request was successful but there were no placements found then 'found' will be false and 'placement' will be nil
}
```

**Unsuccessful Request**

```objective-c
- (void)zoneView:(AYZoneView *)zoneView didFailToReceivePlacement:(NSError *)error {
	
	// The banner view request failed (normally due to connectivity issues)
}
```

## Manual Ad Requests

If you would like to have more control on how ads are displayed within in your app, you may use the SDK to manually request a placement:

```objective-c
@import Adyo;

[Adyo requestPlacement:params success:^(BOOL found, Placement *placement) {

	// Here you can use the placement details to create your own custom UI for the ad.
  
} failure:^(NSError *error) {    
	// Error normally due to connectivity issues
}];
```

### Placements

`Placement` objects contain the following attributes:

| Attribute                   | Type           | Description                              |
| --------------------------- | -------------- | ---------------------------------------- |
| **impressionUrl**           | NSString*      | Pixel URL used to record impressions.    |
| **clickUrl**                | NSString*      | Destination URL to navigate a user to when tapping on an ad. **Can be nil.** |
| **creativeType**            | NSString*      | The type of creative for this placement. Can either be `rich-media` or `image`. |
| **creativeUrl**             | NSString*      | URL to the creative. `rich-media` URLs point to an `index.html` and image types point to an image of either `png`, `gif`, or `jpg` . |
| **refreshAfter**            | NSTimeInterval | The amount of seconds until the next ad must be requested. |
| **thirdPartyImpressionUrl** | NSString*      | Third party impression URL. **Can be nil.** |


### Manual Impressions

To manually record an impression you can call the `recordImpression` method on any `Placement` object:

```objective-c
[placement recordImpression:^{

	// Optional success block if request succeeded
  
} failure:^(NSError *adyoError, NSError *thirdPartyError) {    
	// Optional failure block. If either the Adyo or third party impression URL fails, we will end up here. Either one of the errors can be nil if one succeeded and the other didn't.
}];
```

**Note**: If a third party impression URL exists for the placement, it will also be recorded.

**Note 2**: The Adyo analytics API automatically detects duplicate impression requests so you don't have to worry if you are calling the `recordImpression` method more than once (e.g When the third party impression URL request has failed and you would like to try again).

### Automatic Size Detection & Overriding Width and Height

All zones within Adyo can have specified a  `width` and `height`. The dimensions of the zone are used to choose the best sized creative when requesting a placement. This is why it is important to always create `AYZoneView` objects with the same size of the zone.

If for some reason you need to request a placement of a different size, you can set the `width` and `height`in the `AYPlacementRequestParams` object before executing the placement request.

If you are using an `AYZoneView` with layout constraints which will affect its height and width dynamically (such as stretching to size of the screen), you can simply set `determineSize` on the `AYZoneView` to `true`. At the moment of the request, the current size of the `AYZoneView` will be used in the request.

#### Using AYZoneView

```objective-c
// .. omitted creation of params

_zoneView.determineSize = YES; // Width and height will now be sent when the request is made

[_zoneView requestPlacement:params];
```

#### Manual Request

```objective-c
AYPlacementRequestParams *params = [AYPlacementRequestParams alloc] init];
params.networkId = 1;
params.zoneId = 1;

// Manually override width and height of the zone
params.width = 150;
params.height = 150;

[_zoneView requestPlacement:params];
```

## App Transport Security

Adyo's delivery API is compatible with App Transport Security [(more info)](https://developer.apple.com/library/content/releasenotes/General/WhatsNewIniOS/Articles/iOS9.html).

## Sample Project

An example project is included within the repo which provides a showcase of the different functionalities of the SDK. The `networkId` and `zoneId` values within the sample app are working and can be used for testing and demo purposes.

The project also provides a testing tool for you to input custom parameters to test-drive your own ads.

## Feedback

For any feedback, please contact us at: devops@unitx.co.za or create an issue. You are also more than welcome to send a pull request for any changes or bug fixes.

## Changelog

* v1.0.0 - Initial Release
