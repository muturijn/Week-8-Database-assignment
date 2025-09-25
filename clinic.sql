-- Clinic Booking System SQL Schema
-- File: clinic_booking_system.sql
-- Description: Relational schema for a clinic booking system with tables, constraints, and relationships.

CREATE DATABASE IF NOT EXISTS clinic_booking
  DEFAULT CHARACTER SET = utf8mb4
  DEFAULT COLLATE = utf8mb4_unicode_ci;

USE clinic_booking;

-- --------------------------------------------------
-- Table: specialties (lookup)
-- --------------------------------------------------
CREATE TABLE specialties (
  specialty_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- --------------------------------------------------
-- Table: doctors
-- --------------------------------------------------
CREATE TABLE doctors (
  doctor_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  phone VARCHAR(30) UNIQUE,
  license_number VARCHAR(100) NOT NULL UNIQUE,
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Many-to-many: doctors <-> specialties
CREATE TABLE doctor_specialties (
  doctor_id INT UNSIGNED NOT NULL,
  specialty_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (doctor_id, specialty_id),
  CONSTRAINT fk_ds_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_ds_specialty FOREIGN KEY (specialty_id) REFERENCES specialties(specialty_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- --------------------------------------------------
-- Table: patients
-- --------------------------------------------------
CREATE TABLE patients (
  patient_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  national_id VARCHAR(50) UNIQUE,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  date_of_birth DATE,
  gender ENUM('Male','Female','Other') DEFAULT 'Other',
  email VARCHAR(255) UNIQUE,
  phone VARCHAR(30) UNIQUE,
  address TEXT,
  emergency_contact_name VARCHAR(150),
  emergency_contact_phone VARCHAR(30),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- --------------------------------------------------
-- Table: medical_records (one-to-one with patient)
-- --------------------------------------------------
CREATE TABLE medical_records (
  patient_id INT UNSIGNED PRIMARY KEY,
  blood_type VARCHAR(10),
  allergies TEXT,
  chronic_conditions TEXT,
  notes TEXT,
  last_reviewed DATETIME,
  CONSTRAINT fk_medrec_patient FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- --------------------------------------------------
-- Table: rooms (for in-clinic appointments or procedures)
-- --------------------------------------------------
CREATE TABLE rooms (
  room_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  room_number VARCHAR(50) NOT NULL UNIQUE,
  floor VARCHAR(50),
  type ENUM('Consultation','Procedure','Operating','General') DEFAULT 'Consultation',
  notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- --------------------------------------------------
-- Table: services (e.g., Consultation, X-ray, Blood test)
-- --------------------------------------------------
CREATE TABLE services (
  service_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  code VARCHAR(50) NOT NULL UNIQUE,
  description TEXT,
  price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  duration_minutes INT UNSIGNED NOT NULL DEFAULT 30,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- --------------------------------------------------
-- Table: appointments
-- --------------------------------------------------
CREATE TABLE appointments (
  appointment_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  patient_id INT UNSIGNED NOT NULL,
  doctor_id INT UNSIGNED NOT NULL,
  room_id INT UNSIGNED,
  scheduled_start DATETIME NOT NULL,
  scheduled_end DATETIME NOT NULL,
  status ENUM('Pending','Confirmed','Checked-in','In-Progress','Completed','Cancelled','No-Show') NOT NULL DEFAULT 'Pending',
  reason TEXT,
  created_by INT UNSIGNED, -- staff who created the appointment (optional)
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_appt_patient FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_appt_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_appt_room FOREIGN KEY (room_id) REFERENCES rooms(room_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Indexes to help searching by doctor and time
CREATE INDEX idx_appointments_doctor_time ON appointments(doctor_id, scheduled_start, scheduled_end);
CREATE INDEX idx_appointments_patient_time ON appointments(patient_id, scheduled_start);

-- Many-to-many: appointments <-> services (an appointment can have multiple services)
CREATE TABLE appointment_services (
  appointment_id INT UNSIGNED NOT NULL,
  service_id INT UNSIGNED NOT NULL,
  quantity INT UNSIGNED NOT NULL DEFAULT 1,
  unit_price DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (appointment_id, service_id),
  CONSTRAINT fk_as_appointment FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_as_service FOREIGN KEY (service_id) REFERENCES services(service_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- --------------------------------------------------
-- Table: prescriptions
-- --------------------------------------------------
CREATE TABLE prescriptions (
  prescription_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  appointment_id INT UNSIGNED NOT NULL,
  prescribed_by INT UNSIGNED NOT NULL, -- doctor
  notes TEXT,
  issued_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_presc_appointment FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_presc_doctor FOREIGN KEY (prescribed_by) REFERENCES doctors(doctor_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_presc_appointment ON prescriptions(appointment_id);

-- Prescription items (medicines)
CREATE TABLE prescription_items (
  prescription_item_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  prescription_id INT UNSIGNED NOT NULL,
  medicine_name VARCHAR(255) NOT NULL,
  dosage VARCHAR(100),
  instructions TEXT,
  duration_days INT UNSIGNED,
  CONSTRAINT fk_pi_prescription FOREIGN KEY (prescription_id) REFERENCES prescriptions(prescription_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- --------------------------------------------------
-- Table: invoices
-- --------------------------------------------------
CREATE TABLE invoices (
  invoice_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  appointment_id INT UNSIGNED,
  patient_id INT UNSIGNED NOT NULL,
  invoice_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  subtotal DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  tax DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  total DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  status ENUM('Draft','Unpaid','Paid','Voided') DEFAULT 'Draft',
  CONSTRAINT fk_inv_appointment FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_inv_patient FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Invoice line items
CREATE TABLE invoice_items (
  invoice_item_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  invoice_id INT UNSIGNED NOT NULL,
  description VARCHAR(255) NOT NULL,
  quantity INT UNSIGNED NOT NULL DEFAULT 1,
  unit_price DECIMAL(12,2) NOT NULL,
  line_total DECIMAL(12,2) NOT NULL,
  CONSTRAINT fk_ii_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- --------------------------------------------------
-- Table: payments
-- --------------------------------------------------
CREATE TABLE payments (
  payment_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  invoice_id INT UNSIGNED NOT NULL,
  paid_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  amount DECIMAL(12,2) NOT NULL,
  method ENUM('Cash','Card','Mobile Money','Insurance','Other') DEFAULT 'Cash',
  reference VARCHAR(255),
  received_by INT UNSIGNED,
  CONSTRAINT fk_pay_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- --------------------------------------------------
-- Table: staff (receptionists, admins, nurses, etc.)
-- --------------------------------------------------
CREATE TABLE staff (
  staff_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  role ENUM('Admin','Receptionist','Nurse','Pharmacist','Accountant','Other') DEFAULT 'Other',
  email VARCHAR(255) UNIQUE,
  phone VARCHAR(30) UNIQUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- --------------------------------------------------
-- Table: doctor_schedules (recurring availability)
-- --------------------------------------------------
CREATE TABLE doctor_schedules (
  schedule_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  doctor_id INT UNSIGNED NOT NULL,
  weekday TINYINT UNSIGNED NOT NULL, -- 0=Sunday .. 6=Saturday
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  CONSTRAINT fk_dsched_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT chk_time_span CHECK (start_time < end_time)
) ENGINE=InnoDB;

-- --------------------------------------------------
-- Table: audit_logs (simple audit)
-- --------------------------------------------------
CREATE TABLE audit_logs (
  log_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  entity VARCHAR(100) NOT NULL,
  entity_id VARCHAR(100) NOT NULL,
  action VARCHAR(50) NOT NULL,
  changed_by INT UNSIGNED,
  change_time DATETIME DEFAULT CURRENT_TIMESTAMP,
  details TEXT
) ENGINE=InnoDB;

-- --------------------------------------------------
-- Useful Views (optional) - uncomment to create
-- --------------------------------------------------
-- CREATE VIEW vw_upcoming_appointments AS
-- SELECT a.appointment_id, a.scheduled_start, a.scheduled_end, a.status,
--        p.first_name AS patient_first, p.last_name AS patient_last,
--        d.first_name AS doctor_first, d.last_name AS doctor_last
-- FROM appointments a
-- JOIN patients p ON a.patient_id = p.patient_id
-- JOIN doctors d ON a.doctor_id = d.doctor_id
-- WHERE a.scheduled_start >= NOW();

-- --------------------------------------------------
-- Example constraints or triggers could be added to enforce
-- business rules (e.g., no overlapping appointments for same doctor)
-- However, complex checks are better handled in application logic or via stored procedures.

-- Example: Prevent overlapping appointments for a doctor (simplified trigger)
-- NOTE: Triggers are provided as examples and should be adapted/tested in production.

DELIMITER $$
CREATE TRIGGER trg_appointments_before_insert
BEFORE INSERT ON appointments
FOR EACH ROW
BEGIN
  -- Simple overlapping check: if another appointment for same doctor overlaps, raise an error
  IF EXISTS(
    SELECT 1 FROM appointments a
    WHERE a.doctor_id = NEW.doctor_id
      AND a.status NOT IN ('Cancelled','No-Show')
      AND (NEW.scheduled_start < a.scheduled_end AND NEW.scheduled_end > a.scheduled_start)
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Doctor has another appointment that overlaps this time.';
  END IF;
END$$
DELIMITER ;

-- End of schema
