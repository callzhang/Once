// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to CRUser.h instead.

#import <CoreData/CoreData.h>
#import "ServerObject.h"

extern const struct CRUserAttributes {
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *phone;
} CRUserAttributes;

extern const struct CRUserRelationships {
	__unsafe_unretained NSString *contacts;
	__unsafe_unretained NSString *me;
} CRUserRelationships;

extern const struct CRUserFetchedProperties {
} CRUserFetchedProperties;

@class CRContact;
@class CRContact;




@interface CRUserID : NSManagedObjectID {}
@end

@interface _CRUser : ServerObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (CRUserID*)objectID;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* phone;



//- (BOOL)validatePhone:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet *contacts;

- (NSMutableSet*)contactsSet;




@property (nonatomic, strong) CRContact *me;

//- (BOOL)validateMe:(id*)value_ error:(NSError**)error_;





@end

@interface _CRUser (CoreDataGeneratedAccessors)

- (void)addContacts:(NSSet*)value_;
- (void)removeContacts:(NSSet*)value_;
- (void)addContactsObject:(CRContact*)value_;
- (void)removeContactsObject:(CRContact*)value_;

@end

@interface _CRUser (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSString*)primitivePhone;
- (void)setPrimitivePhone:(NSString*)value;





- (NSMutableSet*)primitiveContacts;
- (void)setPrimitiveContacts:(NSMutableSet*)value;



- (CRContact*)primitiveMe;
- (void)setPrimitiveMe:(CRContact*)value;


@end
