#import "PImportSB.h"

#define NSLog(...)

#define PLIST_PATH_Settings "/var/mobile/Library/Preferences/com.julioverne.pimport.plist"

#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

#import "../libPImportWebServer/PImportWebServer.h"
#import "../libPImportWebServer/PImportWebServerFileResponse.h"
#import "../libPImportWebServer/PImportWebServerDataRequest.h"
#import "../libPImportWebServer/PImportWebServerDataResponse.h"
#import "../libPImportWebServer/PImportWebUploader.h"

#import "../PImportServerDefines.h"

static BOOL SilentImport;

static __strong PImportWebServer* _webServer;
static __strong PImportWebUploader* _webServerUploader;

const char* pimport_running_uploader = "/private/var/mobile/Media/DCIM/pimport_running_uploader";

#define MIMPORT_CACHE_URL "/private/var/mobile/Media/DCIM/pImportCache.plist"

static void disableServerAndCleanCache(BOOL cleanCache)
{
	unlink(pimport_running_uploader);
	if(cleanCache) {
		system([NSString stringWithFormat:@"rm -rf %s", MIMPORT_CACHE_URL].UTF8String);
	}
}

static NSString* encodeBase64WithData(NSData* theData)
{
	@autoreleasepool {
		const uint8_t* input = (const uint8_t*)[theData bytes];
		NSInteger length = [theData length];
		static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
		NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
		uint8_t* output = (uint8_t*)data.mutableBytes;
		NSInteger i;
		for (i=0; i < length; i += 3) {
			NSInteger value = 0;
			NSInteger j;
			for (j = i; j < (i + 3); j++) {
				value <<= 8;
				if (j < length) {
					value |= (0xFF & input[j]);
				}
			}
			NSInteger theIndex = (i / 3) * 4;
			output[theIndex + 0] =			  table[(value >> 18) & 0x3F];
			output[theIndex + 1] =			  table[(value >> 12) & 0x3F];
			output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
			output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
		}
		return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	}
}

static int isFileZipAtPath(NSString* path)
{
	@autoreleasepool {
		if(path) {
			if(NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:path]) {
				NSData *data = [fh readDataOfLength:4];
				if (data && [data length] == 4) {
					const char *bytes = (const char *)[data bytes];
					if(bytes[0] == 'P' && bytes[1] == 'K' && bytes[2] == 3 && bytes[3] == 4) {
						return 1;
					}
					if(bytes[0] == 'R' && bytes[1] == 'a' && bytes[2] == 'r' && bytes[3] == '!') {
						return 2;
					}
				}
			}
		}
		return 0;
	}
}

@interface SpringBoard : NSObject
- (void)pimportAllocServer;
@end

@interface PImportServer : NSObject <PImportWebUploaderDelegate>
+(PImportServer*)shared;
- (void)resetTimeOutCheck;
@end
@implementation PImportServer
+(PImportServer*)shared
{
	static PImportServer* shard = nil;
	if(!shard) {
		shard = [[[self class] alloc] init];
	}
	return shard;
}
- (void)resetTimeOutCheck
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pimportTimeoutServer) object:nil];
	[self performSelector:@selector(pimportTimeoutServer) withObject:nil afterDelay:SERVER_TIMEOUT_SECONDS];
}
- (void)pimportTimeoutServer
{
	disableServerAndCleanCache(YES);
}

- (void)webUploader:(PImportWebUploader*)uploader didUploadFileAtPath:(NSString*)path
{
	if(SilentImport) {
		ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
		UIImage* imageToSave = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL fileURLWithPath:path]]];
		[library writeImageToSavedPhotosAlbum:imageToSave.CGImage metadata:nil completionBlock:^(NSURL *newURL, NSError *error) {
			if (error) {
				NSLog( @"Error writing image with metadata to Photo Library: %@", error );
			} else {
				NSLog( @"Wrote image %@",newURL);
			}
			[[NSFileManager defaultManager] removeItemAtPath:path error:nil];
		}];
		return;
	}
	NSString* base64StringURL = nil;
	NSURL* url = [NSURL fileURLWithPath:path];
	if(url && [(id)url isKindOfClass:[NSURL class]]) {
		base64StringURL = encodeBase64WithData([[(NSURL*)url absoluteString] dataUsingEncoding:NSUTF8StringEncoding]);
		base64StringURL = [base64StringURL stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
		base64StringURL = [base64StringURL stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
		base64StringURL = [base64StringURL stringByReplacingOccurrencesOfString:@"=" withString:@"."];
		if(base64StringURL) {
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"photos:///pimport?pathBase=%@", base64StringURL]]];
		}
	}
}
@end

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application
{
    %orig;
	disableServerAndCleanCache(NO);
	[NSTimer scheduledTimerWithTimeInterval:kMaxIdleTimeSeconds target:self selector:@selector(pimportChecker) userInfo:nil repeats:YES];
}
%new
- (void)pimportAllocServer
{
	if(_webServer) {
		return;
	}
	
	if(%c(PHPhotoLibrary)!=nil) {
		PHAuthorizationStatus status = (PHAuthorizationStatus)[%c(PHPhotoLibrary) authorizationStatus];
		if(status == PHAuthorizationStatusAuthorized) {
			
		} else {
			[%c(PHPhotoLibrary) requestAuthorization:^(PHAuthorizationStatus status) {
				if (status != PHAuthorizationStatusAuthorized) {
					//
				}
			}];
		}
	}
	
	dlopen("/usr/lib/libPImportWebServer.dylib", RTLD_LAZY | RTLD_GLOBAL);
	_webServer = [[objc_getClass("PImportWebServer") alloc] init];
	
	
	
	[_webServer addDefaultHandlerForMethod:@"GET" requestClass:objc_getClass("PImportWebServerRequest") processBlock:^PImportWebServerResponse *(PImportWebServerRequest* request) {
		
		[[PImportServer shared] resetTimeOutCheck];
		
		NSURL* url = request.URL;
		NSDictionary* cachedUrls = [[NSDictionary alloc] initWithContentsOfFile:@MIMPORT_CACHE_URL]?:@{};
		if(NSString * urlFromMD5St = cachedUrls[[[url lastPathComponent] stringByDeletingPathExtension]]) {
			if(NSURL* urlFromMD5 = [NSURL URLWithString:urlFromMD5St]) {
				if([urlFromMD5 isFileURL]) {
					NSString* fileR = [urlFromMD5 path];
					if(fileR && [[NSFileManager defaultManager] fileExistsAtPath:fileR]) {
						return [objc_getClass("PImportWebServerFileResponse") responseWithFile:fileR byteRange:request.byteRange];
					}
				} else {
					NSLog(@"*** REDIRECT REQUEST TO: %@", urlFromMD5);
					return [objc_getClass("PImportWebServerResponse") responseWithRedirect:urlFromMD5 permanent:NO];
				}
			}
		}
		return [objc_getClass("PImportWebServerDataResponse") responseWithData:[NSData data] contentType:@"data"];
	}];
	[_webServer addDefaultHandlerForMethod:@"POST" requestClass:objc_getClass("PImportWebServerRequest") processBlock:^PImportWebServerResponse *(PImportWebServerRequest* request) {
		
		[[PImportServer shared] resetTimeOutCheck];
		
		NSDictionary* piDictRet = [NSDictionary dictionary];
		NSURL* url = request.URL;
		NSDictionary* cachedUrls = [[NSDictionary alloc] initWithContentsOfFile:@MIMPORT_CACHE_URL]?:@{};
		if(NSString * urlFromMD5St = cachedUrls[[[url lastPathComponent] stringByDeletingPathExtension]]) {
			if(NSURL* urlFromMD5 = [NSURL URLWithString:urlFromMD5St]) {
				if([urlFromMD5 isFileURL]) {
					NSString*filePath = [urlFromMD5 path];
					NSMutableDictionary* mutDic = [piDictRet mutableCopy];
					mutDic[@"isFileZip"] = (isFileZipAtPath(filePath)>0)?@YES:@NO;
					mutDic[@"fileSize"] = @([[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:NULL]?:@{} fileSize]);
					piDictRet = [mutDic copy];
				}
			}
		}
		return [objc_getClass("PImportWebServerDataResponse") responseWithJSONObject:piDictRet];
	}];
	[_webServer addDefaultHandlerForMethod:@"FILEMAN" requestClass:objc_getClass("PImportWebServerDataRequest") processBlock:^PImportWebServerResponse *(PImportWebServerRequest* request) {
		
		[[PImportServer shared] resetTimeOutCheck];
		
		BOOL returnResp = NO;
		NSString* errorInfo = [NSString string];
		
		int operationType = 0;
		NSString* path1 = nil;
		NSString* path2 = nil;
		NSString* pathDest = [NSString string];
		
		if(NSData* bodyData = ((PImportWebServerDataRequest*)request).data) {
			NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:bodyData];
			if(unarchiver) {
				operationType = [[unarchiver decodeObjectForKey:@"operationType"]?:@(0) intValue];
				path1 = [unarchiver decodeObjectForKey:@"path1"];
				path2 = [unarchiver decodeObjectForKey:@"path2"];
			}
		}
		
		if(operationType == fileOperationDelete) {
			NSError* error = nil;
			returnResp = [[NSFileManager defaultManager] removeItemAtPath:path1 error:&error];
			if(error != nil) {
				errorInfo = [error description];
			}
		} else if(operationType == fileOperationMove) {
			NSError* error = nil;
			returnResp = [[NSFileManager defaultManager] moveItemAtPath:path1 toPath:path2 error:&error];
			if(error != nil) {
				errorInfo = [error description];
			}
		} else if(operationType == fileOperationExtract) {
			int typeFileZip = isFileZipAtPath(path1);
			pathDest = [[path1 stringByDeletingPathExtension] copy];
			int countPath = 0;
			while(path1 && [[NSFileManager defaultManager] fileExistsAtPath:pathDest]) {
				countPath++;
				pathDest = [[path1 stringByDeletingPathExtension] stringByAppendingFormat:@" (%d)", countPath];
			}
			system([NSString stringWithFormat:@"mkdir -p \"%@\"", pathDest].UTF8String);
			int respCmd = system([NSString stringWithFormat:@"cd \"%@\";%@ \"%@\"", pathDest, typeFileZip==1?@"unzip -q":@"unrar x -o+ -ow -tsmca", path1].UTF8String);
			returnResp = !respCmd;
		} else if(operationType == fileOperationCopy) {
			NSError* error = nil;
			returnResp = [[NSFileManager defaultManager] copyItemAtPath:path1 toPath:path2 error:&error];
			if(error != nil) {
				errorInfo = [error description];
			}
		}
		
		NSLog(@"operationType: %d \n returnResp: %@ \n path1: %@ \n path2: %@ \n errorInfo: %@", operationType, @(returnResp), path1, path2, errorInfo);
		
		return [objc_getClass("PImportWebServerDataResponse") responseWithJSONObject:@{@"result":@(returnResp), @"error":errorInfo, @"pathDest": pathDest,}];
	}];
}
%new
- (void)pimportChecker
{
	@autoreleasepool {
		if(access(pimport_running_uploader, F_OK) == 0) {
			NSLog(@"**** FILE OK %@", _webServerUploader);
			if(!_webServerUploader) {
				[self pimportAllocServer];
				_webServerUploader = [[objc_getClass("PImportWebUploader") alloc] initWithUploadDirectory:@"//tmp/"];
				_webServerUploader.delegate = [PImportServer shared];
				_webServerUploader.allowHiddenItems = YES;
			}
			if(_webServerUploader != nil && !_webServerUploader.running) {
				NSLog(@"**** startWithPort");
				[_webServerUploader startWithPort:PORT_SERVER_SHARE bonjourName:nil];
			}			
		} else {
			NSLog(@"**** FILE 404 %@", _webServerUploader);
			if(_webServerUploader != nil && _webServerUploader.running) {
				[_webServerUploader stop];
			}
		}		
	}
}
%end


static void settingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	@autoreleasepool {
		NSDictionary *TweakPrefs = [[[NSDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings]?:[NSDictionary dictionary] copy];
		SilentImport = (BOOL)[[TweakPrefs objectForKey:@"SilentImport"]?:@NO boolValue];
	}
}


__attribute__((constructor)) static void initialize_pimportCenter()
{
	disableServerAndCleanCache(NO);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, settingsChanged, CFSTR("com.julioverne.pimport/Settings"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	settingsChanged(NULL, NULL, NULL, NULL, NULL);
	
}


