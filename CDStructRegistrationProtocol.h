@class NSString;
@class CDType;

@protocol CDStructRegistration
- (void)registerStruct:(CDType *)structType name:(NSString *)aName;
@end
