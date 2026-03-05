using { tutorial } from '../db/schema';

/**
 * Student Management Service — exposes Students as an OData V4 endpoint.
 * 
 * By default, CAP provides full CRUD (Create, Read, Update, Delete)
 * for every entity exposed in the service.
 */
service StudentService @(requires: 'authenticated-user') {

    entity Students as projection on tutorial.Students;

}