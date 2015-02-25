// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to CRContact.h instead.

#import <CoreData/CoreData.h>
#import "ServerObject.h"

extern const struct CRContactAttributes {
	__unsafe_unretained NSString *company;
	__unsafe_unretained NSString *compositeName;
	__unsafe_unretained NSString *emails;
	__unsafe_unretained NSString *firstName;
	__unsafe_unretained NSString *lastName;
	__unsafe_unretained NSString *phones;
	__unsafe_unretained NSString *photo;
	__unsafe_unretained NSString *recordID;
	__unsafe_unretained NSString *soialProfiles;
	__unsafe_unretained NSString *thumbnail;
} CRContactAttributes;

extern const struct CRContactRelationships {
	__unsafe_unretained NSString *owner;
} CRContactRelationships;

extern const struct CRContactFetchedProperties {
} CRContactFetchedProperties;

@class CRUser;



@class NSObject;


@class NSObject;
@class NSObject;

@class NSObject;
@class NSObject;

@interface CRContactID : NSManagedObjectID {}
@end

@interface _CRContact : ServerObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (CRContactID*)objectID;





@property (nonatomic, strong) NSString* company;



//- (BOOL)validateCompany:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* compositeName;



//- (BOOL)validateCompositeName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) id emails;



//- (BOOL)validateEmails:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* firstName;



//- (BOOL)validateFirstName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* lastName;



//- (BOOL)validateLastName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) id phones;



//- (BOOL)validatePhones:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) id photo;



//- (BOOL)validatePhoto:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* recordID;



//- (BOOL)validateRecordID:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) id soialProfiles;



//- (BOOL)validateSoialProfiles:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) id thumbnail;



//- (BOOL)validateThumbnail:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) CRUser *owner;

//- (BOOL)validateOwner:(id*)value_ error:(NSError**)error_;





@end

@interface _CRContact (CoreDataGeneratedAccessors)

@end

@interface _CRContact (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveCompany;
- (void)setPrimitiveCompany:(NSString*)value;




- (NSString*)primitiveCompositeName;
- (void)setPrimitiveCompositeName:(NSString*)value;




- (id)primitiveEmails;
- (void)setPrimitiveEmails:(id)value;




- (NSString*)primitiveFirstName;
- (void)setPrimitiveFirstName:(NSString*)value;




- (NSString*)primitiveLastName;
- (void)setPrimitiveLastName:(NSString*)value;




- (id)primitivePhones;
- (void)setPrimitivePhones:(id)value;




- (id)primitivePhoto;
- (void)setPrimitivePhoto:(id)value;




- (NSString*)primitiveRecordID;
- (void)setPrimitiveRecordID:(NSString*)value;




- (id)primitiveSoialProfiles;
- (void)setPrimitiveSoialProfiles:(id)value;




- (id)primitiveThumbnail;
- (void)setPrimitiveThumbnail:(id)value;





- (CRUser*)primitiveOwner;
- (void)setPrimitiveOwner:(CRUser*)value;


@end
