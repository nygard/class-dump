//
//  CDLCNote.m
//  class-dump
//
//  Created by Andy Vandijck on 2/04/19z.
//

#import "CDLCNote.h"

#import "CDMachOFile.h"

@implementation CDLCNote
{
    struct note_command _note;
    const char *_noteData;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        _note.cmd     = [cursor readInt32];
        _note.cmdsize = [cursor readInt32];
        [cursor readBytesOfLength:16 intoBuffer:_note.data_owner];
        _note.offset  = [cursor readInt64];
        _note.size    = [cursor readInt64];
        _noteData = [[cursor machOFile] bytesAtOffset:(NSUInteger)(_note.offset)];
    }
    
    return self;
}

#pragma mark -

- (uint32_t)cmd;
{
    return _note.cmd;
}

- (uint32_t)cmdsize;
{
    return _note.cmdsize;
}

- (NSString *)data_owner
{
    return [NSString stringWithUTF8String:(char *)(_note.data_owner)];
}

- (uint64_t)offset
{
    return _note.offset;
}

- (uint64_t)size
{
    return _note.size;
}

- (NSData *)noteData
{
    return [NSData dataWithBytes:_noteData length:(NSUInteger)(_note.size)];
}
    
- (NSString *)noteDataOwner;
{
    return [NSString stringWithFormat:@"%@\n",
            [self data_owner]];
}

- (void)appendToString:(NSMutableString *)resultString verbose:(BOOL)isVerbose;
{
    [super appendToString:resultString verbose:isVerbose];
    
    [resultString appendFormat:@"    Note data owner: %@\n", self.noteDataOwner];
    [resultString appendFormat:@"    Note data: %s\n", (const char *)([self.noteData bytes])];
}

@end
