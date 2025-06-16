#import <UIKit/UIKit.h>

@implementation GeoIpCountry
@end

@implementation GeoIpLocation
@end

@implementation GeoIpAsn
@end

@implementation GeoIpResponse
@end

@implementation GeoIpFetcher

+ (void)fetchWithCompletion:(GeoIpCompletion)completion {
    NSURL *url = [NSURL URLWithString:@"https://api.geoipapi.com/json"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";

    UIDevice *device = [UIDevice currentDevice];
    NSString *deviceID = [[device identifierForVendor] UUIDString];
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];

    [request setValue:appName forHTTPHeaderField:@"X-App-Name"];
    [request setValue:deviceID forHTTPHeaderField:@"X-Device-ID"];
    [request setValue:device.model forHTTPHeaderField:@"X-Device-Model"];
    [request setValue:device.systemName forHTTPHeaderField:@"X-Device-Manufacturer"];
    [request setValue:device.name forHTTPHeaderField:@"X-Device-Brand"];
    [request setValue:device.systemVersion forHTTPHeaderField:@"X-Device-OS-Version"];
    [request setValue:[[NSProcessInfo processInfo] operatingSystemVersionString] forHTTPHeaderField:@"X-Device-SDK"];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                 completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error || !data) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error ?: [NSError errorWithDomain:@"geoip" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"No data"}]);
            });
            return;
        }

        NSError *jsonError;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError || ![json isKindOfClass:[NSDictionary class]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, jsonError);
            });
            return;
        }

        GeoIpResponse *res = [[GeoIpResponse alloc] init];
        res.ip = json[@"ip"];
        res.type = json[@"type"];

        NSDictionary *country = json[@"country"];
        GeoIpCountry *c = [[GeoIpCountry alloc] init];
        c.isEuMember = [country[@"is_eu_member"] boolValue];
        c.currencyCode = country[@"currency_code"];
        c.continent = country[@"continent"];
        c.name = country[@"name"];
        c.countryCode = country[@"country_code"];
        c.state = country[@"state"];
        c.city = country[@"city"];
        c.zip = country[@"zip"];
        c.timezone = country[@"timezone"];
        res.country = c;

        NSDictionary *loc = json[@"location"];
        GeoIpLocation *l = [[GeoIpLocation alloc] init];
        l.latitude = [loc[@"latitude"] doubleValue];
        l.longitude = [loc[@"longitude"] doubleValue];
        res.location = l;

        NSDictionary *asn = json[@"asn"];
        GeoIpAsn *a = [[GeoIpAsn alloc] init];
        a.number = [asn[@"number"] integerValue];
        a.name = asn[@"name"];
        a.network = asn[@"network"];
        a.type = asn[@"type"];
        res.asn = a;

        dispatch_async(dispatch_get_main_queue(), ^{
            completion(res, nil);
        });
    }];

    [task resume];
}

@end
