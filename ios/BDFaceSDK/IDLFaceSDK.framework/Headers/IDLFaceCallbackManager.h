//
//  IDLFaceCallbackManager.h
//  IDLFaceSDK
//
//  Created by v_renshaolei on 2023/9/1.
//  Copyright © 2023 Baidu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDFaceActionInfo.h"

NS_ASSUME_NONNULL_BEGIN


typedef void(^IDLFaceRemainTimeBlock)(CGFloat remainTime);
typedef void(^IDLFaceSingleActionTimeBlock)(CGFloat singleActionRemainTime);
typedef void(^IDLQualityInfoBlock)(NSString *qualityRemind, CGFloat currentValue, CGFloat thresholdValue);
typedef void(^IDLActionInfoBlock)(BDFaceActionInfo *actionInfo);


@interface IDLFaceCallbackManager : NSObject

/*
 回调剩余时间
 */
@property (nonatomic, copy) IDLFaceRemainTimeBlock faceRemainTimeBlock;

/*
 回调单个动作剩余时间
 */
@property (nonatomic, copy) IDLFaceRemainTimeBlock singleActionTimeBlock;

/*
 质量相关信息输出
 */
@property (nonatomic, copy) IDLQualityInfoBlock qulityInfoBlock;

/*
 动作相关信息输出
 */
@property (nonatomic, copy) IDLActionInfoBlock actionInfoBlock;


+ (instancetype)sharedInstance;


@end

NS_ASSUME_NONNULL_END
