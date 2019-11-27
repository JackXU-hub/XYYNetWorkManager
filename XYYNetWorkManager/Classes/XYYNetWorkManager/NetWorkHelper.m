//
//  NetWorkHelper.m
//  Pods-XYYBase_Example
//
//  Created by admin on 2019/10/24.
//

#import "NetWorkHelper.h"
#import "NetworkReachabilityManager.h"
//重连次数
#define reConnectNum 3
//定义一个变量
static NetWorkHelper *helper = nil;
@implementation NetWorkHelper
//实例化对象
+ (instancetype)shareManager
{
    @synchronized(self) {
        if (!helper) {
            helper = [[NetWorkHelper alloc] init];
        }
        return helper;
    }
}

//get请求
+ (void)getWithUrlString:(NSString *)url parameters:(id)parameters success:(SuccessBlock)successBlock failure:(FailureBlock)failureBlock
{
    [self shareManager];
     static  NSInteger reConnectCount  = reConnectNum;
    NSMutableString *mutableUrl = [[NSMutableString alloc] initWithString:url];
    if ([parameters allKeys]) {
        [mutableUrl appendString:@"?"];
        for (id key in parameters) {
            NSString *value = [[parameters objectForKey:key] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            [mutableUrl appendString:[NSString stringWithFormat:@"%@=%@&", key, value]];
        }
    }
    NSString *urlEnCode = [[mutableUrl substringToIndex:mutableUrl.length - 1] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlEnCode]];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:helper delegateQueue:queue];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        reConnectCount --;
        if (error) {
            if (reConnectCount > 0){
                [self postWithUrlString:url parameters:parameters success:successBlock failure:failureBlock];
            }
            failureBlock(error);
        } else {
            NSHTTPURLResponse *httpResponse =  (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 200 ||  httpResponse.statusCode ==304){//成功
                 reConnectCount = reConnectNum;
            }else{
                if (reConnectCount > 0){
                    [self postWithUrlString:url parameters:parameters success:successBlock failure:failureBlock];
                }else{
                    reConnectCount = reConnectNum;
                }
                
            }
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            successBlock(dic);
        }
    }];
    [dataTask resume];
}

//post请求
+ (void)postWithUrlString:(NSString *)url parameters:(id)parameters success:(SuccessBlock)successBlock failure:(FailureBlock)failureBlock
{
    [self shareManager];
    static  NSInteger reConnectCount  = reConnectNum;
    NSURL *nsurl = [NSURL URLWithString:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:nsurl];
    //设置请求方式
    request.HTTPMethod = @"POST";
   NSString *postStr = [self convert2JSONWithDictionary:parameters];
    //设置请求体
    request.HTTPBody = [postStr dataUsingEncoding:NSUTF8StringEncoding];
    [self setRequestHeader:request];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:helper delegateQueue:queue];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        reConnectCount --;
        NSLog(@"reConnectCount:%ld",reConnectCount);
        if (error) {
            if (reConnectCount > 0){
                [self postWithUrlString:url parameters:parameters success:successBlock failure:failureBlock];
            }
            failureBlock(error);
        } else {
            NSHTTPURLResponse *httpResponse =  (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 200 ||  httpResponse.statusCode ==304){//成功
                reConnectCount = reConnectNum;
                NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                successBlock(dic);
            }else{
                if (reConnectCount > 0){
                     [self postWithUrlString:url parameters:parameters success:successBlock failure:failureBlock];
                }else{
                     reConnectCount = reConnectNum;
                }
                NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                successBlock(dic);
            }
            
        }
    }];
    [dataTask resume];
}

//把NSDictionary解析成post格式的NSString字符串
+ (NSString *)parseParams:(NSDictionary *)params
{
    NSString *keyValueFormat;
    NSMutableString *result = [NSMutableString new];
    NSMutableArray *array = [NSMutableArray new];
    //实例化一个key枚举器用来存放dictionary的key
    NSEnumerator *keyEnum = [params keyEnumerator];
    id key;
    while (key = [keyEnum nextObject]) {
        keyValueFormat = [NSString stringWithFormat:@"%@=%@&", key, [params valueForKey:key]];
        [result appendString:keyValueFormat];
        [array addObject:keyValueFormat];
    }
    return result;
}

+ (NSString *)convert2JSONWithDictionary:(NSDictionary *)dic{
    NSError *err;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:&err];
    
    NSString *jsonString;
    if (!jsonData) {
        NSLog(@"%@",err);
    }else{
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return jsonString;
}

+ (void)setRequestHeader:(NSMutableURLRequest*)request{
        NSString *AppVer = [[[NSBundle mainBundle] infoDictionary]objectForKey:@"CFBundleShortVersionString"];
        [request addValue:AppVer forHTTPHeaderField:@"appVer"];
        [request addValue:@"2" forHTTPHeaderField:@"terminalType"];
        NSString *uid = [[NSUserDefaults standardUserDefaults]objectForKey:@"uid"];
        [request addValue:uid forHTTPHeaderField:@"uid"];
        [request addValue:@"1.2.0" forHTTPHeaderField:@"version"];
        [request addValue:@"1" forHTTPHeaderField:@"ignoreMonitor"];
        [request addValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
}

#pragma mark - NSURLSessionDelegate 代理方法

//主要就是处理HTTPS请求的
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
{
    NSURLProtectionSpace *protectionSpace = challenge.protectionSpace;
    if ([protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        SecTrustRef serverTrust = protectionSpace.serverTrust;
        completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:serverTrust]);
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}
@end
