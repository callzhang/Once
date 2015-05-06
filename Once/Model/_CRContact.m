// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to CRContact.m instead.

#import "_CRContact.h"

const struct CRContactAttributes CRContactAttributes = {
	.company = @"company",
	.compositeName = @"compositeName",
	.emails = @"emails",
	.firstName = @"firstName",
	.lastName = @"lastName",
	.phones = @"phones",
	.photo = @"photo",
	.recordID = @"recordID",
	.soialProfiles = @"soialProfiles",
	.thumbnail = @"thumbnail",
};

const struct CRContactRelationships CRContactRelationships = {
	.owner = @"owner",
};

const struct CRContactFetchedProperties CRContactFetchedProperties = {
};

@implementation CRContactID
@end

@implementation _CRContact

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"CRContact" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"CRContact";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"CRContact" inManagedObjectContext:moc_];
}

- (CRContactID*)objectID {
	return (CRContactID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic company;






@dynamic compositeName;






@dynamic emails;






@dynamic firstName;






@dynamic lastName;






@dynamic phones;






@dynamic photo;






@dynamic recordID;






@dynamic soialProfiles;






@dynamic thumbnail;






@dynamic owner;

	






@end
