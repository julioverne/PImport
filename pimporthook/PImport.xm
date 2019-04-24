#import "PImport.h"

const char* pimport_running_uploader = "/private/var/mobile/Media/DCIM/pimport_running_uploader";

static BOOL allowServerWhenExit;

static NSMutableArray* allStringURLReceived()
{
	static NSMutableArray* allURLS;
	if(!allURLS) {
		allURLS = [@[] mutableCopy];
	}
	return allURLS;
}
static BOOL needShowAgainPImportURL;


#define NSLog(...)




@implementation ViewMapController
@synthesize objMapView, annotation, latitude_UserLocation, longitude_UserLocation, userDidChangedLocation;
- (void)viewDidLoad
{
    [super viewDidLoad];
	
	objMapView = [[MKMapView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:objMapView];
	
	UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(foundTap:)]; 
	tapRecognizer.numberOfTapsRequired = 1;
	tapRecognizer.numberOfTouchesRequired = 1;
	[objMapView addGestureRecognizer:tapRecognizer];
	
	annotation = [[MKPointAnnotation alloc] init];
	[objMapView addAnnotation:annotation];
}
- (void)updateCordinate
{
	CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(latitude_UserLocation, longitude_UserLocation);
	MKCoordinateSpan span = MKCoordinateSpanMake(0.1, 0.1);
	MKCoordinateRegion region = {coord, span};
	[annotation setCoordinate:coord];
	[objMapView setRegion:region];
}
- (void)foundTap:(UITapGestureRecognizer *)recognizer
{
	CGPoint point = [recognizer locationInView:objMapView];
	CLLocationCoordinate2D tapPoint = [objMapView convertPoint:point toCoordinateFromView:self.view];
	latitude_UserLocation = tapPoint.latitude;
	longitude_UserLocation = tapPoint.longitude;
	annotation.coordinate = tapPoint;
	userDidChangedLocation = YES;
}
@end


static NSURL* fixURLRemoteOrLocalWithPath(NSString* inPath)
{
	NSString* inPathRet = inPath;
	if([inPathRet hasPrefix:@"file:"]) {
		if(NSString* try1 = [[NSURL URLWithString:inPathRet] path]) {
			inPathRet = try1;
		}
		if([inPathRet hasPrefix:@"file:"]) {
			inPathRet = [inPathRet substringFromIndex:5];
		}
	}
	while([inPathRet hasPrefix:@"//"]) {
		inPathRet = [inPathRet substringFromIndex:1];
	}
	NSURL* retURL = [inPathRet hasPrefix:@"/"]?[NSURL fileURLWithPath:inPathRet]:[NSURL URLWithString:inPathRet];
	//NSLog(@"*** fixURLRemoteOrLocalWithPath:\n inPath: %@ \n inPathRet: %@ \n retURL: %@", inPath, inPathRet, retURL);
	return retURL;
}

@implementation Base64
#define ArrayLength(x) (sizeof(x)/sizeof(*(x)))
static unsigned char encodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static unsigned char decodingTable[128];
+ (void) initialize
{
	if (self == [Base64 class]) {
		memset(decodingTable, 0, ArrayLength(decodingTable));
		for (NSInteger i = 0; i < ArrayLength(encodingTable); i++) {
			decodingTable[encodingTable[i]] = i;
		}
	}
}
+ (NSData*) decode:(const char*) string length:(NSInteger) inputLength
{
	if ((string == NULL) || (inputLength % 4 != 0)) {
		return nil;
	}
	while (inputLength > 0 && string[inputLength - 1] == '=') {
		inputLength--;
	}
	NSInteger outputLength = inputLength * 3 / 4;
	NSMutableData* data = [NSMutableData dataWithLength:outputLength];
	uint8_t* output = (uint8_t*)data.mutableBytes;
	NSInteger inputPoint = 0;
	NSInteger outputPoint = 0;
	while (inputPoint < inputLength) {
		unsigned char i0 = string[inputPoint++];
		unsigned char i1 = string[inputPoint++];
		unsigned char i2 = inputPoint < inputLength ? string[inputPoint++] : 'A'; /* 'A' will decode to \0 */
		unsigned char i3 = inputPoint < inputLength ? string[inputPoint++] : 'A';
		output[outputPoint++] = (decodingTable[i0] << 2) | (decodingTable[i1] >> 4);
		if (outputPoint < outputLength) {
			output[outputPoint++] = ((decodingTable[i1] & 0xf) << 4) | (decodingTable[i2] >> 2);
		}
		if (outputPoint < outputLength) {
			output[outputPoint++] = ((decodingTable[i2] & 0x3) << 6) | decodingTable[i3];
		}
	}
	return data;
}
+ (NSData*) decode:(NSString*) string
{
	return [self decode:[string cStringUsingEncoding:NSASCIIStringEncoding] length:string.length];
}
@end


%hook UINavigationBar
- (void)_accessibility_navigationBarContentsDidChange
{
	%orig;
	[self fixButtonPImport];
}
%new
- (void)fixButtonPImport
{
	BOOL hasButton = NO;
	for(UIBarButtonItem* now in self.topItem.rightBarButtonItems) {
		if (now.tag == 4) {
			hasButton = YES;
			break;
		}
	}
	if (!hasButton) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callLaunchPImportFromURL) name:@"com.julioverne.pimport/callback" object:nil];
		__strong UIBarButtonItem* kBTLaunch = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(launchPImport)];
		kBTLaunch.tag = 4;
		__autoreleasing NSMutableArray* BT = [self.topItem.rightBarButtonItems?:[NSArray array] mutableCopy];
		[BT addObject:kBTLaunch];
		self.topItem.rightBarButtonItems = [BT copy];
	}
}
-(void)layoutSubviews
{
	%orig;
	[self fixButtonPImport];
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		[self fixButtonPImport];
	});
}
%new
-(void)callLaunchPImportFromURL
{
	if(needShowAgainPImportURL) {
		needShowAgainPImportURL = NO;
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(launchPImportFromURL) object:nil];
		[self performSelector:@selector(launchPImportFromURL) withObject:nil afterDelay:1.5];
	}
}
%new
- (void)launchPImportFromURL
{
	[self launchPImport];
}
%new
- (void)launchPImport
{	
	@try {
		//NSURL* FILEURL = [NSURL fileURLWithPath:@"/Applications/MobileSlideShow.app/AppIcon60x60@2x.png"];
		//[[PImportEditTagListController alloc] initWithURL:FILEURL]
		UIViewController *vc = nil;
		id <UIApplicationDelegate> appDele = [UIApplication sharedApplication].delegate;
		if([appDele respondsToSelector:@selector(rootViewController)]) {
			vc = [(UIWindow*)appDele rootViewController];
		}
		if(!vc) {
			vc = [appDele window].rootViewController;
		}
		if([vc respondsToSelector:@selector(presentedViewController)]) {
			if(UIViewController* presentVC = vc.presentedViewController) {
				vc = presentVC;
			}
		}
		[[PImportImportWithController shared] checkForURLReceived];
		static UINavigationController* nacV = [[UINavigationController alloc] initWithRootViewController:[PImportImportWithController shared]];
		//nacV.navigationBar.barTintColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
		[vc presentViewController:nacV animated:YES completion:nil];
		
	} @catch (NSException * e) {
	}
}
%end


@implementation PImportImportWithController
+ (id)shared
{
	static __strong PImportImportWithController* PImportImportWithControllerC;
	if(!PImportImportWithControllerC) {
		PImportImportWithControllerC = [[[self class] alloc] initWithStyle:UITableViewStyleGrouped];
	}
	return PImportImportWithControllerC;
}
- (void)setRightButton
{
	__strong UIBarButtonItem* kBTClose = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(closePImport)];
	kBTClose.tag = 4;
	self.navigationItem.rightBarButtonItems = @[kBTClose];	
}
- (void)closePImport
{
	[self dismissViewControllerAnimated:YES completion:nil];
}
- (void)viewDidLoad
{
	[super viewDidLoad];
	[self setRightButton];
	self.title = @"Import From...";
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static __strong NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
	cell.textLabel.text = nil;
	cell.detailTextLabel.text = nil;
	cell.imageView.image = nil;
	cell.accessoryType = UITableViewCellAccessoryNone;
	
	cell.textLabel.enabled = YES;
	cell.detailTextLabel.enabled = YES;
	cell.userInteractionEnabled = YES;
	
	static __strong UIImage* kIconFolder = nil;
	if(!kIconFolder) {
		NSData* dataImage = [[NSData alloc] initWithBytes:FOLDER_ICON_DATA length:FOLDER_ICON_SIZE];
		kIconFolder = [[[UIImage alloc] initWithData:dataImage] copy];
		if(kIconFolder && [kIconFolder respondsToSelector:@selector(imageWithRenderingMode:)]) {
			kIconFolder = [[kIconFolder imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] copy];
		}
	}
	static __strong UIImage* kIconLogo = nil;
	if(!kIconLogo) {
		NSData* dataImage = [[NSData alloc] initWithBytes:LOGO_ICON_DATA length:LOGO_ICON_SIZE];
		kIconLogo = [[[UIImage alloc] initWithData:dataImage] copy];
		if(kIconLogo && [kIconLogo respondsToSelector:@selector(imageWithRenderingMode:)]) {
			kIconLogo = [[kIconLogo imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] copy];
		}
	}
	if(indexPath.section == 0) {
		cell.textLabel.text = @"Root Filesystem";
		cell.detailTextLabel.text = @"Import Photos From Root Filesystem.";
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.imageView.image = kIconFolder;
		cell.userInteractionEnabled = NO;
		cell.textLabel.enabled = NO;
		cell.detailTextLabel.enabled = NO;
	} else if(indexPath.section == 1) {
		cell.textLabel.text = @"URL or File Path";
		cell.detailTextLabel.text = @"Input Direct Photo URL Or File Path";
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.imageView.image = kIconFolder;
	} else if(indexPath.section == 2) {
		cell.textLabel.text = @"Wi-Fi Sharing";
		cell.detailTextLabel.text = @"Import Photos From Web Server.";
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.imageView.image = kIconLogo;
	} else if(indexPath.section == 3) {
		cell.textLabel.text = @"Dropbox";
		cell.detailTextLabel.text = @"Import Photos From Dropbox.";
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.imageView.image = kIconFolder;
		cell.userInteractionEnabled = NO;
		cell.textLabel.enabled = NO;
		cell.detailTextLabel.enabled = NO;
	}
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	
	if(indexPath.section == 0) {
		//
	} else if(indexPath.section == 1) {
		UIAlertView *alert = [[UIAlertView alloc]
			initWithTitle:@"Input Direct Media URL Or File Path"
			message:nil
			delegate:self
			cancelButtonTitle:[[NSBundle bundleWithPath:@"/System/Library/Frameworks/UIKit.framework"]?:[NSBundle mainBundle] localizedStringForKey:@"Cancel" value:@"Cancel" table:nil]
			otherButtonTitles:
            @"OK",
			nil];
		[alert setContext:@"importurl"];
		[alert setNumberOfRows:1];
		[alert addTextFieldWithValue:[UIPasteboard generalPasteboard].string?:@"" label:@""];
		UITextField *traitsF = [[alert textFieldAtIndex:0] textInputTraits];
		[traitsF setAutocapitalizationType:UITextAutocapitalizationTypeNone];
		[traitsF setAutocorrectionType:UITextAutocorrectionTypeNo];
		//[traitsF setKeyboardType:UIKeyboardTypeURL];
		[traitsF setReturnKeyType:UIReturnKeyNext];
		[alert show];
	} else if(indexPath.section == 2) {
		@try {
			[self.navigationController pushViewController:[PImportUploadController sharedInstance] animated:YES];
		} @catch (NSException * e) {
		}
	} else if(indexPath.section == 3) {
		@try {
			//[self.navigationController pushViewController:[[MImportDropboxController alloc] initWithStyle:UITableViewStyleGrouped] animated:YES];
		} @catch (NSException * e) {
		}
	}
}
- (void) alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)button
{
	@try {
		NSString *context([alert context]);
		if(context&&[context isEqualToString:@"importurl"]) {
			if(button == 1) {
				NSString *href = [[alert textFieldAtIndex:0] text];
				@try {
					[self.navigationController pushViewController:[[%c(PImportEditTagListController) alloc] initWithURL:fixURLRemoteOrLocalWithPath(href)] animated:YES];
				} @catch (NSException * e) {
				}
			}
		}
	} @catch (NSException * e) {
	}
	[alert dismissWithClickedButtonIndex:-1 animated:YES];
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	if(section == [self numberOfSectionsInTableView:tableView]-1) {
		return @"\n\nPImport © 2018 julioverne";
	}
	return [super tableView:tableView titleForFooterInSection:section];
}
- (void)checkForURLReceived
{
	if(allStringURLReceived().count) {
		NSString* stringURLImport = [allStringURLReceived()[0] copy];
		[allStringURLReceived() removeObject:stringURLImport];
		PImportEditTagListController* NVBFromURL = [[%c(PImportEditTagListController) alloc] initWithURL:[[NSURL URLWithString:stringURLImport] copy]];
		NVBFromURL.isFromURL = YES;
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			[self.navigationController pushViewController:NVBFromURL animated:YES];
			[self checkForURLReceived];
		});
	}
}
- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];	
	
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	__strong UIBarButtonItem* kBTClose = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(closePImport)];
	kBTClose.tag = 4;	
	if (self.navigationController.navigationBar.backItem == NULL) {
		self.navigationItem.leftBarButtonItem = kBTClose;
	}
	[self checkForURLReceived];
}
@end


static NSString * formatFileSizeFromBytes(long long fileSize)
{
    return [NSByteCountFormatter stringFromByteCount:fileSize countStyle:NSByteCountFormatterCountStyleFile];
}


@implementation PImportUploadController
+ (instancetype)sharedInstance
{
	static __strong PImportUploadController* _shared;
	if(!_shared) {
		_shared = [[[self class] alloc] initWithStyle:UITableViewStyleGrouped];
	}
	return _shared;
}

- (id)initWithStyle:(UITableViewStyle)style
{
	if(self = [super initWithStyle:style]) {
		
	}
	return self;
}
- (void)setRightButton
{
	__strong UIBarButtonItem* kBTClose = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(closePImport)];
	kBTClose.tag = 4;
	self.navigationItem.rightBarButtonItems = @[kBTClose];	
}
- (void)closePImport
{
	[self dismissViewControllerAnimated:YES completion:nil];
}
- (void)viewDidLoad
{
	[super viewDidLoad];
	[self setRightButton];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static __strong NSString* simpleTableIdentifier = @"PImport";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
	}
	cell.accessoryType = UITableViewCellAccessoryNone;
	[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	cell.accessoryView = nil;
	cell.imageView.image = nil;
	cell.textLabel.text = nil;
	cell.detailTextLabel.text = nil;
	cell.textLabel.textColor = [UIColor blackColor];
	
	if ([indexPath section] == 0) {
		if (indexPath.row == 0) {
			cell.textLabel.text = @"Enabled";
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
			cell.accessoryView = switchView;
			[switchView setOn:(access(pimport_running_uploader, F_OK) == 0) animated:NO];
			[switchView addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
		}
	}
	
	return cell;
}
- (void)switchChanged:(id)sender
{
    UISwitch* switchControl = sender;
	if(switchControl.on) {
		close(open(pimport_running_uploader, O_CREAT));
	} else {
		unlink(pimport_running_uploader);
	}
	[self.tableView reloadData];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0) {
		return 1;
	}
	return 0;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (NSString *)getIPAddress
{
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    success = getifaddrs(&interfaces);
    if (success == 0) {
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    freeifaddrs(interfaces);
    return address;
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	if (section == 0) {
		if(access(pimport_running_uploader, F_OK) == 0) {
			return [NSString stringWithFormat:@"Wi-Fi Sharing running at: http://%@:%@/", [self getIPAddress], @(PORT_SERVER_SHARE)];
		}
	}
	return nil;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.title = @"Wi-Fi Sharing";
	[self.tableView reloadData];
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	__strong UIBarButtonItem* kBTClose = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(closePImport)];
	kBTClose.tag = 4;	
	if (self.navigationController.navigationBar.backItem == NULL) {
		self.navigationItem.leftBarButtonItem = kBTClose;
	}
}
- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}
@end


@implementation PImportEditTagListController
@synthesize sourceURL, container, isFromURL, datePickerSelDateTimeOriginal, datePickerSelDateTimeDigitized, imageview, viewMapController;

- (void)importFileNow
{
	[self.view endEditing:YES];
	if(container) {
		if(self.viewMapController.userDidChangedLocation) {
			[container addLocation:self.viewMapController.latitude_UserLocation latitude:self.viewMapController.longitude_UserLocation];
		}
		[container savePhotoWithCurrentExif];
	}
	[self.navigationController popViewControllerAnimated:NO];
	[[PImportImportWithController shared] closePImport];
}
- (NSString*)extSt
{
	return [[[[self.sourceURL path] lastPathComponent]?:@"" pathExtension]?:@"" lowercaseString];
}
- (id)fileLocation
{
	return [NSString stringWithFormat:@"%@ (%@)", [self.sourceURL isFileURL]?@"Local":@"External", [self.sourceURL scheme]];
}
- (id)fileDimensionFormat
{
	if(container) {
		return [NSString stringWithFormat:@"%@x%@", container.imageMetadata[@"PixelWidth"], container.imageMetadata[@"PixelHeight"]];
	}
	return @"";
}

- (id)fileName
{
	return [[self.sourceURL path] lastPathComponent]?:@"";
}
- (id)fileSizeFormat
{
	int filesize = 0;
	if(container!=nil&&[container imageData]!=nil) {
		filesize = [container imageData].length;
	}
	return formatFileSizeFromBytes(filesize);
}
- (void)dateChanged:(UIDatePicker*)datePicker
{
	if(container) {
		if(datePicker==datePickerSelDateTimeOriginal) {
			[container addCreationDate:datePickerSelDateTimeOriginal.date forExifKey:(__bridge NSString *)kCGImagePropertyExifDateTimeOriginal];
		} else if(datePicker==datePickerSelDateTimeDigitized) {
			[container addCreationDate:datePickerSelDateTimeDigitized.date forExifKey:(__bridge NSString *)kCGImagePropertyExifDateTimeDigitized];
		}
	}
}
- (id)initWithURL:(NSURL*)inURL
{
	self = [super init];
	if(self) {
		self.sourceURL = nil;
		self.container = nil;
		
		self.viewMapController = [[ViewMapController alloc] init];
		
		datePickerSelDateTimeOriginal = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
		[datePickerSelDateTimeOriginal addTarget:self action:@selector(dateChanged:) forControlEvents:UIControlEventValueChanged];
		datePickerSelDateTimeOriginal.datePickerMode = UIDatePickerModeDateAndTime;
		datePickerSelDateTimeOriginal.tag = 468;
		[datePickerSelDateTimeOriginal setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
		
		datePickerSelDateTimeDigitized = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
		[datePickerSelDateTimeDigitized addTarget:self action:@selector(dateChanged:) forControlEvents:UIControlEventValueChanged];
		datePickerSelDateTimeDigitized.datePickerMode = UIDatePickerModeDateAndTime;
		datePickerSelDateTimeDigitized.tag = 469;
		[datePickerSelDateTimeDigitized setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
		
		imageview = [[UIImageView alloc] init];
		imageview.tag = 468;
		imageview.contentMode = UIViewContentModeScaleAspectFit;
		[imageview setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
		
		self.sourceURL = inURL;
		__block UIProgressHUD* hud = [[UIProgressHUD alloc] init];
		[hud setText:@"Loading Tags..."];
		[hud showInView:self.view];
		[self.view setUserInteractionEnabled:NO];
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			
			NSData *image = [NSData dataWithContentsOfURL:self.sourceURL];
			
			dispatch_async(dispatch_get_main_queue(), ^(void) {
				if(image) {
					self.container = [[ExifContainerPImport alloc] initWithImage:image];
					datePickerSelDateTimeOriginal.date = [container getCreationDateForExifKey:(__bridge NSString *)kCGImagePropertyExifDateTimeOriginal]?:[NSDate date];
					datePickerSelDateTimeDigitized.date = [container getCreationDateForExifKey:(__bridge NSString *)kCGImagePropertyExifDateTimeOriginal]?:[NSDate date];
					imageview.image = [[UIImage alloc] initWithData:container.imageData];
					
					NSDictionary* ORIG_GPS_DIC = container.imageMetadata[(__bridge NSString*)kCGImagePropertyGPSDictionary];
					if(ORIG_GPS_DIC) {
						self.viewMapController.latitude_UserLocation = [ORIG_GPS_DIC[(__bridge NSString*)kCGImagePropertyGPSLatitude]?:@(0) floatValue];
						self.viewMapController.longitude_UserLocation = [ORIG_GPS_DIC[(__bridge NSString*)kCGImagePropertyGPSLongitude]?:@(0) floatValue];
					}
				}
				if(self.sourceURL && [self.sourceURL isFileURL]) {
					[[NSFileManager defaultManager] removeItemAtPath:self.sourceURL.path error:nil];
				}
				[hud hide];
				[self.view setUserInteractionEnabled:YES];
				[self reloadSpecifiers];
			});
		});
	}
	return self;
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	__strong UIBarButtonItem* kBTClose = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(closePImportEdit)];
	kBTClose.tag = 4;	
	if (self.navigationController.navigationBar.backItem == NULL) {
		self.navigationItem.leftBarButtonItem = kBTClose;
	}
}
- (void)closePImportEdit
{
	[self dismissViewControllerAnimated:YES completion:nil];
}
- (id)specifiers
{
	if (!_specifiers) {
		NSMutableArray* specifiers = [NSMutableArray array];
		PSSpecifier* spec;
		
		spec = [PSSpecifier preferenceSpecifierNamed:[[NSBundle bundleWithPath:@"/System/Library/Frameworks/UIKit.framework"]?:[NSBundle mainBundle] localizedStringForKey:@"Info" value:@"Info" table:nil]
		                                      target:self
											  set:Nil
											  get:Nil
                                              detail:Nil
											  cell:PSGroupCell
											  edit:Nil];
		[spec setProperty:[[NSBundle bundleWithPath:@"/System/Library/Frameworks/UIKit.framework"]?:[NSBundle mainBundle] localizedStringForKey:@"Info" value:@"Info" table:nil] forKey:@"label"];
		[specifiers addObject:spec];
		
		spec = [PSSpecifier preferenceSpecifierNamed:@"Image"
					      target:self
						 set:NULL
						 get:NULL
					      detail:Nil
						cell:PSTitleValueCell
						edit:Nil];
		[spec setProperty:@"Image" forKey:@"key"];
		[spec setProperty:@"" forKey:@"default"];
		[specifiers addObject:spec];
		
		spec = [PSSpecifier preferenceSpecifierNamed:[[NSBundle bundleWithPath:@"/System/Library/Frameworks/UIKit.framework"]?:[NSBundle mainBundle] localizedStringForKey:@"Name" value:@"Name" table:nil]
					      target:self
						 set:NULL
						 get:@selector(fileName)
					      detail:Nil
						cell:PSTitleValueCell
						edit:Nil];
		[specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"Size"
					      target:self
						 set:NULL
						 get:@selector(fileSizeFormat)
					      detail:Nil
						cell:PSTitleValueCell
						edit:Nil];
		[specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"Dimension"
					      target:self
						 set:NULL
						 get:@selector(fileDimensionFormat)
					      detail:Nil
						cell:PSTitleValueCell
						edit:Nil];
		[specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"Color Model"
                                              target:self
											  set:NULL
											  get:@selector(readRootValue:)
                                              detail:Nil
											  cell:PSTitleValueCell
											  edit:Nil];
		[spec setProperty:@"ColorModel" forKey:@"key"];
        [specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"Profile Name"
                                              target:self
											  set:NULL
											  get:@selector(readRootValue:)
                                              detail:Nil
											  cell:PSTitleValueCell
											  edit:Nil];
		[spec setProperty:@"ProfileName" forKey:@"key"];
        [specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"Source"
					      target:self
						 set:NULL
						 get:@selector(fileLocation)
					      detail:Nil
						cell:PSTitleValueCell
						edit:Nil];
		[specifiers addObject:spec];
		
		spec = [PSSpecifier preferenceSpecifierNamed:@"Date Time Original"
		                                      target:self
											  set:Nil
											  get:Nil
                                              detail:Nil
											  cell:PSGroupCell
											  edit:Nil];
		[spec setProperty:@"Date Time Original" forKey:@"label"];
		[specifiers addObject:spec];
		
		spec = [PSSpecifier preferenceSpecifierNamed:@"DateTimeOriginal"
					      target:self
						 set:NULL
						 get:NULL
					      detail:Nil
						cell:PSTitleValueCell
						edit:Nil];
		[spec setProperty:@"Image" forKey:@"key"];
		[spec setProperty:@"" forKey:@"default"];
		[specifiers addObject:spec];
		
		spec = [PSSpecifier preferenceSpecifierNamed:@"Date Time Digitized"
		                                      target:self
											  set:Nil
											  get:Nil
                                              detail:Nil
											  cell:PSGroupCell
											  edit:Nil];
		[spec setProperty:@"Date Time Digitized" forKey:@"label"];
		[specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"DateTimeDigitized"
					      target:self
						 set:NULL
						 get:NULL
					      detail:Nil
						cell:PSTitleValueCell
						edit:Nil];
		[spec setProperty:@"Image" forKey:@"key"];
		[spec setProperty:@"" forKey:@"default"];
		[specifiers addObject:spec];
		
		spec = [PSSpecifier preferenceSpecifierNamed:@"Location"
		                                      target:self
											  set:Nil
											  get:Nil
                                              detail:Nil
											  cell:PSGroupCell
											  edit:Nil];
		[spec setProperty:@"Location" forKey:@"label"];
		[specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"Set Location"
                                              target:self
                                                 set:NULL
                                                 get:NULL
                                              detail:Nil
                                                cell:PSLinkCell
                                                edit:Nil];
		spec->action = @selector(loadMap);
		[specifiers addObject:spec];
		
		
		spec = [PSSpecifier preferenceSpecifierNamed:@"Exif Tags"
		                                      target:self
											  set:Nil
											  get:Nil
                                              detail:Nil
											  cell:PSGroupCell
											  edit:Nil];
		[spec setProperty:@"Exif Tags" forKey:@"label"];
		[specifiers addObject:spec];
		
		spec = [PSSpecifier preferenceSpecifierNamed:@"Lens Make"
                                              target:self
											  set:@selector(setExifValue:specifier:)
											  get:@selector(readExifValue:)
                                              detail:Nil
											  cell:PSEditTextCell
											  edit:Nil];
		[spec setProperty:@"LensMake" forKey:@"key"];
        [specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"Lens Model"
                                              target:self
											  set:@selector(setExifValue:specifier:)
											  get:@selector(readExifValue:)
                                              detail:Nil
											  cell:PSEditTextCell
											  edit:Nil];
		[spec setProperty:@"LensModel" forKey:@"key"];
        [specifiers addObject:spec];
		
		spec = [PSSpecifier preferenceSpecifierNamed:@"Maker Note"
                                              target:self
											  set:@selector(setExifValue:specifier:)
											  get:@selector(readExifValue:)
                                              detail:Nil
											  cell:PSEditTextCell
											  edit:Nil];
		[spec setProperty:(__bridge NSString*)kCGImagePropertyExifMakerNote forKey:@"key"];
        [specifiers addObject:spec];
		
		spec = [PSSpecifier preferenceSpecifierNamed:@"User Comment"
                                              target:self
											  set:@selector(setExifValue:specifier:)
											  get:@selector(readExifValue:)
                                              detail:Nil
											  cell:PSEditTextCell
											  edit:Nil];
		[spec setProperty:(__bridge NSString*)kCGImagePropertyExifUserComment forKey:@"key"];
        [specifiers addObject:spec];
		
		spec = [PSSpecifier preferenceSpecifierNamed:@"Camera Owner Name"
                                              target:self
											  set:@selector(setExifValue:specifier:)
											  get:@selector(readExifValue:)
                                              detail:Nil
											  cell:PSEditTextCell
											  edit:Nil];
		[spec setProperty:(__bridge NSString*)kCGImagePropertyExifCameraOwnerName forKey:@"key"];
        [specifiers addObject:spec];
		
		
		
		spec = [PSSpecifier preferenceSpecifierNamed:@"Tiff Tags"
		                                      target:self
											  set:Nil
											  get:Nil
                                              detail:Nil
											  cell:PSGroupCell
											  edit:Nil];
		[spec setProperty:@"Tiff Tags" forKey:@"label"];
		[specifiers addObject:spec];
		
		spec = [PSSpecifier preferenceSpecifierNamed:@"Make"
                                              target:self
											  set:@selector(setTiffValue:specifier:)
											  get:@selector(readTiffValue:)
                                              detail:Nil
											  cell:PSEditTextCell
											  edit:Nil];
		[spec setProperty:@"Make" forKey:@"key"];
        [specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"Model"
                                              target:self
											  set:@selector(setTiffValue:specifier:)
											  get:@selector(readTiffValue:)
                                              detail:Nil
											  cell:PSEditTextCell
											  edit:Nil];
		[spec setProperty:@"Model" forKey:@"key"];
        [specifiers addObject:spec];
		spec = [PSSpecifier preferenceSpecifierNamed:@"Software"
                                              target:self
											  set:@selector(setTiffValue:specifier:)
											  get:@selector(readTiffValue:)
                                              detail:Nil
											  cell:PSEditTextCell
											  edit:Nil];
		[spec setProperty:@"Software" forKey:@"key"];
        [specifiers addObject:spec];
		
		spec = [PSSpecifier preferenceSpecifierNamed:@"Description"
                                              target:self
											  set:@selector(setTiffValue:specifier:)
											  get:@selector(readTiffValue:)
                                              detail:Nil
											  cell:PSEditTextCell
											  edit:Nil];
		[spec setProperty:(__bridge NSString*)kCGImagePropertyTIFFImageDescription forKey:@"key"];
        [specifiers addObject:spec];
		
		spec = [PSSpecifier emptyGroupSpecifier];
		[spec setProperty:[NSString stringWithFormat:@"Source:\n%@", self.sourceURL] forKey:@"footerText"];
		[specifiers addObject:spec];
		
		spec = [PSSpecifier emptyGroupSpecifier];
        [spec setProperty:@"PImport © 2018 julioverne" forKey:@"footerText"];
        [specifiers addObject:spec];
		_specifiers = [specifiers copy];
	}
	return _specifiers;
}
- (void)loadMap
{
	@try {
		[self.navigationController pushViewController:self.viewMapController animated:YES];
	} @catch (NSException * e) {
	}
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	if(cell.textLabel.text && [cell.textLabel.text isEqualToString:@"Artwork"]) {
		return YES;
	}
    return NO;
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if(editingStyle == UITableViewCellEditingStyleDelete) {
		
    }
}
- (void)setRightButton
{
	__strong UIBarButtonItem* kBTClose = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(closePImportEdit)];
	__strong UIBarButtonItem* kBTRight = [[UIBarButtonItem alloc] initWithTitle:[[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/PhotoLibrary.framework"]?:[NSBundle mainBundle] localizedStringForKey:@"IMPORT" value:@"Import" table:@"PhotoLibrary"] style:UIBarButtonItemStylePlain target:self action:@selector(importFileNow)];
	kBTRight.tag = 4;
	self.navigationItem.rightBarButtonItems = @[kBTClose, kBTRight];	
}
- (void)viewDidLoad
{
	[super viewDidLoad];
	self.title = [[NSBundle bundleWithPath:@"/System/Library/Frameworks/UIKit.framework"]?:[NSBundle mainBundle] localizedStringForKey:@"Edit" value:@"Edit" table:nil];
	[self setRightButton];
	__strong UIRefreshControl *refreshControl;
	if(!refreshControl) {
		refreshControl = [[UIRefreshControl alloc] init];
		[refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
		refreshControl.tag = 8654;
	}	
	if(UITableView* tableV = (UITableView *)object_getIvar(self, class_getInstanceVariable([self class], "_table"))) {
		if(UIView* rem = [tableV viewWithTag:8654]) {
			[rem removeFromSuperview];
		}
		[tableV addSubview:refreshControl];
	}
}
- (void)refresh:(UIRefreshControl *)refresh
{
	[self reloadSpecifiers];
	[refresh endRefreshing];
}
- (void)setRootValue:(id)value specifier:(PSSpecifier *)specifier
{
	if(container) {
		[container.imageMetadata setValue:value forKey:[specifier identifier]];
	}
}
- (id)readRootValue:(PSSpecifier*)specifier
{
	if(container) {
		return container.imageMetadata[[specifier identifier]];
	}
	return nil;
}
- (void)setExifValue:(id)value specifier:(PSSpecifier *)specifier
{
	if(container) {
		[container.exifDictionary setValue:value forKey:[specifier identifier]];
	}
}
- (id)readExifValue:(PSSpecifier*)specifier
{
	if(container) {
		return container.exifDictionary[[specifier identifier]];
	}
	return nil;
}
- (void)setTiffValue:(id)value specifier:(PSSpecifier *)specifier
{
	if(container) {
		[container.tiffDictionary setValue:value forKey:[specifier identifier]];
	}
}
- (id)readTiffValue:(PSSpecifier*)specifier
{
	if(container) {
		return container.tiffDictionary[[specifier identifier]];
	}
	return nil;
}
- (void)_returnKeyPressed:(id)arg1
{
	//[super _returnKeyPressed:arg1];
	[self.view endEditing:YES];
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section==0 && indexPath.row==0) {
		UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Image"];
		cell.textLabel.text = nil;
		cell.textLabel.textColor = [UIColor whiteColor];
		
		imageview.frame = cell.bounds;
		if(UIView* removeOld = [cell viewWithTag:468]) {
			[removeOld removeFromSuperview];
		}
		[cell addSubview:imageview];
		
		return cell;
	}
	
	if(indexPath.section==1 && indexPath.row==0) {
		UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DateTimeOriginal"];
		cell.textLabel.text = nil;
		cell.textLabel.textColor = [UIColor whiteColor];
		
		datePickerSelDateTimeOriginal.frame = cell.bounds;
		if(UIView* removeOld = [cell viewWithTag:468]) {
			[removeOld removeFromSuperview];
		}
		[cell addSubview:datePickerSelDateTimeOriginal];
		
		return cell;
	}
	
	if(indexPath.section==2 && indexPath.row==0) {
		UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DateTimeDigitized"];
		cell.textLabel.text = nil;
		cell.textLabel.textColor = [UIColor whiteColor];
		
		datePickerSelDateTimeDigitized.frame = cell.bounds;
		if(UIView* removeOld = [cell viewWithTag:469]) {
			[removeOld removeFromSuperview];
		}
		[cell addSubview:datePickerSelDateTimeDigitized];
		
		return cell;
	}
	
	
	
	return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}
- (double)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section==0 && indexPath.row==0) {
		return 150.0f;
	}
	if(indexPath.section==1 && indexPath.row==0) {
		return 100.0f;
	}
	if(indexPath.section==2 && indexPath.row==0) {
		return 100.0f;
	}
	return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}
@end

%hook NSURL
- (id)scheme
{
	id ret = %orig;
	if(ret) {
		@try{
		if([ret isEqualToString:@"photos"] && [[self lastPathComponent] isEqualToString:@"pimport"]) {
			if(NSString* query = [self query]) {
				NSMutableDictionary *queryStringDictionary = [[NSMutableDictionary alloc] init];
				NSArray *urlComponents = [query componentsSeparatedByString:@"&"];
				for(NSString *keyValuePair in urlComponents) {
					NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
					NSString *key = [[pairComponents firstObject] stringByRemovingPercentEncoding];
					NSString *value = [[pairComponents lastObject] stringByRemovingPercentEncoding];
					queryStringDictionary[key] = value;
				}
				if([queryStringDictionary objectForKey:@"path"] != nil) {
					NSURL* receivedURLPImport = fixURLRemoteOrLocalWithPath([queryStringDictionary objectForKey:@"path"]);
					if(![allStringURLReceived() containsObject:receivedURLPImport.absoluteString]) {
						needShowAgainPImportURL = YES;
						[allStringURLReceived() addObject:receivedURLPImport.absoluteString];
						//NSLog(@"***** DETECTEDRECEIVE URL: %@", receivedURLPImport);
						[[NSNotificationCenter defaultCenter] performSelector:@selector(postNotificationName:) withObject:@"com.julioverne.pimport/callback" afterDelay:0.5];
					}
				} else if(queryStringDictionary[@"pathBase"] != nil) {
					NSString* receivedURLPImportBase64 = queryStringDictionary[@"pathBase"];
					receivedURLPImportBase64 = [receivedURLPImportBase64 stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
					receivedURLPImportBase64 = [receivedURLPImportBase64 stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
					receivedURLPImportBase64 = [receivedURLPImportBase64 stringByReplacingOccurrencesOfString:@"." withString:@"="];
					NSURL* receivedURLPImport = [NSURL URLWithString:[[NSString alloc] initWithData:[Base64 decode:receivedURLPImportBase64] encoding:NSUTF8StringEncoding]];
					if(![allStringURLReceived() containsObject:receivedURLPImport.absoluteString]) {
						needShowAgainPImportURL = YES;
						[allStringURLReceived() addObject:receivedURLPImport.absoluteString];
						//NSLog(@"***** DETECTED RECEIVE URL: %@", receivedURLPImport);
						[[NSNotificationCenter defaultCenter] performSelector:@selector(postNotificationName:) withObject:@"com.julioverne.pimport/callback" afterDelay:0.5];
					}
				}
			}
			ret = @"https";
		}
		} @catch (NSException * e) {
		}
	}	
	return ret;
}
%end

__attribute__((constructor)) static void initialize_mimport()
{
	%init;
}

__attribute__((destructor)) static void finalize_mimport()
{
	@autoreleasepool {
		if(!allowServerWhenExit) {
			unlink(pimport_running_uploader);
		}
	}
}