//
//  DIConfig.m
//  AHARSDK
//
//  Created by mac on 2017/2/13.
//  Copyright © 2017年 JT Ma. All rights reserved.
//

#import "DIConfig.h"

#define TIME_DURING_D (3600 * 24)
#define TIME_DURING_H (3600)

#define SIZE_M (1024 * 1024)
#define SIZE_K (1024)

BOOL DIConfigComOperatorAnd(BOOL r1, BOOL r2) {
    return r1 && r2;
}

BOOL DIConfigComOperatorOr(BOOL r1, BOOL r2) {
    return r1 || r2;
}

BOOL DIConfigOperatorLess(size_t s1, size_t s2) {
    return s1 < s2;
}
BOOL DIConfigOperatorGreater(size_t s1, size_t s2) {
    return s1 > s2;
}

BOOL DIConfigOperatorEqual(size_t s1, size_t s2) {
    return s1 == s2;
}

int hasPrefix(const char *chs, const char *prefix) {
    size_t sstr = strlen(chs);
    size_t spre = strlen(prefix);
    if (sstr < spre) {
        return 0;
    }
    for (int i = 0; i < spre; ++i) {
        if (chs[i] != prefix[i]) {
            return 0;
        }
    }
    return spre;
}

size_t parseLength(const char *line, size_t len, size_t off) {
    BOOL ready = false;
    size_t size = 0;
    while (off < len) {
        char ch = line[off];
        if (!ready) {
            if (ch < '1' || ch > '9') {
                if (ch == ' ') {
                    ++off;
                    continue;
                }else {
                    return 0;
                }
            }
            ready = true;
        }
        if (ch >= '0' && ch <= '9') {
            size = size * 10 + ch - '0';
        }else {
            break;
        }
        ++off;
    }
    if (size) {
        ready = false;
        while (off < len) {
            char ch = line[off];
            switch (ch) {
                case 'm':
                    size *= SIZE_M;
                    goto set_size;
                    break;
                case 'k':
                    size *= SIZE_K;
                    goto set_size;
                    break;
                case 'd': {
                    size *= TIME_DURING_D;
                    goto set_size;
                    break;
                }
                case 'h': {
                    size *= TIME_DURING_H;
                    goto set_size;
                    break;
                }
                    
                default:
                    break;
            }
            ++off;
        }
    set_size:
        return size;
    }
    return size;
}

@implementation DIConfig

- (id)init {
    self = [super init];
    if (self) {
        _comOp = DIConfigComOperatorAnd;
        _op = DIConfigOperatorLess;
    }
    return self;
}

+ (NSArray *)defaultConfigs {
    NSDate *now = [NSDate date];
    DIConfig *con1 = [[DIConfig alloc] init];
    con1->_date = [now dateByAddingTimeInterval:- 7 *TIME_DURING_D];
    con1->_count = 5;
    con1->_op = DIConfigOperatorLess;
    con1->_comOp = DIConfigComOperatorAnd;
    con1->_size = 100 * SIZE_M;
    
    DIConfig *con2 = [[DIConfig alloc] init];
    con2->_date = [now dateByAddingTimeInterval:- 5 *TIME_DURING_D];
    con2->_count = 3;
    con2->_op = DIConfigOperatorLess;
    con1->_comOp = DIConfigComOperatorOr;
    con2->_size = 300 * SIZE_M;
    
    return @[con1, con2];
}

+ (NSArray *)configsFromPath:(NSString *)path {
    return [self configsFromString:[NSString stringWithContentsOfFile:path
                                                             encoding:NSUTF8StringEncoding
                                                                error:nil]];
}

+ (NSArray *)configsFromString:(NSString *)content {
    NSArray *lines = [content componentsSeparatedByString:@"\n"];
    NSMutableArray *mArr = [NSMutableArray array];
    __block DIConfig *currentConfig = nil;
    void(^newConfig)(const char *) = ^(const char *line) {
        if (currentConfig) {
            [mArr addObject:currentConfig];
            currentConfig = nil;
        }
        size_t len = strlen(line);
        if (len == 0) return;
        currentConfig = [[DIConfig alloc] init];
        switch (line[0]) {
            case '<':
            {
                currentConfig->_op = DIConfigOperatorLess;
            }
                break;
            case '>': {
                currentConfig->_op = DIConfigOperatorGreater;
            }
                break;
            case '=': {
                currentConfig->_op = DIConfigOperatorEqual;
            }
                break;
                
            default:
                break;
        }
        size_t size = parseLength(line, len, 1);
        if (size) {
            currentConfig->_size = size;
        }else {
            currentConfig = nil;
        }
    };
    void (^parseLine)(const char *) = ^(const char *line) {
        if (!currentConfig) return;
        int off = 0;
        int type = 0;
        if (off = hasPrefix(line, "during")) {
            type = 1;
        }else if (off = hasPrefix(line, "count")) {
            type = 2;
        }else if (off = hasPrefix(line, "and")) {
            currentConfig->_comOp = DIConfigComOperatorAnd;
            return;
        }else if (off = hasPrefix(line, "or")) {
            currentConfig->_comOp = DIConfigComOperatorOr;
            return;
        }
        
        if (type) {
            size_t size = parseLength(line, strlen(line), off);
            if (type == 1) {
                currentConfig->_date = [[NSDate date] dateByAddingTimeInterval:-(NSTimeInterval)size];
            }else if (type == 2) {
                currentConfig->_count = size;
            }
        }
    };
    
    for (NSString *line in lines) {
        const char *chs = [line UTF8String];
        if (chs[0] == '<' || chs[0] == '>' || chs[0] == '=') {
            newConfig(chs);
        }else {
            parseLine(chs);
        }
    }
    if (currentConfig) [mArr addObject:currentConfig];
    return mArr;
}

@end
