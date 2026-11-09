Database Audit Report v1
Purpose
This document records findings, observations, and improvement opportunities identified during the continued development of the NomadStay database.

The audit was performed after the original Scrum project was completed and before development of the final portfolio website.

Audit Summary
Architecture Assessment
Database Architecture: 8.8 / 10

The overall schema is well structured and does not require redesign.

The database supports:

User management
Profiles and preferences
Accommodation management
Room management
Bookings
Payments
Invoices
Reviews
Favorites
Workspace bookings
Digital nomad functionality
Strengths
Requirements Traceability
The project demonstrates a complete development chain:

Interviews → User Stories → BDD Scenarios → ER Models → SQL Database → Query Wireframes → UI Design → Future Website

Digital Nomad Features
The database supports:

WiFi speeds
Coworking distance
Workspace booking
External monitors
Ergonomic chairs
Long-stay discounts
Good Database Design
Most core entities are normalized and correctly separated.

Examples:

boende
rum
bokning
betalning
faktura
recension
favorit
arbetsplats
Findings
F01 - Incomplete Cost Breakdown
Priority: High

Bookings 1-2 contain detailed cost records.

Bookings 3-6 contain booking totals but do not contain corresponding cost rows.

Impact:

Reduced transparency
Harder invoice generation
Weaker reporting
F02 - Pricing Inconsistency
Priority: High

Booking 1 contains a cost breakdown that does not match the stored booking total.

This requires further investigation.

F03 - Duplicate Phone Storage
Priority: Medium

Phone numbers currently exist in both:

anvandare.telefon
profil.telefonnummer
Future versions should use one authoritative source.

F04 - Availability Logic
Priority: Medium

Room availability currently depends on both:

room availability flag
booking dates
Long-term improvements may be required.

F05 - WiFi Verification
Priority: Medium

The interviews consistently identified verified WiFi as one of the most important requirements.

The database currently stores WiFi speed but does not include any verification mechanism.

Dataset Assessment
Current dataset functions primarily as a demonstration dataset.

Current record counts:

Users: 8
Profiles: 5
Accommodations: 8
Rooms: 16
Bookings: 6
Reviews: 2
Payments: 6
Workspaces: 10
Next Development Phase
Database Stabilization
Resolve pricing inconsistencies
Complete missing cost breakdown records
Review duplicate fields
Review availability strategy
Data Enrichment
Add more accommodations
Add more rooms
Add more bookings
Add more reviews
Website Development
Planned MVP:

Homepage
Search Results
Accommodation Details
Booking Flow
Payment Flow
User Profile
Admin Dashboard
Status
Audit Version 1 - In Progress
