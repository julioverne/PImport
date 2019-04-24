
#if !__has_feature(objc_arc)

#endif

#import <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <SystemConfiguration/SystemConfiguration.h>
#endif

#import "PImportWebUploader.h"

#import "PImportWebServerDataRequest.h"
#import "PImportWebServerMultiPartFormRequest.h"
#import "PImportWebServerURLEncodedFormRequest.h"

#import "PImportWebServerDataResponse.h"
#import "PImportWebServerErrorResponse.h"
#import "PImportWebServerFileResponse.h"



#import <Photos/Photos.h>

@interface PImportWebUploader () {
@private
  NSString* _uploadDirectory;
  NSArray* _allowedExtensions;
  BOOL _allowHidden;
  NSString* _title;
  NSString* _header;
  NSString* _prologue;
  NSString* _epilogue;
  NSString* _footer;
}
@end

@interface PHAsset ()
@property (nonatomic, readonly) NSString *filename;

@end

@implementation PImportWebUploader (Methods)

// Must match implementation in PImportWebDAVServer
- (BOOL)_checkSandboxedPath:(NSString*)path {
  return [[path stringByStandardizingPath] hasPrefix:_uploadDirectory];
}

- (BOOL)_checkFileExtension:(NSString*)fileName {
  if (_allowedExtensions && ![_allowedExtensions containsObject:[[fileName pathExtension] lowercaseString]]) {
    return NO;
  }
  return YES;
}

- (NSString*) _uniquePathForPath:(NSString*)path {
  if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
    NSString* directory = [path stringByDeletingLastPathComponent];
    NSString* file = [path lastPathComponent];
    NSString* base = [file stringByDeletingPathExtension];
    NSString* extension = [file pathExtension];
    int retries = 0;
    do {
      if (extension.length) {
        path = [directory stringByAppendingPathComponent:[[base stringByAppendingFormat:@" (%i)", ++retries] stringByAppendingPathExtension:extension]];
      } else {
        path = [directory stringByAppendingPathComponent:[base stringByAppendingFormat:@" (%i)", ++retries]];
      }
    } while ([[NSFileManager defaultManager] fileExistsAtPath:path]);
  }
  return path;
}

- (PImportWebServerResponse*)listDirectory:(PImportWebServerRequest*)request
{
	NSString* relativePath = [[request query] objectForKey:@"path"];
	
	NSString* lastComp = [relativePath lastPathComponent]?:@"";
	
	NSString* lastCompEx = [lastComp pathExtension]?:@"";
	
	BOOL getAlbums = ((lastComp.length < 2) && lastCompEx.length == 0);
	BOOL getPhotosAlbum = ((lastComp.length > 1) && lastCompEx.length == 0);
	
	NSMutableArray* array = [NSMutableArray array];
	
	
	
	PHFetchResult *results = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
	PHFetchResult *resultsAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
	
	if(getAlbums) {
		for (int x = 0; x < results.count; x ++) {
			PHAssetCollection* albumn = results[x];
			if([PHAsset fetchAssetsInAssetCollection:albumn options:nil].count) {
			[array addObject:@{
				@"path": [[relativePath stringByAppendingPathComponent:albumn.localizedTitle] stringByAppendingString:@"/"],
				@"filename": albumn.localizedTitle,
				@"directory": @YES,
				@"readOnly": @YES,
			}];
			}
		}
		for (int x = 0; x < resultsAlbums.count; x ++) {
			PHAssetCollection* albumn = resultsAlbums[x];
			if([PHAsset fetchAssetsInAssetCollection:albumn options:nil].count) {
			[array addObject:@{
				@"path": [[relativePath stringByAppendingPathComponent:albumn.localizedTitle] stringByAppendingString:@"/"],
				@"filename": albumn.localizedTitle,
				@"directory": @YES,
				@"readOnly": @YES,
			}];
			}
		}
	} else if(getPhotosAlbum) {
		for (int x = 0; x < results.count; x ++) {
			PHAssetCollection* albumn = results[x];
			if([albumn.localizedTitle isEqualToString:lastComp]) {
				PHFetchResult* collectionResult = [PHAsset fetchAssetsInAssetCollection:albumn options:nil];
				for (int x = 0; x < collectionResult.count; x ++) {
					PHAsset * assetNow = collectionResult[x];
					[array addObject:@{
						@"path": [relativePath stringByAppendingPathComponent:[assetNow filename]],
						@"filename": [assetNow filename],
					}];
				}
			}
		}
		for (int x = 0; x < resultsAlbums.count; x ++) {
			PHAssetCollection* albumn = resultsAlbums[x];
			if([albumn.localizedTitle isEqualToString:lastComp]) {
				PHFetchResult* collectionResult = [PHAsset fetchAssetsInAssetCollection:albumn options:nil];
				for (int x = 0; x < collectionResult.count; x ++) {
					PHAsset * assetNow = collectionResult[x];
					[array addObject:@{
						@"path": [relativePath stringByAppendingPathComponent:[assetNow filename]],
						@"filename": [assetNow filename],
					}];
				}
			}
		}
	}
	
	array = (NSMutableArray*)[[array reverseObjectEnumerator] allObjects];
	
	[array insertObject:@{@"path": [relativePath stringByAppendingPathComponent:@"/"], @"contentSort": @"sortByDateDesc"} atIndex:0];
	
	return [PImportWebServerDataResponse responseWithJSONObject:array];
}

- (PImportWebServerResponse*)downloadFile:(PImportWebServerRequest*)request
{
	NSString* relativePath = [[[request query] objectForKey:@"path"] copy];
	
	NSString* fileRequest = [[relativePath lastPathComponent] copy];
	
	NSString* lastComp = [[[relativePath stringByDeletingLastPathComponent] lastPathComponent] copy];
	
	PHFetchResult *results = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
	PHFetchResult *resultsAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
	
	PHAsset * assetGet = nil;
	
	for(int x = 0; x < results.count; x ++) {
		PHAssetCollection* albumn = results[x];
		if([albumn.localizedTitle isEqualToString:lastComp]) {
			PHFetchResult* collectionResult = [PHAsset fetchAssetsInAssetCollection:albumn options:nil];
			for (int x = 0; x < collectionResult.count; x ++) {
				PHAsset * assetNow = collectionResult[x];
				if([[assetNow filename] isEqualToString:fileRequest]) {
					assetGet = assetNow;
					break;
				}
			}
		}
	}
	if(!assetGet) {
		for (int x = 0; x < resultsAlbums.count; x ++) {
			PHAssetCollection* albumn = resultsAlbums[x];
			if([albumn.localizedTitle isEqualToString:lastComp]) {
				PHFetchResult* collectionResult = [PHAsset fetchAssetsInAssetCollection:albumn options:nil];
				for (int x = 0; x < collectionResult.count; x ++) {
					PHAsset * assetNow = collectionResult[x];
					if([[assetNow filename] isEqualToString:fileRequest]) {
						assetGet = assetNow;
						break;
					}
				}
			}
		}
	}
	__block NSString* absolutePath;
	absolutePath = nil;
	
	PHImageRequestOptions *options = [PHImageRequestOptions new];
	options.synchronous = YES;
	options.version = PHImageRequestOptionsVersionOriginal;
	options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
	options.resizeMode = PHImageRequestOptionsResizeModeExact;
	options.networkAccessAllowed = YES;
	__block BOOL waitDown;
	waitDown = YES;
	[[PHImageManager defaultManager] requestImageForAsset:assetGet targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage *resultImage, NSDictionary *info) {
		NSURL *filePath = [info valueForKeyPath:@"PHImageFileURLKey"];
		if(filePath) {
			absolutePath = filePath.path;
		}
		waitDown = NO;
	}];
	while(waitDown) {
		sleep(1/2);
	}
	if ([self.delegate respondsToSelector:@selector(webUploader:didDownloadFileAtPath:  )]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.delegate webUploader:self didDownloadFileAtPath:absolutePath];
		});
	}
	
	return [PImportWebServerFileResponse responseWithFile:absolutePath isAttachment:YES];
}

- (PImportWebServerResponse*)downloadViewFile:(PImportWebServerRequest*)request
{
	NSString* relativePath = [[[request query] objectForKey:@"path"] copy];
	
	NSString* fileRequest = [[relativePath lastPathComponent] copy];
	
	NSString* lastComp = [[[relativePath stringByDeletingLastPathComponent] lastPathComponent] copy];
	
	PHFetchResult *results = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
	PHFetchResult *resultsAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
	
	PHAsset * assetGet = nil;
	
	for(int x = 0; x < results.count; x ++) {
		PHAssetCollection* albumn = results[x];
		if([albumn.localizedTitle isEqualToString:lastComp]) {
			PHFetchResult* collectionResult = [PHAsset fetchAssetsInAssetCollection:albumn options:nil];
			for (int x = 0; x < collectionResult.count; x ++) {
				PHAsset * assetNow = collectionResult[x];
				if([[assetNow filename] isEqualToString:fileRequest]) {
					assetGet = assetNow;
					break;
				}
			}
		}
	}
	if(!assetGet) {
		for (int x = 0; x < resultsAlbums.count; x ++) {
			PHAssetCollection* albumn = resultsAlbums[x];
			if([albumn.localizedTitle isEqualToString:lastComp]) {
				PHFetchResult* collectionResult = [PHAsset fetchAssetsInAssetCollection:albumn options:nil];
				for (int x = 0; x < collectionResult.count; x ++) {
					PHAsset * assetNow = collectionResult[x];
					if([[assetNow filename] isEqualToString:fileRequest]) {
						assetGet = assetNow;
						break;
					}
				}
			}
		}
	}
	__block NSString* absolutePath;
	absolutePath = nil;
	PHImageManager *manager = [PHImageManager defaultManager];
	PHImageRequestOptions *options = [PHImageRequestOptions new];
	options.synchronous = YES;
	options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
	options.resizeMode = PHImageRequestOptionsResizeModeNone;
	options.networkAccessAllowed = YES;
	__block BOOL waitDown;
	waitDown = YES;
	[manager requestImageForAsset:assetGet targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage *resultImage, NSDictionary *info) {
		NSURL *filePath = [info valueForKeyPath:@"PHImageFileURLKey"];
		if(filePath) {
			absolutePath = filePath.path;
		}
		waitDown = NO;
	}];
	while(waitDown) {
		sleep(1/2);
	}
	if ([self.delegate respondsToSelector:@selector(webUploader:didDownloadFileAtPath:  )]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.delegate webUploader:self didDownloadFileAtPath:absolutePath];
		});
	}
	
	return [PImportWebServerFileResponse responseWithFile:absolutePath isAttachment:NO];
}

- (PImportWebServerResponse*)downloadThumbnailFile:(PImportWebServerRequest*)request
{
	NSString* relativePath = [[[request query] objectForKey:@"path"] copy];
	
	NSString* fileRequest = [[relativePath lastPathComponent] copy];
	
	NSString* lastComp = [[[relativePath stringByDeletingLastPathComponent] lastPathComponent] copy];
	
	PHFetchResult *results = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
	PHFetchResult *resultsAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
	
	PHAsset * assetGet = nil;
	
	for(int x = 0; x < results.count; x ++) {
		PHAssetCollection* albumn = results[x];
		if([albumn.localizedTitle isEqualToString:lastComp]) {
			PHFetchResult* collectionResult = [PHAsset fetchAssetsInAssetCollection:albumn options:nil];
			for (int x = 0; x < collectionResult.count; x ++) {
				PHAsset * assetNow = collectionResult[x];
				if([[assetNow filename] isEqualToString:fileRequest]) {
					assetGet = assetNow;
					break;
				}
			}
		}
	}
	if(!assetGet) {
		for (int x = 0; x < resultsAlbums.count; x ++) {
			PHAssetCollection* albumn = resultsAlbums[x];
			if([albumn.localizedTitle isEqualToString:lastComp]) {
				PHFetchResult* collectionResult = [PHAsset fetchAssetsInAssetCollection:albumn options:nil];
				for (int x = 0; x < collectionResult.count; x ++) {
					PHAsset * assetNow = collectionResult[x];
					if([[assetNow filename] isEqualToString:fileRequest]) {
						assetGet = assetNow;
						break;
					}
				}
			}
		}
	}
	__block NSString* absolutePath;
	absolutePath = nil;
	PHImageManager *manager = [PHImageManager defaultManager];
	PHImageRequestOptions *options = [PHImageRequestOptions new];
	options.synchronous = YES;
	options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
	options.resizeMode = PHImageRequestOptionsResizeModeNone;
	options.networkAccessAllowed = YES;
	__block BOOL waitDown;
	waitDown = YES;
	
	__block NSData* imageData;
	imageData = nil;
	[manager requestImageForAsset:assetGet targetSize:CGSizeMake(90,90) contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage *resultImage, NSDictionary *info) {
		imageData = UIImageJPEGRepresentation (resultImage, 2.0);
		waitDown = NO;
	}];
	while(waitDown) {
		sleep(1/2);
	}
	if ([self.delegate respondsToSelector:@selector(webUploader:didDownloadFileAtPath:  )]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.delegate webUploader:self didDownloadFileAtPath:absolutePath];
		});
	}
	return [PImportWebServerDataResponse responseWithData:imageData contentType:@"image/jpeg"];
}

- (PImportWebServerResponse*)uploadFile:(PImportWebServerMultiPartFormRequest*)request {
  NSRange range = [[request.headers objectForKey:@"Accept"] rangeOfString:@"application/json" options:NSCaseInsensitiveSearch];
  NSString* contentType = (range.location != NSNotFound ? @"application/json" : @"text/plain; charset=utf-8");  // Required when using iFrame transport (see https://github.com/blueimp/jQuery-File-Upload/wiki/Setup)
  
  PImportWebServerMultiPartFile* file = [request firstFileForControlName:@"files[]"];
  if ((!_allowHidden && [file.fileName hasPrefix:@"."]) || ![self _checkFileExtension:file.fileName]) {
    return [PImportWebServerErrorResponse responseWithClientError:kPImportWebServerHTTPStatusCode_Forbidden message:@"Uploaded file name \"%@\" is not allowed", file.fileName];
  }
  NSString* relativePath = [[request firstArgumentForControlName:@"path"] string];
  NSString* absolutePath = [self _uniquePathForPath:[_uploadDirectory stringByAppendingPathComponent:file.fileName]];
  if (![self _checkSandboxedPath:absolutePath]) {
    return [PImportWebServerErrorResponse responseWithClientError:kPImportWebServerHTTPStatusCode_NotFound message:@"\"%@\" does not exist", relativePath];
  }
  
  if (![self shouldUploadFileAtPath:absolutePath withTemporaryFile:file.temporaryPath]) {
    return [PImportWebServerErrorResponse responseWithClientError:kPImportWebServerHTTPStatusCode_Forbidden message:@"Uploading file \"%@\" to \"%@\" is not permitted", file.fileName, relativePath];
  }
  
  NSError* error = nil;
  if (![[NSFileManager defaultManager] moveItemAtPath:file.temporaryPath toPath:absolutePath error:&error]) {
    return [PImportWebServerErrorResponse responseWithServerError:kPImportWebServerHTTPStatusCode_InternalServerError underlyingError:error message:@"Failed moving uploaded file to \"%@\"", relativePath];
  }
  
  if ([self.delegate respondsToSelector:@selector(webUploader:didUploadFileAtPath:)]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.delegate webUploader:self didUploadFileAtPath:absolutePath];
    });
  }
  return [PImportWebServerDataResponse responseWithJSONObject:@{} contentType:contentType];
}

- (PImportWebServerResponse*)moveItem:(PImportWebServerURLEncodedFormRequest*)request {
  NSString* oldRelativePath = [request.arguments objectForKey:@"oldPath"];
  NSString* oldAbsolutePath = [_uploadDirectory stringByAppendingPathComponent:oldRelativePath];
  BOOL isDirectory = NO;
  if (![self _checkSandboxedPath:oldAbsolutePath] || ![[NSFileManager defaultManager] fileExistsAtPath:oldAbsolutePath isDirectory:&isDirectory]) {
    return [PImportWebServerErrorResponse responseWithClientError:kPImportWebServerHTTPStatusCode_NotFound message:@"\"%@\" does not exist", oldRelativePath];
  }
  
  NSString* newRelativePath = [request.arguments objectForKey:@"newPath"];
  NSString* newAbsolutePath = [self _uniquePathForPath:[_uploadDirectory stringByAppendingPathComponent:newRelativePath]];
  if (![self _checkSandboxedPath:newAbsolutePath]) {
    return [PImportWebServerErrorResponse responseWithClientError:kPImportWebServerHTTPStatusCode_NotFound message:@"\"%@\" does not exist", newRelativePath];
  }
  
  NSString* itemName = [newAbsolutePath lastPathComponent];
  if ((!_allowHidden && [itemName hasPrefix:@"."]) || (!isDirectory && ![self _checkFileExtension:itemName])) {
    return [PImportWebServerErrorResponse responseWithClientError:kPImportWebServerHTTPStatusCode_Forbidden message:@"Moving to item name \"%@\" is not allowed", itemName];
  }
  
  if (![self shouldMoveItemFromPath:oldAbsolutePath toPath:newAbsolutePath]) {
    return [PImportWebServerErrorResponse responseWithClientError:kPImportWebServerHTTPStatusCode_Forbidden message:@"Moving \"%@\" to \"%@\" is not permitted", oldRelativePath, newRelativePath];
  }
  
  NSError* error = nil;
  if (![[NSFileManager defaultManager] moveItemAtPath:oldAbsolutePath toPath:newAbsolutePath error:&error]) {
    return [PImportWebServerErrorResponse responseWithServerError:kPImportWebServerHTTPStatusCode_InternalServerError underlyingError:error message:@"Failed moving \"%@\" to \"%@\"", oldRelativePath, newRelativePath];
  }
  
  if ([self.delegate respondsToSelector:@selector(webUploader:didMoveItemFromPath:toPath:)]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.delegate webUploader:self didMoveItemFromPath:oldAbsolutePath toPath:newAbsolutePath];
    });
  }
  return [PImportWebServerDataResponse responseWithJSONObject:@{}];
}

- (PImportWebServerResponse*)deleteItem:(PImportWebServerURLEncodedFormRequest*)request
{
	NSString* relativePath = [[[request query] objectForKey:@"path"] copy];
	
	NSString* fileRequest = [[relativePath lastPathComponent] copy];
	
	NSString* lastComp = [[[relativePath stringByDeletingLastPathComponent] lastPathComponent] copy];
	
	PHFetchResult *results = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
	PHFetchResult *resultsAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
	
	PHAsset * assetGet = nil;
	
	for(int x = 0; x < results.count; x ++) {
		PHAssetCollection* albumn = results[x];
		if([albumn.localizedTitle isEqualToString:lastComp]) {
			PHFetchResult* collectionResult = [PHAsset fetchAssetsInAssetCollection:albumn options:nil];
			for (int x = 0; x < collectionResult.count; x ++) {
				PHAsset * assetNow = collectionResult[x];
				if([[assetNow filename] isEqualToString:fileRequest]) {
					assetGet = assetNow;
					break;
				}
			}
		}
	}
	if(!assetGet) {
		for (int x = 0; x < resultsAlbums.count; x ++) {
			PHAssetCollection* albumn = resultsAlbums[x];
			if([albumn.localizedTitle isEqualToString:lastComp]) {
				PHFetchResult* collectionResult = [PHAsset fetchAssetsInAssetCollection:albumn options:nil];
				for (int x = 0; x < collectionResult.count; x ++) {
					PHAsset * assetNow = collectionResult[x];
					if([[assetNow filename] isEqualToString:fileRequest]) {
						assetGet = assetNow;
						break;
					}
				}
			}
		}
	}
	
	__block BOOL waitDown;
	waitDown = YES;
	
	[[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
		[PHAssetChangeRequest deleteAssets:[@[assetGet] mutableCopy]];
    } completionHandler:^(BOOL success, NSError *error) {
        waitDown = NO;
    }];
	
	while(waitDown) {
		sleep(1/2);
	}
	
	return [PImportWebServerDataResponse responseWithJSONObject:@{}];
}

- (PImportWebServerResponse*)createDirectory:(PImportWebServerURLEncodedFormRequest*)request {
  NSString* relativePath = [request.arguments objectForKey:@"path"];
  NSString* absolutePath = [self _uniquePathForPath:[_uploadDirectory stringByAppendingPathComponent:relativePath]];
  if (![self _checkSandboxedPath:absolutePath]) {
    return [PImportWebServerErrorResponse responseWithClientError:kPImportWebServerHTTPStatusCode_NotFound message:@"\"%@\" does not exist", relativePath];
  }
  
  NSString* directoryName = [absolutePath lastPathComponent];
  if (!_allowHidden && [directoryName hasPrefix:@"."]) {
    return [PImportWebServerErrorResponse responseWithClientError:kPImportWebServerHTTPStatusCode_Forbidden message:@"Creating directory name \"%@\" is not allowed", directoryName];
  }
  
  if (![self shouldCreateDirectoryAtPath:absolutePath]) {
    return [PImportWebServerErrorResponse responseWithClientError:kPImportWebServerHTTPStatusCode_Forbidden message:@"Creating directory \"%@\" is not permitted", relativePath];
  }
  
  NSError* error = nil;
  if (![[NSFileManager defaultManager] createDirectoryAtPath:absolutePath withIntermediateDirectories:NO attributes:nil error:&error]) {
    return [PImportWebServerErrorResponse responseWithServerError:kPImportWebServerHTTPStatusCode_InternalServerError underlyingError:error message:@"Failed creating directory \"%@\"", relativePath];
  }
  
  if ([self.delegate respondsToSelector:@selector(webUploader:didCreateDirectoryAtPath:)]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.delegate webUploader:self didCreateDirectoryAtPath:absolutePath];
    });
  }
  return [PImportWebServerDataResponse responseWithJSONObject:@{}];
}

@end

@implementation PImportWebUploader

@synthesize uploadDirectory=_uploadDirectory, allowedFileExtensions=_allowedExtensions, allowHiddenItems=_allowHidden,
            title=_title, header=_header, prologue=_prologue, epilogue=_epilogue, footer=_footer;

@dynamic delegate;

- (instancetype)initWithUploadDirectory:(NSString*)path {
  if ((self = [super init])) {
    NSBundle* siteBundle = [NSBundle bundleWithPath:@"/Library/PreferenceBundles/PImport.bundle"];
    if (siteBundle == nil) {
      return nil;
    }
    _uploadDirectory = [[path stringByStandardizingPath] copy];
    PImportWebUploader* __unsafe_unretained server = self;
    
    // Resource files
    [self addGETHandlerForBasePath:@"/" directoryPath:[siteBundle resourcePath] indexFilename:nil cacheAge:3600 allowRangeRequests:NO];
    
    // Web page
    [self addHandlerForMethod:@"GET" path:@"/" requestClass:[PImportWebServerRequest class] processBlock:^PImportWebServerResponse *(PImportWebServerRequest* request) {
      
#if TARGET_OS_IPHONE
      NSString* device = [[UIDevice currentDevice] name];
#else
      NSString* device = CFBridgingRelease(SCDynamicStoreCopyComputerName(NULL, NULL));
#endif
      NSString* title = server.title;
      if (title == nil) {
        title = @"PImport";
        if (title == nil) {
          title = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
        }
#if !TARGET_OS_IPHONE
        if (title == nil) {
          title = [[NSProcessInfo processInfo] processName];
        }
#endif
      }
      NSString* header = server.header;
      if (header == nil) {
        header = title;
      }
      NSString* prologue = server.prologue;
      if (prologue == nil) {
        prologue = [siteBundle localizedStringForKey:@"PROLOGUE" value:@"<p>Drag &amp; drop files on this window or use the \"Upload Files&hellip;\" button to upload new files.</p>" table:nil];
      }
      NSString* epilogue = server.epilogue;
      if (epilogue == nil) {
        epilogue = path;//[siteBundle localizedStringForKey:@"EPILOGUE" value:@"" table:nil];
      }
      NSString* footer = server.footer;
      if (footer == nil) {
        NSString* name = @"PImport";
        footer = [NSString stringWithFormat:[siteBundle localizedStringForKey:@"FOOTER_FORMAT" value:@"%@ %@" table:nil], name, @"2018"];
      }
      return [PImportWebServerDataResponse responseWithHTMLTemplate:[siteBundle pathForResource:@"index" ofType:@"html"]
                                                      variables:@{
                                                                  @"device": device,
                                                                  @"title": title,
                                                                  @"header": header,
                                                                  @"prologue": prologue,
                                                                  @"epilogue": epilogue,
                                                                  @"footer": footer
                                                                  }];
      
    }];
    
    // File listing
    [self addHandlerForMethod:@"GET" path:@"/rdwifidrive/list" requestClass:[PImportWebServerRequest class] processBlock:^PImportWebServerResponse *(PImportWebServerRequest* request) {
      return [server listDirectory:request];
    }];
    
    // File download
    [self addHandlerForMethod:@"GET" path:@"/rdwifidrive/download" requestClass:[PImportWebServerRequest class] processBlock:^PImportWebServerResponse *(PImportWebServerRequest* request) {
      return [server downloadFile:request];
    }];
    
	// File thumbnail
    [self addHandlerForMethod:@"GET" path:@"/thumbnail" requestClass:[PImportWebServerRequest class] processBlock:^PImportWebServerResponse *(PImportWebServerRequest* request) {
      return [server downloadThumbnailFile:request];
    }];
	
	// File view
    [self addHandlerForMethod:@"GET" path:@"/rdwifidrive/open" requestClass:[PImportWebServerRequest class] processBlock:^PImportWebServerResponse *(PImportWebServerRequest* request) {
      return [server downloadViewFile:request];
    }];
	
	[self addHandlerForMethod:@"GET" path:@"/rdwifidrive/supports_direct_download" requestClass:[PImportWebServerRequest class] processBlock:^PImportWebServerResponse *(PImportWebServerRequest* request) {
      return [PImportWebServerDataResponse responseWithJSONObject:@{@"supports_direct_download": @YES,}];
    }];
	
    // File upload
    [self addHandlerForMethod:@"POST" path:@"/rdwifidrive/upload" requestClass:[PImportWebServerMultiPartFormRequest class] processBlock:^PImportWebServerResponse *(PImportWebServerRequest* request) {
      return [server uploadFile:(PImportWebServerMultiPartFormRequest*)request];
    }];
    
    // File and folder moving
    [self addHandlerForMethod:@"POST" path:@"/move" requestClass:[PImportWebServerURLEncodedFormRequest class] processBlock:^PImportWebServerResponse *(PImportWebServerRequest* request) {
      return [server moveItem:(PImportWebServerURLEncodedFormRequest*)request];
    }];
    
    // File and folder deletion
    [self addHandlerForMethod:@"POST" path:@"/delete" requestClass:[PImportWebServerURLEncodedFormRequest class] processBlock:^PImportWebServerResponse *(PImportWebServerRequest* request) {
      return [server deleteItem:(PImportWebServerURLEncodedFormRequest*)request];
    }];
    
    // Directory creation
    [self addHandlerForMethod:@"POST" path:@"/create" requestClass:[PImportWebServerURLEncodedFormRequest class] processBlock:^PImportWebServerResponse *(PImportWebServerRequest* request) {
      return [server createDirectory:(PImportWebServerURLEncodedFormRequest*)request];
    }];
    
  }
  return self;
}

@end

@implementation PImportWebUploader (Subclassing)

- (BOOL)shouldUploadFileAtPath:(NSString*)path withTemporaryFile:(NSString*)tempPath {
  return YES;
}

- (BOOL)shouldMoveItemFromPath:(NSString*)fromPath toPath:(NSString*)toPath {
  return YES;
}

- (BOOL)shouldDeleteItemAtPath:(NSString*)path {
  return YES;
}

- (BOOL)shouldCreateDirectoryAtPath:(NSString*)path {
  return YES;
}

@end
