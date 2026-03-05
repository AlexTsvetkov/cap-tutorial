package com.tutorial.studentmanager.handlers;

import com.sap.cds.services.handler.EventHandler;
import com.sap.cds.services.handler.annotations.Before;
import com.sap.cds.services.handler.annotations.ServiceName;
import com.sap.cds.services.cds.CqnService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

@Component
@ServiceName("StudentService")
public class StudentServiceHandler implements EventHandler {

    private static final Logger log = LoggerFactory.getLogger(StudentServiceHandler.class);

    /**
     * Validation: runs BEFORE every CREATE operation on Students.
     * Ensures email contains '@' character.
     */
    @Before(event = CqnService.EVENT_CREATE, entity = "StudentService.Students")
    public void validateStudentEmail(List<Map<String, Object>> students) {
        for (Map<String, Object> student : students) {
            String email = (String) student.get("email");
            if (email != null && !email.contains("@")) {
                throw new IllegalArgumentException("Invalid email: " + email);
            }
            log.info("Creating student: {} {}", student.get("firstName"), student.get("lastName"));
        }
    }
}