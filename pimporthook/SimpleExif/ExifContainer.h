//
//  ExifContainerPImport.h
//  Pods
//
//  Created by Nikita Tuk on 02/02/15.
//
//

#import <Foundation/Foundation.h>

@class CLLocation;

@interface ExifContainerPImport : NSObject

@property (nonatomic, strong) NSData *imageData;
@property (nonatomic, strong) NSMutableDictionary *imageMetadata;

@property (nonatomic, strong, readonly) NSMutableDictionary *exifDictionary;
@property (nonatomic, strong, readonly) NSMutableDictionary *tiffDictionary;
@property (nonatomic, strong, readonly) NSMutableDictionary *gpsDictionary;
@property (nonatomic, strong, readonly) NSMutableDictionary *jfifDictionary;
@property (nonatomic, strong, readonly) NSMutableDictionary *gifDictionary;
@property (nonatomic, strong, readonly) NSMutableDictionary *pngDictionary;

- (id)initWithImage:(NSData*)image;

- (void)addLocation:(double)longitude latitude:(double)latitude;

- (void)addCreationDate:(NSDate *)date forExifKey:(NSString *)key;
- (NSDate*)getCreationDateForExifKey:(NSString *)key;

- (void)addProjection:(NSString *)projection;

- (void)setValue:(NSString *)key forExifKey:(NSString *)value;
- (id)getValueForExifKey:(NSString *)key;

- (void)applyExifInfo;
- (void)applyExifInfoToImageData;
- (void)savePhotoWithCurrentExif;

@end


#import <CoreGraphics/CoreGraphics.h>
#import <AssetsLibrary/AssetsLibrary.h>

typedef struct CGImageSource *CGImageSourceRef;
typedef struct CGImageDestination *CGImageDestinationRef;

extern CGImageSourceRef CGImageSourceCreateWithData(CFDataRef data, CFDictionaryRef options);
extern CFStringRef CGImageSourceGetType(CGImageSourceRef isrc);
extern CGImageDestinationRef CGImageDestinationCreateWithData(CFMutableDataRef data, CFStringRef type, size_t count, CFDictionaryRef opts);
extern void CGImageDestinationAddImageFromSource(CGImageDestinationRef dest, CGImageSourceRef source, size_t index, CFDictionaryRef properties);
extern bool CGImageDestinationFinalize(CGImageDestinationRef dest);
extern CFDictionaryRef CGImageSourceCopyPropertiesAtIndex(CGImageSourceRef source, size_t index, CFDictionaryRef opts);