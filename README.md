
# Commuter Reservation System — Group 10

A database-driven Train Reservation System designed according to the given business rules for booking, cancelling, and managing confirmed and waitlisted tickets.

---

## Project Overview

This project implements a complete backend system for **train ticket reservations** using **Oracle SQL & PL/SQL**.
It follows the exact requirements defined in the assignment:

* Train data
* Train status (available seats, booked seats, waitlist)
* Passenger information
* Ticket booking & cancellation
* Waitlist management
* Only Business & Economy class
* Limited seats & waitlist slots
* Advance booking rules

The system supports automatic confirmation, waitlisting, cancellation, promotion, and waitlist compacting.

---

##  Repository Structure

```
CommuterReservationSystem_Group10/
│
├── SchemaCreation/                -- Tables, sequences, constraints
├── Train_Data/                    -- Sample data inserts
├── Train_App/                     -- PL/SQL packages (book, cancel, promotion logic)
├── RUN_ALL_TRAIN_SYSTEM.sql       -- Master script to run complete system
├── er-trainmanagementsystem.jpg   -- ER diagram (conceptual model)
└── test_cases.sql                 -- Manual tests for booking + cancellation
```

---

##  Requirements (from assignment)

### **1. Train Data Includes**

* Train number
* Departure & arrival stations
* Arrival and departure times
* Days when the train is in service

### **2. Train Status Includes**

* The train number
* Date for which the train is available to book
* Number of seats available
* Number of seats booked

### **3. Passenger Data Includes**

* Passenger name (first & last)
* Date of birth (to determine minor / major / senior citizen)
* Address (home address)
* Email
* Phone number

---

##  **Business Rules Implemented**

### **1. Passenger email & phone must be unique.**

### **2. Passengers can book tickets only if seats are available.**

### **3. Booking requires:**

* Valid passenger
* Valid train
* Valid booking date

### **4. Before confirming a ticket:**

* Train number, booking date, seat class are validated
* If validation passes → ticket ID generated

### **5. After seats are fully booked:**

* **10 additional WAITLIST tickets** allowed
* If waitlist slots full → booking NOT allowed

### **6. Ticket Cancellation:**

* A ticket can be cancelled anytime
* Cancellation of a CONFIRMED ticket → **first waitlisted passenger gets promoted**
* Cancellation of a WAITLISTED ticket → **compact waitlist positions**

### **7. Only one-week advance booking is allowed**

### **8. Only two seat classes: Business & Economy**

### **9. Maximum seat capacity per class: 40 seats**

### **10. Each class can have up to *5 waitlist tickets***

---

##  **System Features Implemented**

###  Ticket Booking

* Auto-assigns confirmed seat if available
* Otherwise assigns next waitlist position
* Prevents over-booking
* Validates booking window (1-week limit)

###  Ticket Cancellation

* Cancels both CONFIRMED and WAITLISTED bookings
* Promotes first waitlisted passenger
* Rearranges remaining waitlist (compacting)

###  Data Validation

* Train & passenger existence
* Booking time window
* Class availability
* Duplicate booking prevention

---

##  **Database Design**

### **Conceptual Model (ER Diagram)**

The ER diagram is included as:
`er-trainmanagementsystem.jpg`

Contains entities:

* TRAIN
* TRAIN_STATUS
* PASSENGER
* RESERVATION (Booking)
* Supporting relationships
* Attributes mapped based on assignment rules

### **Normalization**

* Step-by-step conversion from **1NF → 2NF → 3NF** included in report
* All tables are fully normalized
* Composite keys used appropriately
* No transitive dependencies

---

##  **Setup Instructions**

###  Clone the repository

```bash
git clone https://github.com/PriyankaVadivel12/CommuterReservationSystem_Group10.git
```

###  Run Schema Creation Scripts

Create required tables, constraints, sequences.

###  Load Sample Data

Run scripts in **Train_Data/**.

### Compile PL/SQL Package

Contains:

* `book_ticket`
* `cancel_ticket`
* Promotion & waitlist logic

###  Run Test Cases

Use:

```
set serveroutput on;
@RUN_ALL_TRAIN_SYSTEM.sql
```

---

##  **Test Coverage**

Includes tests for:

* Booking CONFIRMED ticket
* Booking WAITLISTED ticket
* Booking after both are full
* Cancellation of CONFIRMED ticket
* Cancellation of WAITLISTED ticket
* Promotion from waitlist
* Waitlist compaction
* Advance booking rule violation
* Invalid passenger or train

---

##  Contributors (Group 10)

Add your group names here:

* **Priyanka Vadivel**
* **Aryaa Prashant Hanamar**
* **Nancy Ketankumar Taswala**

---




