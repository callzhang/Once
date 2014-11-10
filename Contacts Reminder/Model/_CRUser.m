// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to CRUser.m instead.

#import "_CRUser.h"

const struct CRUserAttributes CRUserAttributes = {
	.name = @"name",
	.phone = @"phone",
};

const struct CRUserRelationships CRUserRelationships = {
	.contacts = @"contacts",
	.me = @"me",
};

const struct CRUserFetchedProperties CRUserFetchedProperties = {
};

@implementation CRUserID
@end

@implementation _CRUser

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"CRUser" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"CRUser";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"CRUser" inManagedObjectContext:moc_];
}

- (CRUserID*)objectID {
	return (CRUserID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic name;






@dynamic phone;






@dynamic contacts;

	
- (NSMutableSet*)contactsSet {
	[self willAccessValueForKey:@"contacts"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"contacts"];
  
	[self didAccessValueForKey:@"contacts"];
	return result;
}
	

@dynamic me;

	






@end
