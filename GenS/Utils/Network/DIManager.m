//
//  DIManager.m
//  DownloadInterface
//
//  Created by gen on 03/12/2016.
//  Copyright © 2016 gen. All rights reserved.
//

#import "DIManager.h"
#import <CommonCrypto/CommonDigest.h>
#import "PKMultipartInputStream.h"
#import "DIConfig.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#define Z_SUFFIX @".tmp"
#define D_SUFFIX @".dl"
#define D2_SUFFIX @".dld"



static NSMutableDictionary *NSURLSession_dictionary = nil;
NSMutableDictionary *DIManager_handlerCache = nil;

@implementation DIData

@end

// item delegate 的消息也要向manager发送一次。
@protocol DIItemManagerDelegate <DIItemDelegate>

- (void)itemDead:(DIItem*)item;

@end

/**
 * item需要实现NSCoding协议， 让item能够序列化
 * 以及反序列化
 * 序列化用 NSKeyedArchiver
 * 反序列化用 NSKeyedUnarchiver
 * 序列化时注意把Process序列化为Pause
 * 这样可以简化下载开始时的逻辑
 */
@interface DIItem () <NSCoding,NSURLSessionDelegate> {
    NSString    *_path;
    NSTimer     *_timer;
}

// 管理器的回调
@property (nonatomic, weak) id<DIItemManagerDelegate> managerDelegate;
@property (nonatomic, strong) NSURLSessionTask *dataTask;
@property (nonatomic, strong) NSString *name;

- (void)setUrlString:(NSString *)url;
- (void)setManager:(DIManager*)manager;

@end

/**
 * 一个弱引用对象，让Item的释放不会被字典约束。
 */
@interface DICacheItem : NSObject

@property (nonatomic, weak, readonly) DIItem* item;

- (instancetype)initWithItem:(DIItem*)item;

@end

@implementation DICacheItem

- (instancetype)initWithItem:(DIItem *)item {
    self = [super init];
    if (self) {
        _item = item;
    }
    return self;
}

@end

NSString *const DIManagerBasePathKey = @"AHARSDK/Resources";

@interface DIManager () <DIItemManagerDelegate> {
    /**
     * 缓存item,当item没有开始下载的时候放到这里，
     * 当这个item开始下载的时候移动到_items里边
     */
    NSMutableDictionary<NSString*, DICacheItem*> *_cacheItems;
    
    NSURLSessionConfiguration   *_config;
    BOOL _didModifyItems;
    
    NSArray<DIConfig*> *_configs;
    DIItem* _protectingItem;
    NSMutableArray *_temporaryPauseItems;
}

@property (nonatomic, readonly) NSOperationQueue *queue;
@property (nonatomic, readonly) NSURLSessionConfiguration   *config;

- (NSString *)stringMD5:(NSString *)originalString;
- (NSURLSession *)session:(id)delegate;
- (NSURLSession *)downloadSession:(id)delegate identifier:(NSString *)identifier;

@end

@implementation DIItem {
    NSError *_error;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.urlString
                  forKey:@"urlString"];
    [aCoder encodeObject:self->_name
                  forKey:@"name"];
    [aCoder encodeObject:@(self.status == DIStatusProcess ? DIStatusPause : self.status)
                  forKey:@"status"];
    [aCoder encodeObject:@(self.totalSize)
                  forKey:@"totalSize"];
    [aCoder encodeObject:@(self.size)
                  forKey:@"size"];
    [aCoder encodeObject:@(self.percent)
                  forKey:@"percent"];
    [aCoder encodeObject:self.method
                  forKey:@"method"];
    [aCoder encodeObject:self.requestDate forKey:@"requestDate"];
    [aCoder encodeObject:@(self.unlessCount) forKey:@"unlessCount"];
    [aCoder encodeObject:@(self.download)
                  forKey:@"download"];
}

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super init];
    if (self) {
        _timeout = 6;
        _urlString = [aCoder decodeObjectForKey:@"urlString"];
        _name = [aCoder decodeObjectForKey:@"name"];
        _method = [aCoder decodeObjectForKey:@"method"];
        _status = [[aCoder decodeObjectForKey:@"status"] unsignedIntegerValue];
        if (_status == DIStatusProcess) _status = DIStatusPause;
        _totalSize = [[aCoder decodeObjectForKey:@"totalSize"] integerValue];
        _size = [[aCoder decodeObjectForKey:@"size"] integerValue];
        _percent = [[aCoder decodeObjectForKey:@"percent"] floatValue];
        _requestDate = [aCoder decodeObjectForKey:@"requestDate"];
        _unlessCount = [[aCoder decodeObjectForKey:@"unlessCount"] integerValue];
        self.download = [[aCoder decodeObjectForKey:@"download"] boolValue];
    }
    return self;
}

//-(NSString *)description {
//    NSString *des = @"";
//    des = [NSString stringWithFormat:@"\n name:%@ \n status:%d \n totalSize : %f \n size : %f \n requestDate : %@ \n unlessCount : %d",self.name,self.status,self.totalSize,self.size,self.requestDate,self.unlessCount];
//    return des;
//}

- (instancetype)initWithManager:(DIManager *)manager {
    self = [super init];
    if (self) {
        _timeout = 10;
        self.manager = manager;
        self.method = @"GET";
    }
    return self;
}

- (void)setManager:(DIManager *)manager {
    _manager = manager;
}

- (void)setUrlString:(NSString *)urlString {
    _urlString = urlString;
}

- (void)dealloc {
    if ([_managerDelegate respondsToSelector:@selector(itemDead:)]) {
        [_managerDelegate itemDead:self];
    }
}

- (NSString *)path {
    if (!_path && _name) {
        _path = [_manager.path stringByAppendingPathComponent:_name];
    }
    return _path;
}

- (void)setPath:(NSString *)path {
    _path = path;
    _name = [_path lastPathComponent];
}

/**
 * 获得下载数据
 * 直接读取path文件的内容并返回即可
 */
- (NSData*)data {
    NSData *data = [[NSFileManager defaultManager] contentsAtPath:self.path];
    return data;
}

#pragma mark - NSURLSession Delegate

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    void (^comp)() = [DIManager_handlerCache objectForKey:session.configuration.identifier];
    if (comp) {
        comp();
        [session invalidateAndCancel];
    }
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error{
    if (session.configuration.identifier) {
        [NSURLSession_dictionary removeObjectForKey:session.configuration.identifier];
        
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task  didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * __nullable credential))completionHandler {
    if(challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
        NSURLCredential *credntial = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential,credntial);
    }
}

- (void)complete {
    _dataTask = nil;
    if (self.status == DIStatusDone) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(itemComplete:)]) {
                [self.delegate itemComplete:self];
            }
            
            if (self.block) {
                self.block(self, DICallbackComplete, nil);
            }
        });
        return;
    }
    if ([self.managerDelegate respondsToSelector:@selector(itemComplete:)]) {
        [self.managerDelegate itemComplete:self];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(itemComplete:)]) {
            [self.delegate itemComplete:self];
        }
        
        if (self.block) {
            self.block(self, DICallbackComplete, nil);
        }
    });
}

- (void)failed:(NSError *)error {
    _dataTask = nil;
    if (self.readCacheWhenError) {
        NSFileManager *manager = [NSFileManager defaultManager];
        if ([manager fileExistsAtPath:self.path]) {
            [self complete];
            return;
        }
    }
    if (self.status != DIStatusNone)
        self.status = DIStatusPause;
    if ([self.managerDelegate respondsToSelector:@selector(itemFailed:error:)]) {
        [self.managerDelegate itemFailed:self error:error];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(itemFailed:error:)]) {
            [self.delegate itemFailed:self error:error];
        }
        if (self.block) {
            self.block(self, DICallbackFailed, error);
        }
    });
}

#pragma mark - NSURLSessionData Delegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    if(self.dataTask && self.dataTask != task) {
        return;
    }
    [_timer invalidate];
    _timer = nil;
    if (_error) error = _error;
    if (error) {
        if (error.code == -3003) {
            [[NSFileManager defaultManager] removeItemAtPath:[self.path stringByAppendingString:D2_SUFFIX]
                                                       error:nil];
            [self pause];
            [self start];
        }else
            [self failed:error];
    } else {
        NSHTTPURLResponse *response = (NSHTTPURLResponse*)task.response;
        //NSString *errorString = @"";
        if (response.statusCode != 200 && response.statusCode != 206) {
            [self failed:[NSError errorWithDomain:@"Unknow error"
                                             code:response.statusCode
                                         userInfo:nil]];
        }
        else {
            NSString *dpath = [self.path stringByAppendingString:D_SUFFIX];
            NSFileManager *manager = [NSFileManager defaultManager];
            if ([manager fileExistsAtPath:dpath] == NO) {
                NSLog(@"dpath NOT exists");
            }
            if ([manager fileExistsAtPath:dpath]) {
                if (self.totalSize == 0) {
                    _totalSize = self.size;
                }
                if ([manager fileExistsAtPath:self.path]) {
                    [manager removeItemAtPath:self.path
                                        error:nil];
                }
                [manager moveItemAtPath:dpath
                                 toPath:self.path
                                  error:nil];
                [self complete];
            }else {
                [self failed:[NSError errorWithDomain:@"Unkown error."
                                                 code:900
                                             userInfo:nil]];
            }
        }

    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    _totalSize = totalBytesExpectedToWrite;
    _size = totalBytesWritten;
//    NSLog(@"downloadTask : %@",downloadTask);
//    NSLog(@"dataTask %@",self.dataTask);
//    NSLog(@"session : %@",session);
//    NSLog(@"---线程---%@",[NSThread currentThread]);
//    double progress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
    float progress = 0;
    if (self.totalSize > 0) {
        progress = self.size / (float)self.totalSize;
        progress = MIN(progress, 1.0);
    }
    
    self.percent = progress;
    if (self.managerDelegate && [self.managerDelegate respondsToSelector:@selector(item:process:)]) {
        [self.managerDelegate item:self process:progress];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(item:process:)]) {
            [self.delegate item:self process:progress];
        }
        if (self.block) {
            self.block(self,DICallbackProcess, [NSNumber numberWithFloat:progress]);
        }
    });
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)downloadURL {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSError *error;
    NSString *path = [self.path stringByAppendingString:D_SUFFIX];
    [fileManager removeItemAtPath:path error:NULL];
    BOOL success = [fileManager moveItemAtURL:downloadURL
                                        toURL:[NSURL fileURLWithPath:path]
                                        error:&error];
    NSDictionary *dic = [fileManager attributesOfItemAtPath:path
                                                      error:nil];
    _size = dic.fileSize;
    _totalSize = dic.fileSize;
    
    self.percent = 1;
    if (self.managerDelegate && [self.managerDelegate respondsToSelector:@selector(item:process:)]) {
        [self.managerDelegate item:self process:self.percent];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(item:process:)]) {
            [self.delegate item:self process:self.percent];
        }
        if (self.block) {
            self.block(self,DICallbackProcess, [NSNumber numberWithFloat:self.percent]);
        }
    });
    [session invalidateAndCancel];
    if (success) {
//        [self complete];
    }else {
        [self failed:error];
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    NSHTTPURLResponse *response = (NSHTTPURLResponse*)dataTask.response;
//    NSLog(@"%@", response);
    
    if (response.statusCode == 200) {
        if (_totalSize <= 0){
            _totalSize = dataTask.countOfBytesExpectedToReceive;
        }
        _totalSize = MAX(_totalSize, 0);
    }else if (response.statusCode == 206){
        if (_totalSize <= 0){
            NSString *contentRange = [response.allHeaderFields valueForKey:@"Content-Range"];
            if ([contentRange hasPrefix:@"bytes"]) {
                NSArray *bytes = [contentRange componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" -/"]];
                if ([bytes count] == 4) {
                    _totalSize = [[bytes objectAtIndex:3] longLongValue];
                    _totalSize = MAX(_totalSize, 0);
                }
            }
            else {
                NSArray *rangComponent = [contentRange componentsSeparatedByString:@"-/"];
                NSString *totalRang = [rangComponent lastObject];
                _totalSize = [totalRang longLongValue];
                _totalSize = MAX(_totalSize, 0);
            }
        }
    }else if (response.statusCode == 416){
        NSString *contentRange = [response.allHeaderFields valueForKey:@"Content-Range"];
        if ([contentRange hasPrefix:@"bytes"]) {
            NSArray *bytes = [contentRange componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" -/"]];
            if ([bytes count] == 3) {
                _totalSize = [[bytes objectAtIndex:2] longLongValue];
                _totalSize = MAX(_totalSize, 0);
                if (self.size >= self.totalSize) {
                    //NSLog(@"下载完成");
                }else{
                    //416 Requested Range Not Satisfiable
                    //self.error = [[NSError alloc]initWithDomain:[self.url absoluteString] code:416 userInfo:response.allHeaderFields];
                }
            }
        }
        return;
    }else{
        _error = [NSError errorWithDomain:[response.URL absoluteString]
                                     code:response.statusCode
                                 userInfo:response.allHeaderFields];
        return;
    }
    
    NSString *dpath = [self.path stringByAppendingString:D_SUFFIX];
    const char *cpath = dpath.UTF8String;
    FILE *file = fopen(cpath, "a");
    if (!file) {
        file = fopen(cpath, "w");
    }
    if (file) {
        fwrite(data.bytes, data.length, 1, file);
        fclose(file);
    }else {
        [self failed:[NSError errorWithDomain:@"Can not read file"
                                         code:600
                                     userInfo:nil]];
        [self pause];
        return;
    }
    
    self.size += data.length;
//    NSLog(@"currentItem.size : %ld (%lld)",(long)self.size,self.totalSize);
    
    float percent = 0;
    if (self.totalSize > 0) {
        percent = self.size / (float)self.totalSize;
        percent = MIN(percent, 1.0);
    }
    self.percent = percent;
    if (self.managerDelegate && [self.managerDelegate respondsToSelector:@selector(item:process:)]) {
        [self.managerDelegate item:self process:percent];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(item:process:)]) {
            [self.delegate item:self process:percent];
        }
        if (self.block) {
            self.block(self,DICallbackProcess, [NSNumber numberWithFloat:percent]);
        }
    });
    
}

#pragma mark - String Change
static inline NSString *NSStringCCHashFunction(unsigned char *(function)(const void *data, CC_LONG len, unsigned char *md), CC_LONG digestLength, NSString *string)
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[digestLength];
    
    function(data.bytes, (CC_LONG)data.length, digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:digestLength * 2];
    
    for (int i = 0; i < digestLength; i++)
    {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return output;
}

- (NSString *)stringMD5:(NSString *)originalString {
    return NSStringCCHashFunction(CC_MD5, CC_MD5_DIGEST_LENGTH, originalString);
}

- (NSString *)identifierWithURLSting:(NSString *)URLString {
    NSString *identifier = @"";
    identifier = [self stringMD5:URLString];
    return identifier;
}

#pragma mark - DIItem Operate

- (void)start {
    if (self.status == DIStatusProcess)
        return;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.urlString]];
    request.timeoutInterval = self.timeout;
    long long downloadedBytes = 0;
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL exists = [manager fileExistsAtPath:self.path];
    
    if (self.status == DIStatusDone && exists && self.readCache) {
        [self complete];
        return;
    }
    if (self.readCache) {
        if (self.totalSize >= 0) {
            if (exists && self.size >= self.totalSize && self.size) {
                [self performSelector:@selector(complete)
                           withObject:nil
                           afterDelay:0];
                return;
            }
        }
        
        if (downloadedBytes == 0) {
            NSString *dpath = [self.path stringByAppendingString:D_SUFFIX];
            if ([manager fileExistsAtPath:dpath]) {
                downloadedBytes = [self fileSizeForPath:dpath];
                self.size = downloadedBytes;
                if (downloadedBytes >= self.totalSize && self.totalSize) {
                    if ([manager fileExistsAtPath:self.path]) {
                        [manager removeItemAtPath:self.path
                                            error:nil];
                    }
                    [manager moveItemAtPath:dpath
                                     toPath:self.path
                                      error:nil];
                    [self complete];
                    return;
                }else {
                    NSString *requestRange = [NSString stringWithFormat:@"bytes=%llu-", downloadedBytes];
                    [request setValue:requestRange forHTTPHeaderField:@"Range"];
                }
                goto start_request;
            }
        }
    }
    [request setValue:@"bytes=0-" forHTTPHeaderField:@"Range"];
    self.size = 0;
start_request:
    
    _error = nil;
    [request setHTTPMethod:self.method];
    if (![self.method isEqualToString:@"GET"] && self.datas.count) {
        switch (self.postType) {
            case DIPostTypeForm: {
                PKMultipartInputStream *body = [[PKMultipartInputStream alloc] init];
                __block NSInteger index = 0;
                [self.datas enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    if ([obj isKindOfClass:[DIData class]]) {
                        DIData *data = obj;
                        [body addPartWithName:key
                                     filename:data.fileName
                                         data:data.data
                                  contentType:data.mineType];
                    }else if ([obj isKindOfClass:[NSData class]]) {
                        [body addPartWithName:key
                                     filename:[NSString stringWithFormat:@"file%d.dat", index]
                                         data:obj
                                  contentType:@"application/octet-stream"];
                    }else if ([obj isKindOfClass:[NSString class]]) {
                        [body addPartWithName:key
                                       string:obj];
                    }
                    ++index;
                }];
                [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", [body boundary]] forHTTPHeaderField:@"Content-Type"];
                [request setValue:[NSString stringWithFormat:@"%d", [body length]] forHTTPHeaderField:@"Content-Length"];
//                [request setHTTPBodyStream:body];
                size_t length = [body length];
                void *buffer = malloc(length);
                [body read:buffer
                 maxLength:length];
                [request setHTTPBody:[NSData dataWithBytes:buffer
                                                    length:[body length]]];
                free(buffer);
            }
                break;
            case DIPostTypeJson: {
                
            }
                
            default:
                break;
        }
    }
    NSURLSession *session;
    if (self.download) {
        session = [_manager downloadSession:self identifier:self.name];
        if (!session) {
            self.download = NO;
            goto not_download;
        }
        [session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
            if (downloadTasks.count) {
                self.dataTask = downloadTasks.firstObject;
            }else {
                NSString *dpath = [self.path stringByAppendingString:D2_SUFFIX];
                NSFileManager *fileManager = [NSFileManager defaultManager];
                if ([fileManager fileExistsAtPath:dpath]) {
                    self.dataTask = [session downloadTaskWithResumeData:[NSData dataWithContentsOfFile:dpath]];
                }else
                    self.dataTask = [session downloadTaskWithRequest:request];
            }
            [self.dataTask resume];
            [session finishTasksAndInvalidate];
        }];
    }else {
    not_download:
        session = [_manager session:self];
        self.dataTask = [session dataTaskWithRequest:request];
        [self.dataTask resume];
        [session finishTasksAndInvalidate];
    }
    
    _totalSize = 0;
    _timer = [NSTimer timerWithTimeInterval:self.timeout
                                     target:self
                                   selector:@selector(sTimeout:)
                                   userInfo:self.dataTask
                                    repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:_timer
                                 forMode:NSDefaultRunLoopMode];
    
    self.status = DIStatusProcess;
    
    if (self.managerDelegate && [self.managerDelegate respondsToSelector:@selector(itemStarted:)]) {
        [self.managerDelegate itemStarted:self];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(itemStarted:)]) {
            [self.delegate itemStarted:self];
        }
        
        if (self.block) {
            self.block(self,DICallbackStart,nil);
        }
    });
}

- (void)sTimeout:(NSTimer *)timer {
    if (self.dataTask == timer.userInfo) {
        if (self.status != DIStatusDone) {
            
            self.status = DIStatusPause;
            
            _error = [NSError errorWithDomain:@"Timeout"
                                         code:980
                                     userInfo:nil];
        }
        [self _pause];
        [_timer invalidate];
        _timer = nil;
    }
}

- (void)_pause {
    if ([self.dataTask isKindOfClass:[NSURLSessionDownloadTask class]]) {
        [(NSURLSessionDownloadTask *)self.dataTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            NSString *dpath = [self.path stringByAppendingString:D2_SUFFIX];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if ([fileManager fileExistsAtPath:dpath]) {
                [fileManager removeItemAtPath:dpath
                                        error:nil];
            }
            [resumeData writeToFile:dpath
                         atomically:YES];
        }];
    }else {
        [self.dataTask cancel];
    }
}

- (void)pause {
    NSLog(@"item pause");
//    NSArray *syms = [NSThread  callStackSymbols];
//    if ([syms count] > 1) {
//        NSLog(@"<%@ %p> %@ - caller: %@ ", [self class], self, NSStringFromSelector(_cmd),[syms objectAtIndex:1]);
//    } else {
//        NSLog(@"<%@ %p> %@", [self class], self, NSStringFromSelector(_cmd));
//    }
    if (self.status == DIStatusDone) {
        return;
    }
    self.status = DIStatusPause;
    
    [self _pause];
    
    if (self.managerDelegate && [self.managerDelegate respondsToSelector:@selector(itemPaused:)]) {
        [self.managerDelegate itemPaused:self];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(itemPaused:)]) {
            [self.delegate itemPaused:self];
        }
        
        if (self.block) {
            self.block(self,DICallbackPause,nil);
        }
    });
}

- (void)cancel {
    if (self.status != DIStatusProcess) return;
    [self.dataTask cancel];
    
    self.status = DIStatusNone;
    [self remove];
    
    if (self.managerDelegate && [self.managerDelegate respondsToSelector:@selector(itemCanceled:)]) {
        [self.managerDelegate itemCanceled:self];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(itemCanceled:)]) {
            [self.delegate itemCanceled:self];
        }
        
        if (self.block) {
            self.block(self,DICallbackCancel,nil);
        }
    });
}

- (void)remove {
    
    if ([self.managerDelegate respondsToSelector:@selector(itemRemoved:)]) {
        [self.managerDelegate itemRemoved:self];
    }
    
    
    NSFileManager *manager = [NSFileManager defaultManager];
    NSError *error;
    [manager removeItemAtPath:self.path
                        error:&error];
    [manager removeItemAtPath:[self.path stringByAppendingString:D_SUFFIX]
                        error:&error];
    [manager removeItemAtPath:[self.path stringByAppendingString:D2_SUFFIX]
                        error:&error];
    [manager removeItemAtPath:[self.path stringByAppendingString:Z_SUFFIX]
                        error:&error];
    NSLog(@"deleted path %@ %d", self.path, [manager fileExistsAtPath:self.path]);
    //NSLog(@"remove ［%@］: %@",self.path, hasRemove ? @"成功" : @"失败");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.status == DIStatusProcess) {
            [self _pause];
        }
        _size = 0;
        _totalSize = 0;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(itemRemoved:)]) {
            [self.delegate itemRemoved:self];
        }
        
        if (self.block) {
            self.block(self,DICallbackRemoved,nil);
        }
    });
}

- (NSString *)filePathWithURLString:(NSString *)URLString {
    NSString *identifier = [self identifierWithURLSting:URLString];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@",[DIManager defaultManager].path, identifier];
    
    return filePath;
}

- (long long)fileSizeForPath:(NSString *)path {
    long long fileSize = 0;
    NSFileManager *fileManager = [NSFileManager new]; // not thread safe
    if ([fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        NSDictionary *fileDict = [fileManager attributesOfItemAtPath:path error:&error];
        if (!error && fileDict) {
            fileSize = [fileDict fileSize];
        }
    }
    return fileSize;
}

@end

@implementation DIManager

@synthesize queue = _queue;

static NSString * DIItemArchiverkey = @"item.archiver";

static DIManager* _defaultManager = NULL;

typedef void (*DIManagerApplicationIMP)(id this, SEL sel, UIApplication *app, NSString *identify, void (^completionHandler)());

+ (instancetype)defaultManager {
    @synchronized ([DIManager class]) {
        if (!_defaultManager) {
            
            Class cls = [[UIApplication sharedApplication].delegate class];
            SEL sel = @selector(application:handleEventsForBackgroundURLSession:completionHandler:);
            DIManagerApplicationIMP imp = (DIManagerApplicationIMP)class_getMethodImplementation(cls, sel);
            IMP nImp = imp_implementationWithBlock(^(id this,  UIApplication *app, NSString *identify, void (^completionHandler)()){
                if (imp) imp(this, sel, app, identify, completionHandler);
                if (!DIManager_handlerCache) {
                    DIManager_handlerCache = [NSMutableDictionary dictionary];
                }
                [DIManager_handlerCache setObject:completionHandler
                                           forKey:identify];
            });
            if (imp) {
                class_replaceMethod(cls, sel, nImp, "v20@0:4@8@12@?16");
            }else {
                class_addMethod(cls, sel, nImp, "v20@0:4@8@12@?16");
            }
            _defaultManager = [[DIManager alloc] init];
        }
        
        return _defaultManager;
    }
}

- (instancetype)init {
    if (self = [super init]) {
        _items = [[NSMutableArray alloc] init];
        _itemIndexes = [[NSMutableDictionary alloc] init];
        _cacheItems = [[NSMutableDictionary alloc] init];
        
        _queue = [[NSOperationQueue alloc] init];
        _queue.maxConcurrentOperationCount = 3;
        
        _protectingItem = nil;
        _configs = [DIConfig defaultConfigs];
        
        [self restoredItems];
        
        [self performSelector:@selector(autoSave)
                   withObject:nil
                   afterDelay:10];
    }
    return self;
}

- (void)loadConfig:(NSString *)path {
    NSArray *configs = [DIConfig configsFromPath:path];
    if (configs.count)
        _configs = configs;
}

- (NSURLSessionConfiguration *)config {
    if (!_config) {
        _config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    }
    _config.requestCachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    return _config;
}

- (NSURLSession *)session:(id)delegate {
//    return [NSURLSession sessionWithConfiguration:self.config
//                                         delegate:delegate
//                                    delegateQueue:self.queue];
    return [NSURLSession sessionWithConfiguration:self.config
                                         delegate:delegate
                                    delegateQueue:[NSOperationQueue mainQueue]];
}

- (NSURLSession *)downloadSession:(id)delegate identifier:(NSString *)identifier {
    if (!NSURLSession_dictionary) {
        NSURLSession_dictionary = [NSMutableDictionary dictionary];
    }
    NSURLSession *session = [NSURLSession_dictionary objectForKey:identifier];
//    NSLog(@"session-objectForKey : %@",session);
//    if (session) {
//        [session invalidateAndCancel];
//        [NSURLSession_dictionary removeObjectForKey:identifier];
//    }
    if (!session) {
        NSURLSessionConfiguration *cls = [NSURLSessionConfiguration class];
        NSURLSessionConfiguration *config;
        if ([cls respondsToSelector:@selector(backgroundSessionConfigurationWithIdentifier:)]) {
            config = [cls performSelector:@selector(backgroundSessionConfigurationWithIdentifier:)
                               withObject:identifier];
        }else if ([cls respondsToSelector:@selector(backgroundSessionConfiguration:)]) {
            config = [cls performSelector:@selector(backgroundSessionConfiguration:)
                               withObject:identifier];
        }
//        session = [NSURLSession sessionWithConfiguration:config
//                                                delegate:delegate
//                                           delegateQueue:self.queue];
        session = [NSURLSession sessionWithConfiguration:config
                                                delegate:delegate
                                           delegateQueue:[NSOperationQueue mainQueue]];
//        NSLog(@"session-sessionWithConfiguration : %@",session);
        [NSURLSession_dictionary setObject:session
                                    forKey:identifier];
    }else {
        session = nil;
//        NSLog(@"session-nil");
    }
    return session;
}

- (void)autoSave {
    if (_didModifyItems) {
        [self save];
    }
    [self performSelector:@selector(autoSave)
               withObject:nil
               afterDelay:30];
}

- (NSString *)path {
    if (!_path) {
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES) objectAtIndex:0];
        NSString *filePath = [path stringByAppendingPathComponent:DIManagerBasePathKey];
        NSError *anError = nil;
        BOOL isDir = YES;
        NSFileManager *manager = [NSFileManager defaultManager];
        
        if (![manager fileExistsAtPath:filePath isDirectory:&isDir] || !isDir){
            if (!isDir) [manager removeItemAtPath:filePath
                                            error:nil];
            BOOL aCreateDirectorySuccess = [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:&anError];
            if (aCreateDirectorySuccess == NO){
                //NSLog(@"ERR on create directory: %@ (%@, %d)", anError, [NSString stringWithUTF8String:__FILE__].lastPathComponent, __LINE__);
            }
            else{
                NSURL *fileDirectoryURL = [NSURL URLWithString:filePath];
                BOOL aSetResourceValueSuccess = [fileDirectoryURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&anError];
                if (aSetResourceValueSuccess == NO){
                    //NSLog(@"ERR on set resource value (NSURLIsExcludedFromBackupKey): %@ (%@, %d)", anError, [NSString stringWithUTF8String:__FILE__].lastPathComponent, __LINE__);
                }
                else {
                    _path = [fileDirectoryURL absoluteString];
                }
            }
        }
        else {
            _path = filePath;
        }
    }
    return _path;
}

- (void)dealloc {
}

#pragma mark -
- (void)itemDead:(DIItem *)item {
//    [_cacheItems removeObjectForKey:item.urlString];
    [_cacheItems removeObjectForKey:item.name];
}

- (void)itemStarted:(DIItem *)item {
    //NSLog(@"%s", __func__);
    
    NSString *identifier = item.name;
    DICacheItem *cacheItem = _cacheItems[identifier];
    if (cacheItem) {
        @synchronized (_cacheItems) {
            [_cacheItems removeObjectForKey:identifier];
        }
    }
    
    @synchronized (_items) {
        if (![_itemIndexes objectForKey:identifier]) {
            [_items addObject:item];
            [_itemIndexes setObject:item forKey:identifier];
            _didModifyItems = YES;
        }
    }
}

- (void)itemPaused:(DIItem *)item {
    //NSLog(@"%s", __func__);
    //    [self restoredItems];
}

- (void)itemCanceled:(DIItem *)item {
    //NSLog(@"%s", __func__);
    if (item != DIStatusNone) {
        @synchronized (_items) {
            [_items removeObject:item];
//            [_itemIndexes removeObjectForKey:item.urlString];
            [_itemIndexes removeObjectForKey:item.name];
            _didModifyItems = YES;
        }
    }
    [self save];
    //    [self restoredItems];
}

- (void)itemComplete:(DIItem *)item {
    //NSLog(@"%s",__func__);
    if (item.status != DIStatusDone) {
        item.status = DIStatusDone;
        _totalSize += item.totalSize;
        _totalSize = MAX(_totalSize, 0);
        [self save];
    }
}

- (void)itemRemoved:(DIItem *)item {
    @synchronized (_items) {
        [_items removeObject:item];
        [_itemIndexes removeObjectForKey:item.name];
        _didModifyItems = YES;
    }
    @synchronized (_cacheItems) {
        [_cacheItems removeObjectForKey:item.name];
    }
    if (item.status == DIStatusDone) {
        _totalSize -= item.totalSize;
        _totalSize = MAX(_totalSize, 0);
    }
    [self save];
}

- (void)itemFailed:(DIItem *)item error:(NSError *)error {
    
}

#pragma mark -
- (DIItem *)itemWithURLString:(NSString *)urlString {
    return [self itemWithURLString:urlString
                             cache:urlString];
}

- (DIItem *)itemWithURLString:(NSString *)urlString cache:(NSString *)cacheUrl {
//    NSLog(@"%s url : %@ cache : %@",__func__, urlString,cacheUrl);
    
    NSString *identifier = [self stringMD5:cacheUrl];
    DIItem *tempItem = _itemIndexes[identifier];
    
    if (tempItem) {
        tempItem.requestDate = [NSDate date];
        tempItem.unlessCount = 0;
        [self save];
        return tempItem;
    } else {
        DICacheItem *cacheItem = _cacheItems[identifier];
        if (cacheItem.item) {
            cacheItem.item.requestDate = [NSDate date];
            cacheItem.item.unlessCount = 0;
            [self save];
            return cacheItem.item;
        }
    }
    
    DIItem *item = [[DIItem alloc] initWithManager:self];
    item.urlString = urlString;
    item.status = DIStatusNone;
    item.name = identifier;
    item.requestDate = [NSDate date];
    item.unlessCount = 0;
    
    DICacheItem *cacheItem = [[DICacheItem alloc] initWithItem:item];
    @synchronized (_cacheItems) {
        [_cacheItems setObject:cacheItem forKey:identifier];
    }
    
    // 在这里设置 manager的回调.
    item.managerDelegate = self;
    item.manager = self;
    
    return item;
}

#pragma mark -

dispatch_queue_t DIManger_save_queue;
bool saveing_key = NO;

- (void)save {
    if (!DIManger_save_queue) {
        DIManger_save_queue = dispatch_queue_create("DIManger_save", NULL);
    }
    
    if (saveing_key || !_didModifyItems) return;
    saveing_key = YES;
    
    NSMutableArray *arr = [_items copy];
    
    dispatch_async(DIManger_save_queue, ^{
        NSString *path = [_path stringByAppendingPathComponent:DIItemArchiverkey];
        [NSKeyedArchiver archiveRootObject:arr toFile:path];
        saveing_key = NO;
    });
    _didModifyItems = NO;
}

- (void)restoredItems{
    NSString *path = [self.path stringByAppendingPathComponent:DIItemArchiverkey];
    NSArray *restoredDataItems = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    
    @synchronized (_items) {
        [_items removeAllObjects];
        [_itemIndexes removeAllObjects];
        _totalSize = 0;
        for (DIItem *item in restoredDataItems) {
            NSString *identifier = item.name;
            if (identifier && ![_itemIndexes objectForKey:identifier]) {
                [_items addObject:item];
                item.manager = self;
                item.managerDelegate = self;
                [_itemIndexes setObject:item forKey:identifier];
                _totalSize += item.size;
                _totalSize = MAX(_totalSize, 0);
            }
        }
    }
}

#pragma mark -

- (NSString *)stringMD5:(NSString *)originalString {
    return NSStringCCHashFunction(CC_MD5, CC_MD5_DIGEST_LENGTH, originalString);
}

#pragma mark -

- (void)clear {
    @synchronized (_items) {
        NSArray *arr = [_items copy];
        for (DIItem *item in arr) {
            if (item.status != DIStatusProcess) {
                [item remove];
            }
        }
        _totalSize = 0;
    }
}

- (void)removeItemWithIdentifier:(NSString *)identifier {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSError *error;
    NSString *path = [[DIManager defaultManager].path stringByAppendingPathComponent:identifier];
    BOOL dir = NO;
    if ([manager fileExistsAtPath:path isDirectory:&dir]) {
        if (dir) {
            DIItem *item = _itemIndexes[identifier];
            if (item) {
                [item remove];
            }
            else {
                BOOL hasRemove = [manager removeItemAtPath:path
                                                     error:&error];
            }
        }
        else {
        }
    }
}

- (void)setProtectingItem:(DIItem *)item {
    _protectingItem = item;
}

- (NSString *)autoClearConfigPath {
    NSString *configPath = [[DIManager defaultManager].path stringByAppendingPathComponent:@"cacheConfig"];
    return configPath;
}

- (void)updateItemsUnlessCount {
    @synchronized (_items) {
        NSArray *items = [[NSArray alloc] initWithArray:_items];
        for (DIItem *item in _items) {
            item.unlessCount++;
            NSLog(@"itemName : %@ (%d)",item.name,item.unlessCount);
        }
        [self save];
    }
}

static NSDate *LastAutoClearDate = nil;
- (void)autoClearIncreaseUnlessCount:(BOOL)increaseUnlessCount {
    
    [self performSelectorInBackground:@selector(autoClear) withObject:nil];
    
    if (increaseUnlessCount) {
        [self updateItemsUnlessCount];
    }
}

- (void)autoClear {
    BOOL hadHandle = NO;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitDay fromDate:LastAutoClearDate toDate:[NSDate date] options:0];
    NSInteger day = dateComponents.day;
    NSString *configPath = [[DIManager defaultManager] autoClearConfigPath];
    BOOL configExists = [[NSFileManager defaultManager] fileExistsAtPath:configPath];
    if (day >= 1 && _configs.count > 0 && configExists) {
        //app到后台超过一天回来更新_configs
        [self loadConfig:configPath];
    }
    LastAutoClearDate = [NSDate date];
    
    for (DIConfig *config in _configs) {
        if (config.op(_totalSize, config.size)) {
            @synchronized (_items) {
                NSArray *items = [[NSArray alloc] initWithArray:_items];
                for (DIItem *item in items) {
                    NSDate *earlierDate = [item.requestDate earlierDate:config.date];
                    BOOL earlier = earlierDate == item.requestDate ? YES : NO;
                    BOOL countGreater = item.unlessCount >= config.count ? YES : NO;
                    if (config.comOp(earlier,countGreater)) {
                        if (item != _protectingItem) {
                            [item remove];
                        }
                    }
                }
            }
            hadHandle = YES;
            break;
        }
    }
    
    if (hadHandle == NO) {
        DIConfig *lastConfig = [_configs lastObject];
        float maxLimited = lastConfig.size;
        
        if (_totalSize > maxLimited) {
            @synchronized (_items) {
                NSArray *items = [[NSArray alloc] initWithArray:_items];
                NSArray *resultItems = [items sortedArrayUsingComparator:^NSComparisonResult(DIItem * _Nonnull obj1, DIItem * _Nonnull obj2) {
                    if ([obj1.requestDate earlierDate:obj2.requestDate] == obj1.requestDate) {
                        return (NSComparisonResult)NSOrderedAscending;
                    }
                    else {
                        return (NSComparisonResult)NSOrderedDescending;
                    }
                    return (NSComparisonResult)NSOrderedSame;
                }];
                
                for (DIItem *item in resultItems) {
                    if (item != _protectingItem) {
                        [item remove];
                    }
                    if (_totalSize < maxLimited) {
                        break;
                    }
                }
            }
        }
    }
}

#pragma mark -

- (void)pauseProcessItems {
    if (_temporaryPauseItems == nil) {
        _temporaryPauseItems = [[NSMutableArray alloc] init];
    }
    for (DIItem *item in _items) {
        if (item.status == DIStatusProcess && item.download == YES) {
            [_temporaryPauseItems addObject:item];
            [item pause];
        }
    }
}

- (void)restartPauseItems {
    for (DIItem *item in _temporaryPauseItems) {
        if (item.status == DIStatusPause) {
            [item start];
        }
    }
    [_temporaryPauseItems removeAllObjects];
}

- (void)dispalyItems {
    NSInteger index = 0;
    for (DIItem *item in _items) {
        NSLog(@"[%d] : %@",index,item);
    }
}

@end
