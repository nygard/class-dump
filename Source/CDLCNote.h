//
//  CDLCNote.h
//  class-dump
//
//  Created by Andy Vandijck on 2/04/19z.
//

#ifndef CDLCNote_h
#define CDLCNote_h

#import "CDLoadCommand.h"

@interface CDLCNote : CDLoadCommand

@property (nonatomic, readonly) NSString *noteDataOwner;
@property (nonatomic, readonly) NSData *noteData;

@end

#endif /* CDLCNote_h */
