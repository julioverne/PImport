//
//  ExifContainerPImport.m
//  Pods
//
//  Created by Nikita Tuk on 02/02/15.
//
//

#import <ImageIO/CGImageProperties.h>
#import <CoreLocation/CoreLocation.h>
#import "ExifContainer.h"

NSString const * kCGImagePropertyProjection = @"ProjectionType";


@implementation ExifContainerPImport
@synthesize imageData, imageMetadata;
- (instancetype)init
{
    self = [super init];
    if(self) {
		imageMetadata = [[NSMutableDictionary alloc] init];
    }
    return self;
}
- (id)initWithImage:(NSData*)image
{
	self = [super init];
	if(self) {
		imageData = image;
		imageMetadata = [[NSMutableDictionary alloc] init];
		[self applyExifInfo];
	}
	return self;
}
- (void)applyExifInfo
{
	CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef) imageData, NULL);
    
	NSDictionary *metadata = (__bridge NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
	NSMutableDictionary *metadataAsMutable = [metadata?:@{} mutableCopy];
	
	[metadataAsMutable  addEntriesFromDictionary:imageMetadata];
	
	imageMetadata = [metadataAsMutable?:@{} mutableCopy];
	
	CFRelease(source);
}
- (void)applyExifInfoToImageData
{
	CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef) imageData, NULL);
	
	[self applyExifInfo];
	
    CFStringRef UTI = CGImageSourceGetType(source);
	
    NSMutableData *dest_data = [NSMutableData data];
    CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)dest_data, UTI, 1, NULL);
	
    if (!destination) {
        NSLog(@"Error: Could not create image destination");
    }
	
    CGImageDestinationAddImageFromSource(destination, source, 0, (__bridge CFDictionaryRef)imageMetadata);
    BOOL success = NO;
    success = CGImageDestinationFinalize(destination);
    if (!success) {
        NSLog(@"Error: Could not create data from image destination");
    }
	
    CFRelease(destination);
    CFRelease(source);
	
    imageData = dest_data;
}
- (void)savePhotoWithCurrentExif
{
	[self applyExifInfoToImageData];
	
	ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];	
	UIImage* imageToSave = [[UIImage alloc] initWithData:imageData];
	
	[library writeImageToSavedPhotosAlbum:imageToSave.CGImage metadata:imageMetadata completionBlock:^(NSURL *newURL, NSError *error) {
        if (error) {
            NSLog( @"Error writing image with metadata to Photo Library: %@", error );
        } else {
            NSLog( @"Wrote image %@ with imageMetadata: %@",newURL,imageMetadata);
        }
    }];
}

- (void)addLocation:(double)longitude latitude:(double)latitude
{
	//CLLocationDegrees latitude  = currentLocation.coordinate.latitude;
	//CLLocationDegrees longitude = currentLocation.coordinate.longitude;
	
	NSString *latitudeRef = nil;
	NSString *longitudeRef = nil;
	
	if (latitude < 0.0) {
        
        latitude *= -1;
        latitudeRef = @"S";
        
    } else {
        
        latitudeRef = @"N";
        
    }
    
    if (longitude < 0.0) {
        
        longitude *= -1;
        longitudeRef = @"W";
        
    } else {
        
        longitudeRef = @"E";
        
    }
    
    //self.gpsDictionary[(NSString*)kCGImagePropertyGPSTimeStamp] = [self getUTCFormattedDate:currentLocation.timestamp];
    
    self.gpsDictionary[@"LatitudeRef"] = latitudeRef;
    self.gpsDictionary[@"Latitude"] = [NSNumber numberWithFloat:latitude];

    self.gpsDictionary[@"LongitudeRef"] = longitudeRef;
    self.gpsDictionary[@"Longitude"] = [NSNumber numberWithFloat:longitude];

    //self.gpsDictionary[(NSString*)kCGImagePropertyGPSDOP] = [NSNumber numberWithFloat:currentLocation.horizontalAccuracy];
    //self.gpsDictionary[(NSString*)kCGImagePropertyGPSAltitude] = [NSNumber numberWithFloat:currentLocation.altitude];
	
}

- (void)addCreationDate:(NSDate *)date forExifKey:(NSString *)key
{
	NSString *dateString = [self getUTCFormattedDate:date];
    [self setValue:dateString forExifKey:key];
}
- (NSDate*)getCreationDateForExifKey:(NSString *)key
{
	NSString *dateString = [self getValueForExifKey:key];
    return [self getUTCFormattedNSDate:dateString];
}


- (void)addProjection:(NSString *)projection {

    [self setValue:projection forExifKey:(NSString *)kCGImagePropertyProjection];

}

- (void)setValue:(NSString *)value forExifKey:(NSString *)key {

    [self.exifDictionary setObject:value forKey:key];

}

- (id)getValueForExifKey:(NSString *)key
{
	return self.exifDictionary[key];
}

#pragma mark - Getters

- (NSMutableDictionary *)exifDictionary {
    
    return [self dictionaryForKey:(NSString*)kCGImagePropertyExifDictionary];
    
}

- (NSMutableDictionary *)tiffDictionary {
    
    return [self dictionaryForKey:(NSString*)kCGImagePropertyTIFFDictionary];
    
}

- (NSMutableDictionary *)jfifDictionary {
    
    return [self dictionaryForKey:(NSString*)kCGImagePropertyJFIFDictionary];
    
}

- (NSMutableDictionary *)gifDictionary {
    
    return [self dictionaryForKey:(NSString*)kCGImagePropertyGIFDictionary];
    
}

- (NSMutableDictionary *)pngDictionary {
    
    return [self dictionaryForKey:(NSString*)kCGImagePropertyPNGDictionary];
    
}

- (NSMutableDictionary *)gpsDictionary {
    
    return [self dictionaryForKey:@"{GPS}"];
    
}

- (NSMutableDictionary *)dictionaryForKey:(NSString *)key
{
	NSMutableDictionary *dict = self.imageMetadata[key];
	if (!dict) {
		dict = [[NSMutableDictionary alloc] init];
		self.imageMetadata[key] = dict;
	}
	return dict;
}

#pragma mark - Helpers

- (NSString *)getUTCFormattedDate:(NSDate *)localDate {
    
    static NSDateFormatter *dateFormatter = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"];
        
    });

    
    return [dateFormatter stringFromDate:localDate];

}

- (NSDate *)getUTCFormattedNSDate:(NSString*)localDate
{    
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"];
        
    });
    return [dateFormatter dateFromString:localDate];
}


@end
