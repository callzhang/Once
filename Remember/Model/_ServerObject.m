// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ServerObject.m instead.

#import "_ServerObject.h"

const struct ServerObjectAttributes ServerObjectAttributes = {
	.createdAt = @"createdAt",
	.objectId = @"objectId",
	.updatedAt = @"updatedAt",
};

const struct ServerObjectRelationships ServerObjectRelationships = {
};

const struct ServerObjectFetchedProperties ServerObjectFetchedProperties = {
};

@implementation ServerObjectID
@end

@implementation _ServerObject

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"ServerObject" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"ServerObject";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"ServerObject" inManagedObjectContext:moc_];
}

- (ServerObjectID*)objectID {
	return (ServerObjectID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic createdAt;






@dynamic objectId;






@dynamic updatedAt;











@end
