//
//  GWUserSession.m
//  GraffitiWalls
//
//  Created by Jakub Knejzlík on 28.06.12.
//  Copyright (c) 2012 Me. All rights reserved.
//

@import AFNetworking;

#import "GNGeocoder.h"

@interface GNGeocoder ()
@property (nonatomic,readonly) AFHTTPSessionManager *sessionManager;
@end


@implementation GNGeocoder

+ (instancetype)sharedInstance {
  static dispatch_once_t once;
  static id sharedInstance;
  dispatch_once(&once, ^{ sharedInstance = [self new]; });
  return sharedInstance;
}

@synthesize sessionManager = _sessionManager;

-(AFHTTPSessionManager *)sessionManager{
  if (!_sessionManager) {
    _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://maps.googleapis.com/maps/api"]];
    _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
  }
  return _sessionManager;
}

#pragma mark - Google Location Stuff

-(void)geocodeName:(NSString *)name
           success:(void (^)(NSArray *))success
           failure:(void (^)(NSError *))failure
{
  return [self geocodeName:name attributes:nil success:success failure:failure];
}

-(void)geocodeName:(NSString *)name
        attributes:(GNGeocoderAttributes *)attributes
           success:(void (^)(NSArray *))success
           failure:(void (^)(NSError *))failure
{
  NSMutableDictionary *params = [[self geocodingParametersFromAttributes:attributes] mutableCopy];
  [params setObject:name forKey:@"address"];
  
  NSURLSessionDataTask *task =
  [self.sessionManager GET:@"geocode/json"
                parameters:params
                  progress:nil
                   success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject) {
                     NSMutableArray *results = [NSMutableArray array];
                     if ([responseObject[@"status"] isEqualToString:@"OK"]) {
                       for (NSDictionary *resultData in responseObject[@"results"]) {
                         [results addObject:[[GNLocationInfo alloc] initWithResultData:resultData]];
                       }
                       success(results);
                     }
                     else {
                       [self handleStatusCode:responseObject[@"status"] withFailureHandler:failure];
                     }
                   }
                   failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                     failure(error);
                   }];
  
  NSLog(@"%@", task.currentRequest.URL);
}

-(void)reverseGeocodeLocation:(CLLocation *)location
                      success:(void (^)(NSArray *))success
                      failure:(void (^)(NSError *))failure
{
  return [self reverseGeocodeLocation:location attributes:nil success:success failure:failure];
}

-(void)reverseGeocodeLocation:(CLLocation *)location
                   attributes:(GNReverseGeocoderAttributes *)attributes
                      success:(void (^)(NSArray *))success
                      failure:(void (^)(NSError *))failure
{
  NSMutableDictionary *params = [[self reverseGeocodingParametersFromAttributes:attributes] mutableCopy];
  [params setObject:[NSString stringWithFormat:@"%f,%f",location.coordinate.latitude,location.coordinate.longitude] forKey:@"latlng"];
  
  NSURLSessionDataTask *task =
  [self.sessionManager GET:@"geocode/json"
                parameters:params
                  progress:nil
                   success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                     NSMutableArray *results = [NSMutableArray array];
                     if ([responseObject[@"status"] isEqualToString:@"OK"]) {
                       for (NSDictionary *resultData in responseObject[@"results"]) {
                         [results addObject:[[GNLocationInfo alloc] initWithResultData:resultData]];
                       }
                       success(results);
                     }
                     else {
                       [self handleStatusCode:responseObject[@"status"] withFailureHandler:failure];
                     }
                   }
                   failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                     failure(error);
                   }];
  
  NSLog(@"%@", task.currentRequest.URL);
}


-(void)handleStatusCode:(NSString *)statusCode
     withFailureHandler:(void(^)(NSError *error))failureHandler
{
  NSArray *errorStatuses = @[@"ZERO_RESULTS",@"OVER_QUERY_LIMIT",@"REQUEST_DENIED",@"INVALID_REQUEST",@"UNKNOWN_ERROR"];
  NSInteger errorCode = [errorStatuses indexOfObject:statusCode];
  NSError *error = [NSError errorWithDomain:@"GNGeocoder response failure" code:errorCode userInfo:@{@"statusCode":statusCode}];
  failureHandler(error);
}

-(NSMutableDictionary *)parametersFromAttributes:(GNGeocoderBaseAttributes *)attributes {
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  
  NSString *lang = (attributes.language?attributes.language:[[NSLocale preferredLanguages] firstObject]);
  if (lang) {
    [dict setObject:lang forKey:@"language"];
  }
  
  if (attributes.apiKey) {
    [dict setObject:attributes.apiKey forKey:@"key"];
  } else if (self.apiKey) {
    [dict setObject:self.apiKey forKey:@"key"];
  }
  
  return dict;
}

-(NSMutableDictionary *)geocodingParametersFromAttributes:(GNGeocoderAttributes *)attributes {
  NSMutableDictionary *dict = [self parametersFromAttributes:attributes];
  
  if (attributes.boundsRegion) {
    [dict setObject:[self boundsStringFromRegion:attributes.boundsRegion] forKey:@"bounds"];
  }
  
  if (attributes.components.allValues.count > 0) {
    [dict setObject:[self componentsStringFromDictionary:attributes.components] forKey:@"components"];
  }
  
  if (attributes.region) {
    [dict setObject:attributes.region forKey:@"region"];
  }
  
  return dict;
}

-(NSMutableDictionary *)reverseGeocodingParametersFromAttributes:(GNReverseGeocoderAttributes *)attributes {
  NSMutableDictionary *dict = [self parametersFromAttributes:attributes];
  
  if (attributes.resultTypes.count > 0) {
    [dict setObject:[attributes.resultTypes componentsJoinedByString:@"|"] forKey:@"result_type"];
  }
  
  if (attributes.locationTypes.count > 0) {
    [dict setObject:[attributes.locationTypes componentsJoinedByString:@"|"] forKey:@"location_type"];
  }
  
  return dict;
}

- (NSString*)boundsStringFromRegion:(CLCircularRegion *)region {
  MKCoordinateRegion coordinateRegion = MKCoordinateRegionMakeWithDistance(region.center, region.radius, region.radius);
  
  NSString *bounds = [NSString stringWithFormat:@"%f,%f|%f,%f",
                      coordinateRegion.center.latitude-(coordinateRegion.span.latitudeDelta/2.0),
                      coordinateRegion.center.longitude-(coordinateRegion.span.longitudeDelta/2.0),
                      coordinateRegion.center.latitude+(coordinateRegion.span.latitudeDelta/2.0),
                      coordinateRegion.center.longitude+(coordinateRegion.span.longitudeDelta/2.0)];
  
  return bounds;
}

- (NSString*)componentsStringFromDictionary:(NSDictionary *)components {
  NSMutableArray *preparedComponents = [NSMutableArray new];
  
  [components enumerateKeysAndObjectsUsingBlock:^(NSString* key, NSString* value, BOOL *stop) {
    NSString *component = [NSString stringWithFormat:@"%@:%@", key, value];
    [preparedComponents addObject:component];
  }];
  
  NSString *componentsValue = [preparedComponents componentsJoinedByString:@"|"];
  
  return componentsValue;
}

@end
