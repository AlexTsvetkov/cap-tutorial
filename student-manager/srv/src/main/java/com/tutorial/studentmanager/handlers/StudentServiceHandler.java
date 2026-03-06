package com.tutorial.studentmanager.handlers;

import cds.gen.studentservice.Students;
import com.sap.cds.services.ErrorStatuses;
import com.sap.cds.services.ServiceException;
import com.sap.cds.services.handler.EventHandler;
import com.sap.cds.services.handler.annotations.Before;
import com.sap.cds.services.handler.annotations.ServiceName;
import com.sap.cds.services.cds.CqnService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
@ServiceName("StudentService")
public class StudentServiceHandler implements EventHandler {

    private static final Logger log = LoggerFactory.getLogger(StudentServiceHandler.class);

    /**
     * Validation: runs BEFORE every CREATE operation on Students.
     * Ensures email contains '@' character.
     * Returns HTTP 400 Bad Request if validation fails.
     */
    @Before(event = CqnService.EVENT_CREATE, entity = "StudentService.Students")
    public void validateStudentEmail(List<Students> students) {
        for (Students student : students) {
            String email = student.getEmail();
            if (email != null && !email.contains("@")) {
                throw new ServiceException(ErrorStatuses.BAD_REQUEST, "Invalid email format: " + email + ". Email must contain '@' character.");
            }
            log.info("Creating student: {} {}", student.getFirstName(), student.getLastName());
        }
    }
}
