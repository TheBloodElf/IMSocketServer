//
//  IMChatMessage.h
//  SocketIMDemo
//
//  Created by Mac on 2018/3/27.
//  Copyright © 2018年 Mac. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 服务器会把这个消息进行存储，该类数据取自MsgContent，按照https://zhuanlan.zhihu.com/p/31377253?refer=helloim中提到的思想，用下面的方法来变相实现了消息同步库（离线消息）和消息存储库（漫游消息）；因为重点不在服务器，就用一个表搞定。
 1：当10001获取他的未读消息时，则从数据库中获取reciver_imid=10001&&msg_id<last_msg_id（客户端本地存储的最后一条msg_id）即可；因为并不会存在sender_imid=10001的未读消息（想一下发送逻辑）
 2：获取10001和10002之间所有聊天内容，则从数据库中获取sender_id=10001&&reciver_id=10002||sender_id=10002&&reciver_id=10001即可
 也就是说，该类就充当了消息同步库和消息存储库的作用；当然了，如果后面做某些功能的时候不得不拆分，那就拆吧。。。
 */
@interface IMMsgContent : RLMObject

/**消息ID 建议用毫秒时间戳既可 用作Timeline逻辑模型中的顺序ID 用于拉取离线*/
@property (nonatomic, assign) int64_t msg_id;
/**发送消息时填自己的终端类型，接收消息时为对方的终端类型*/
@property (nonatomic, assign) E_SOCKET_CLIENT_TYPE from_source_type;
/**发送消息时，自己的uid，接收消息时是对方的uid*/
@property (nonatomic, assign) int64_t sender_imid;
/**发送消息时，对方的uid,接收时自己的uid*/
@property (nonatomic, assign) int64_t reciver_imid;
/**消息时间，发送消息时可以不关心这个字段，由server填充，如果是接收方，则是收到该消息的时间，单位秒 */
@property (nonatomic, assign) int64_t time;
/**消息内容 是IMChatMesssage对象的json格式字符串*/
@property (nonatomic, strong) NSString *msg_data;

@end
