@interface NSData (SnapAdditions)

@end

@interface NSMutableData (SnapAdditions)

- (void)rw_appendInt32:(int)value;
- (void)rw_appendInt16:(short)value;
- (void)rw_appendInt8:(char)value;
- (void)rw_appendString:(NSString *)string;

@end