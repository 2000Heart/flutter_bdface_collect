//
//  BDFaceActionInfo.h
//  IDLFaceSDK
//
//  Created by v_renshaolei on 2023/9/8.
//  Copyright © 2023 Baidu. All rights reserved.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@interface BDFaceActionInfo : NSObject
/* 各个动作返回参数
 眨眨眼：
 - 当前动作类型
 - 当前动作状态

张嘴：
 - 当前动作类型
 - 当前动作状态

 左转头：
 - 当前动作类型
 - 当前动作状态
 - 初始yaw角
 - 当前姿态yaw角

 右转头：
 - 当前动作类型
 - 当前动作状态
 - 初始yaw角
 - 当前姿态yaw角

 摇头
 - 当前动作类型
 - 当前动作状态
 - 初始yaw角
 - 当前姿态yaw角

 向上抬头
 - 当前动作类型
 - 当前动作状态
 - 初始pitch角
 - 当前姿态pitch角

 向下低头
 - 当前动作类型
 - 当前动作状态
 - 初始pitch角
 - 当前姿态pitch角

 点点头
 - 当前动作类型
 - 当前动作状态
 - 初始pitch角
 - 当前姿态pitch角
 */

/**
 *  动作类型
 */
@property (nonatomic, assign) NSInteger actionType;

/**
 *  0 代表 不存在该动作，1代表存在该动作
 */
@property (nonatomic,assign) int actionStatus;
/**
 *  初始值
 */
@property (nonatomic,assign) float originValue;
/**
 *  当前值
 */
@property (nonatomic,assign) float currentValue;

/**
 *  阀值(不含摇头)
 */
@property (nonatomic,assign) float thresholdValue;

/**
 *  阀值(摇头, 判断左转)
 */
@property (nonatomic,assign) float shakeLeftThresholdValue;
/**
 *  阀值(摇头, 判断右转)
 */
@property (nonatomic,assign) float shakeRightThresholdValue;

/**
 *  非预期动作数量
 */
@property (nonatomic,assign) NSInteger otherLiveCount;



@end

NS_ASSUME_NONNULL_END
