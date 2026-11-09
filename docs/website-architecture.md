Website Architecture
Purpose
This document describes the planned architecture of the NomadStay web application.

The goal is to transform the existing database project into a functional portfolio website that demonstrates:

Database Design
SQL
Data Management
Requirements Engineering
Web Development
The website will be built on the existing NomadStay MySQL database.

Technology Stack
Backend
Python
Flask
SQLAlchemy
Database
MySQL
Frontend
HTML
CSS
Bootstrap 5
MVP Scope
The first version of the website will include the following pages.

Homepage
Route:

/
Features:

Accommodation search
Featured accommodations
WiFi filters
Coworking filters
Location search
Search Results
Route:

/search
Features:

Accommodation comparison
Filtering
Sorting
WiFi information
Workspace information
Accommodation Details
Route:

/accommodation/<id>
Features:

Accommodation information
Images
Facilities
Properties
Shared spaces
Workspace information
Reviews
Room options
Booking
Route:

/booking/<id>
Features:

Room selection
Guest selection
Price calculation
Discount handling
Payment
Route:

/payment/<id>
Features:

Booking summary
Payment methods
Payment confirmation
User Profile
Route:

/profile
Features:

Profile information
Bookings
Favorites
Reviews
Activity bookings
Workspace bookings
Admin Dashboard
Route:

/admin
Features:

User statistics
Booking statistics
Review statistics
Activity statistics
Workspace booking statistics
Database Integration
The website will use the existing database structure and core entities:

anvandare
profil
boende
rum
bokning
bokning_rum
betalning
recension
favorit
arbetsplats
aktivitetsbokning
Development Order
Phase 1

Flask setup
Database connection
Application structure
Phase 2

Homepage
Search Results
Phase 3

Accommodation Details
Phase 4

Booking Flow
Payment Flow
Phase 5

Profile Page
Phase 6

Admin Dashboard
Current Status
Planning Phase

Database audit completed.

Website development not yet started.
