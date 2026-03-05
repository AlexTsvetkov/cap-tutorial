
DROP VIEW IF EXISTS StudentService_Students;
DROP TABLE IF EXISTS tutorial_Students;

CREATE TABLE tutorial_Students (
  ID NVARCHAR(36) NOT NULL,
  createdAt TIMESTAMP(7),
  createdBy NVARCHAR(255),
  modifiedAt TIMESTAMP(7),
  modifiedBy NVARCHAR(255),
  firstName NVARCHAR(100),
  lastName NVARCHAR(100),
  email NVARCHAR(255),
  dateOfBirth DATE,
  status NVARCHAR(20) DEFAULT 'ACTIVE',
  PRIMARY KEY(ID)
);


CREATE VIEW StudentService_Students AS SELECT
  Students_0.ID,
  Students_0.createdAt,
  Students_0.createdBy,
  Students_0.modifiedAt,
  Students_0.modifiedBy,
  Students_0.firstName,
  Students_0.lastName,
  Students_0.email,
  Students_0.dateOfBirth,
  Students_0.status
FROM tutorial_Students AS Students_0;

