namespace tutorial;

using { cuid, managed } from '@sap/cds/common';

/**
 * Student entity — represents a student in our system.
 * 
 * `cuid` provides: ID (UUID, auto-generated key)
 * `managed` provides: createdAt, createdBy, modifiedAt, modifiedBy
 */
entity Students : cuid, managed {
    firstName    : String(100) @mandatory;
    lastName     : String(100) @mandatory;
    email        : String(255) @mandatory;
    dateOfBirth  : Date;
    status       : String(20) default 'ACTIVE';
}