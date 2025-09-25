# Clinic Booking System Database

## Overview

This project provides a **MySQL relational database schema** for a Clinic Booking System. It is designed to manage doctors, patients, appointments, services, invoices, prescriptions, and related entities. The schema is intended as a starting point for implementing a real-world healthcare booking and management system.

## Features

* **Doctors and Specialties**: Store doctor details and their medical specialties.
* **Patients and Medical Records**: Manage patient information with one-to-one medical records.
* **Appointments**: Bookings between patients and doctors, with room allocation and status tracking.
* **Services**: Define clinic services (e.g., consultations, lab tests).
* **Invoices & Payments**: Generate invoices for appointments and record payments.
* **Prescriptions**: Doctors can issue prescriptions with itemized medicines.
* **Scheduling**: Support recurring doctor schedules.
* **Audit Logs**: Basic tracking of entity changes.

## Database Design

* **One-to-One**: Each patient has one medical record.
* **One-to-Many**: A doctor can have many appointments.
* **Many-to-Many**: Doctors can belong to multiple specialties; appointments can include multiple services.

## File Structure

* `clinic_booking_system.sql`: Contains the full SQL schema with tables, constraints, indexes, and an example trigger.
* `README.md`: This documentation file.

## Setup Instructions

1. Open MySQL client or a tool like phpMyAdmin.
2. Run the provided SQL script:

   ```sql
   SOURCE clinic_booking_system.sql;
   ```
3. The database `clinic_booking` will be created with all tables and constraints.

## Example Use Cases

* Register patients and doctors.
* Assign doctors to specialties.
* Book appointments and allocate rooms.
* Record services and generate invoices.
* Issue prescriptions for patients.
* Track payments for services rendered.

## Requirements

* MySQL 8.0+ (for trigger and CHECK constraint support).

## Notes

* Some business rules (like advanced overlapping checks) may be better enforced in the application layer.
* You may extend this schema with user authentication, reporting features, or integration with external systems (e.g., insurance).

## License

This project is provided for **educational purposes**. You are free to modify and extend it for your own use.
