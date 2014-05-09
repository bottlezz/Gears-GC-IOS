//
//  TGBroadcastingServer.m
//  GearsGameCenter
//
//  Created by LJ-Jian on 2/22/2014.
//  Copyright (c) 2014 Gears. All rights reserved.
//

#import "TGCommunicationServer.h"
#import "BLWebSocketsServer.h"
#import "GCDSingleton.h"
#import "TGMessage.h"
#import <Foundation/Foundation.h>
#import "JSONModel.h"
#import "TGUser.h"

NSString* const ACTION_BROADCASTING 		= @"broadcasting";
NSString* const ACTION_ADD_USER				= @"add_user";
NSString* const ACTION_DISCONNECT_USER      = @"disconnect_user";
NSString* const ACTION_CONNECT_USER         = @"connect_user";
NSString* const ACTION_SET_USER_PROPERTY 	= @"set_user_property";
NSString* const ACTION_GET_USER_PROPERTY	= @"get_user_property";
NSString* const ACTION_GET_USER_LIST		= @"get_user_list";
NSString* const ACTION_USER_JOINED			= @"user_joined";
NSString* const ACTION_USER_DISCONNECTED	= @"user_disconnected";
NSString* const ACTION_USER_LIST			= @"user_list";

NSString* const ACTION_SET_SHARED_MEMORY 	= @"set_shared_memory";
NSString* const ACTION_GET_SHARED_MEMORY	= @"get_shared_memory";
NSString* const ACTION_SHARED_MEMORY		= @"shared_memory";

__attribute__((deprecated))
NSString* const ACTION_SET_USER 			= @"set_user";

@interface TGCommunicationServer()

@property (strong, nonatomic) NSMutableDictionary *userList;
//@property (strong, nonatomic) NSMutableArray *userList;
@property (nonatomic, strong) NSMutableDictionary *sharedMemory;
//@property (nonatomic, strong) NSMutableArray *messageQueue;

@property (nonatomic, strong) NSDate *tempDate;

@end

@implementation TGCommunicationServer

@synthesize userList = _userList;
@synthesize sharedMemory = _sharedMemory;

#pragma mark - shared instance

+ (id)sharedManager {
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
    });
}

- (NSMutableDictionary *)userList {
	if (!_userList) {
        _userList = [[NSMutableDictionary alloc] init];
    }
    
    return _userList;
}

//- (NSMutableArray *)userList {
//	if (!_userList) {
//        _userList = [[NSMutableArray alloc] init];
//    }
//    
//    return _userList;
//}

- (NSMutableDictionary *)sharedMemory {
	if (!_sharedMemory) {
        _sharedMemory = [[NSMutableDictionary alloc] init];
    }
    
    return _sharedMemory;
}

- (void)startCommunicationServer {
    
    self.portNumber = 8081;
	[[BLWebSocketsServer sharedInstance] startListeningOnPort:self.portNumber withProtocolName:NULL andCompletionBlock:^(NSError *error) {
        if (!error) {
            NSLog(@"Server started");
        }
        else {
            NSLog(@"%@", error);
        }
    }];
    
    [[BLWebSocketsServer sharedInstance] setHandleRequestBlock:^NSData *(NSData *requestData, int sessionID) {

        NSData* jsonData;
        
        
        if(requestData == NULL){
//            BOOL needToChangeHost = false;
//        	NSLog(@"session id: %d disconnected", sessionID);
////            
////          	if([self.userList objectForKey:sessionID]) {
////            	TGUser *user = [self.userList objectForKey:sessionID];
////                if([user.isHost isEqualToString:@"1"]){
////                	needToChangeHost = true;
////                }
////                
////                [self.userList removeObjectForKey:sessionID];
////            }
//            
//            if(needToChangeHost && [self.userList count] > 0){
//            	((TGUser *)[self.userList objectForKey:self.userList.allKeys[0]]).isHost = [NSString stringWithFormat:@"1"];
//            }
//            
//            [self broadcastingUserList];
            
        } else {
            
			TGMessage* newMessage = [TGMessage messageFromJsonData:requestData];
	        newMessage = [self messageHandler:newMessage sessionID:sessionID];
    	    jsonData = [TGMessage jsonDataFromMessage:newMessage];
        }
        return jsonData;
    }];
}

- (TGMessage *)messageHandler:(TGMessage *)message sessionID:(int)sessionID {

    TGMessage *returnedMessage = nil;
    
    NSLog(@"Incoming message action: %@", message.action);
    
    if ([message.action isEqualToString:ACTION_BROADCASTING]) {
        if (message.toSelf) {
        	[self broadcastingMessage:message];
        } else {
        	[self broadcastingMessage:message fromSessionID:sessionID];
        }
    } else if ([message.action isEqualToString:ACTION_ADD_USER]) {
        
        TGUser *newUser = [TGUser userFromObject:message.body withSessionID:sessionID];
        [self addUser:newUser];
        [self broadcastingUserListFromSessionID:sessionID];
    
    }else if ([message.action isEqualToString:ACTION_SET_USER]) {
        

        TGUser *newUser = [[TGUser alloc] init];
        newUser.name = [message.body objectForKey:@"name"];
        newUser.sessionID = sessionID;
        newUser.properties = [message.body objectForKey:@"property"];
        
//        if (self.userList.count == 0) {
//            newUser.isHost = @"1";
//        } else if([self.userList objectForKey:sessionID]) {
//        	newUser.isHost = ((TGUser*)[self.userList objectForKey:sessionID]).isHost;
//        } else {
//            newUser.isHost = @"0";
//        }
//        
//        //add user to userList
//        [self.userList setObject:newUser forKey:sessionID];
        
        
        
		[self broadcastingUserList];
        
    } else if ([message.action isEqualToString:@"get_user_list"]) {
        //prepare return message
        returnedMessage = [[TGMessage alloc] init];
        returnedMessage.action = @"user_list";
        //returnedMessage.timestamp = [NSDate date];
        returnedMessage.name = @"user_list";
//        returnedMessage.userList = [self.userList allValues];
    }else if ([message.action isEqualToString:ACTION_SET_SHARED_MEMORY]) {
//		[self.messageQueue addObject:message];
        [self writeSharedMemory:message];
    } else if ([message.action isEqualToString:@"get_shared_memory"]) {
    	returnedMessage = [self readSharedMemory:message];
    }
    
    return returnedMessage;
}

- (void)broadcastingMessage:(TGMessage *)message {
    NSData* jsonData = [TGMessage jsonDataFromMessage:message];
    [[BLWebSocketsServer sharedInstance] pushToAll:jsonData];
}

- (void)broadcastingMessage:(TGMessage *)message fromSessionID:(int)sessionID {
	NSData* jsonData = [TGMessage jsonDataFromMessage:message];
    [[BLWebSocketsServer sharedInstance] pushToAllOther:jsonData fromSessionID:sessionID];
}

- (void)broadcastingUserListFromSessionID:(int)sessionID {

    
    
	TGMessage *newMessage = [[TGMessage alloc] init];
    newMessage.action = ACTION_USER_LIST;
    newMessage.timestamp = [self getCurrentTimestamp];
    newMessage.name = ACTION_USER_LIST;
    newMessage.body = [self.userList allValues][0];
    
    [self broadcastingMessage:newMessage fromSessionID:sessionID];
}

- (void)addUser:(TGUser *)user {
	
    BOOL needToAdd = false;
    
    if (!user.userID) {
    	user.userID = [NSString stringWithFormat:@"%u", [self.userList count] + 1];
        user.isHost = @"1";
        needToAdd = true;
    } else {
        for (TGUser *user in self.userList) {
            if ([user.userID isEqualToString:user.userID]) {
            
            }
        }
    }
    
    if (needToAdd) {
        [self.userList setObject:user forKey:user.userID];
    }
}

- (void)broadcastingUserList {
	TGMessage *broadcastMessage = [[TGMessage alloc] init];
    broadcastMessage.action = @"user_list";
    broadcastMessage.timestamp = [self getCurrentTimestamp];
    broadcastMessage.name = @"user_list";
//    broadcastMessage.userList = [self.userList allValues];
    
	[self broadcastingMessage:broadcastMessage];
	
}

- (void)writeSharedMemory:(TGMessage *)message {
    @synchronized(self.sharedMemory)
    {
        [self.sharedMemory setObject:message.body forKey:message.name];
        //if (message.isBroadcasting) {
            message.action = ACTION_SHARED_MEMORY;
            [self broadcastingMessage:message];
        //}
    }
}

- (TGMessage*)readSharedMemory:(TGMessage *)message {
    @synchronized(self.sharedMemory)
    {
        TGMessage *returnedMessage = nil;
        if ([self.sharedMemory objectForKey:message.name]) {
            
            returnedMessage = [[TGMessage alloc] init];
            returnedMessage.action = ACTION_SHARED_MEMORY;
            returnedMessage.timestamp = [self getCurrentTimestamp];
            returnedMessage.body = [self getObjectFromMemory:[self.sharedMemory objectForKey:message.name] forPath:message.body];
        }
        
        return returnedMessage;
    }
}

- (id)getObjectFromMemory:(id)memory forPath:(NSString *)path {
    
    NSError *error = nil;
    NSString *pattern = @"\[(.*?)\\]";
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    NSTextCheckingResult *result = [expression firstMatchInString:path options:0 range:NSMakeRange(0, path.length)];
    NSString *value = [path substringWithRange:[result range]];
    NSUInteger index = [value integerValue];
    
    id object = nil;
    
    if ([memory isKindOfClass:[NSDictionary class]]) {
        
    } else if ([memory isKindOfClass:[NSArray class]]) {
        object = [memory objectAtIndex:index];
    }
    
    return object;
}

- (NSString *)getCurrentTimestamp {
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
    return [dateFormatter stringFromDate:currentDate];
}

- (void)stopCommunicationServer {
	[[BLWebSocketsServer sharedInstance] stopWithCompletionBlock:^{
        NSLog(@"Server stopped");
        [self.userList removeAllObjects];
        [self.sharedMemory removeAllObjects];
    }];
}

@end
