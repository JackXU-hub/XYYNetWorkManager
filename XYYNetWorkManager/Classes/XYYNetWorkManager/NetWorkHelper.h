//
//  NetWorkHelper.h
//  Pods-XYYBase_Example
//
//  Created by admin on 2019/10/24.
//

#import <Foundation/Foundation.h>
/// 请求成功的Block
typedef void (^CompletioBlock)(NSDictionary *dic, NSURLResponse *response, NSError *error);
typedef void (^SuccessBlock)(NSDictionary *data);
typedef void (^FailureBlock)(NSError *error);
NS_ASSUME_NONNULL_BEGIN

@interface NetWorkHelper : NSObject<NSURLSessionDelegate>

+ (instancetype)shareManager;



/**
 *  get请求
 */
+ (void)getWithUrlString:(NSString *)url parameters:(id)parameters success:(SuccessBlock)successBlock failure:(FailureBlock)failureBlock;

/**
 * post请求
 */
+ (void)postWithUrlString:(NSString *)url parameters:(id)parameters success:(SuccessBlock)successBlock failure:(FailureBlock)failureBlock;

@end

NS_ASSUME_NONNULL_END
