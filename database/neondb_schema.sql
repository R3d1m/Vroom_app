-- ==============================================================================
-- VROOM: On-the-Go Real Ride Sharing Platform — NeonDB (PostgreSQL) Schema
-- Optimized for Neon Serverless PostgreSQL with JSONB Polyline & Geospatial support
-- ==============================================================================

-- 1. Enable required PostgreSQL extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 2. Clean Existing Tables (if re-running)
-- ==============================================================================
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS bookings CASCADE;
DROP TABLE IF EXISTS sub_requests CASCADE;
DROP TABLE IF EXISTS group_trip_requests CASCADE;
DROP TABLE IF EXISTS ride_posts CASCADE;
DROP TABLE IF EXISTS vehicles CASCADE;
DROP TABLE IF EXISTS locations CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ==============================================================================
-- 3. USERS TABLE
-- ==============================================================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL, -- bcrypt hashed password
    phone VARCHAR(20) UNIQUE NOT NULL,
    avatar_url TEXT,
    university_or_org VARCHAR(150),
    nid_status VARCHAR(20) DEFAULT 'verified' CHECK (nid_status IN ('unverified', 'pending', 'verified', 'rejected')),
    student_id_status VARCHAR(20) DEFAULT 'verified' CHECK (student_id_status IN ('unverified', 'verified')),
    rating_avg NUMERIC(3, 2) DEFAULT 5.00,
    total_trips INT DEFAULT 0,
    active_mode VARCHAR(20) DEFAULT 'passenger' CHECK (active_mode IN ('passenger', 'rider')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 4. VEHICLES TABLE (Rider Vehicle Registration)
-- ==============================================================================
CREATE TABLE vehicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rider_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    vehicle_type VARCHAR(20) NOT NULL CHECK (vehicle_type IN ('Motorcycle', 'Car')),
    registration_number VARCHAR(50) NOT NULL,
    model_name VARCHAR(100) NOT NULL,
    documents_verified BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 5. LOCATIONS TABLE (Standard Hubs & Campus Stops)
-- ==============================================================================
CREATE TABLE locations (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    latitude NUMERIC(10, 7) NOT NULL,
    longitude NUMERIC(10, 7) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 6. RIDE POSTS TABLE (Scheduled Rides with Multi-Route Corridors)
-- ==============================================================================
CREATE TABLE ride_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rider_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    origin_id VARCHAR(50) NOT NULL REFERENCES locations(id),
    destination_id VARCHAR(50) NOT NULL REFERENCES locations(id),
    
    -- Primary Route Polylines & Details
    primary_route_name VARCHAR(255) NOT NULL,
    primary_route_via VARCHAR(255) NOT NULL,
    primary_polyline JSONB NOT NULL, -- Array of [lat, lng] coordinates
    primary_distance_km NUMERIC(5, 2) NOT NULL,
    primary_duration_mins INT NOT NULL,
    
    -- Alternate Corridors (Checked/Unchecked by Rider)
    alternate_routes JSONB DEFAULT '[]'::jsonb, -- Array of route objects with isSelected flag
    detour_tolerance_km NUMERIC(4, 2) DEFAULT 1.50,
    
    -- Schedule & Pricing
    departure_time TIMESTAMPTZ NOT NULL,
    total_seats INT NOT NULL DEFAULT 1,
    available_seats INT NOT NULL DEFAULT 1,
    fare_per_seat NUMERIC(10, 2) NOT NULL,
    
    -- Vehicle info snapshot
    vehicle_type VARCHAR(20) NOT NULL,
    vehicle_plate VARCHAR(50) NOT NULL,
    vehicle_model VARCHAR(100) NOT NULL,
    
    status VARCHAR(20) DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 7. GROUP TRIP REQUESTS TABLE (Passenger Broadcast Engine)
-- ==============================================================================
CREATE TABLE group_trip_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    passenger_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pickup_id VARCHAR(50) NOT NULL REFERENCES locations(id),
    dropoff_id VARCHAR(50) NOT NULL REFERENCES locations(id),
    scheduled_departure TIMESTAMPTZ NOT NULL,
    requested_seats INT DEFAULT 1,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'cancelled', 'expired')),
    accepted_ride_post_id UUID REFERENCES ride_posts(id) ON DELETE SET NULL,
    accepted_rider_id UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 8. SUB-REQUESTS TABLE (Individual Targeted Riders for Atomic Auto-Cancellation)
-- ==============================================================================
CREATE TABLE sub_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_trip_request_id UUID NOT NULL REFERENCES group_trip_requests(id) ON DELETE CASCADE,
    ride_post_id UUID NOT NULL REFERENCES ride_posts(id) ON DELETE CASCADE,
    rider_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'auto_cancelled')),
    cancellation_reason TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 9. BOOKINGS TABLE (Confirmed Trips & Verification PIN)
-- ==============================================================================
CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ride_post_id UUID NOT NULL REFERENCES ride_posts(id) ON DELETE CASCADE,
    rider_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    passenger_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pickup_id VARCHAR(50) NOT NULL REFERENCES locations(id),
    dropoff_id VARCHAR(50) NOT NULL REFERENCES locations(id),
    scheduled_time TIMESTAMPTZ NOT NULL,
    fare NUMERIC(10, 2) NOT NULL,
    pin_code VARCHAR(10) NOT NULL, -- 4-Digit Security PIN
    payment_status VARCHAR(20) DEFAULT 'unpaid' CHECK (payment_status IN ('unpaid', 'paid', 'refunded')),
    payment_method VARCHAR(20) DEFAULT 'bKash' CHECK (payment_method IN ('bKash', 'nagad', 'cash')),
    trip_status VARCHAR(20) DEFAULT 'confirmed' CHECK (trip_status IN ('confirmed', 'rider_arrived', 'in_progress', 'completed', 'cancelled')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 10. REVIEWS & RATINGS TABLE
-- ==============================================================================
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    from_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    to_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating NUMERIC(2, 1) NOT NULL CHECK (rating >= 1.0 AND rating <= 5.0),
    review_text TEXT,
    tags TEXT[] DEFAULT ARRAY[]::TEXT[], -- e.g. ARRAY['Punctual', 'Safe Driving']
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 11. INDEXES FOR HIGH-PERFORMANCE ROUTE & SEARCH QUERIES
-- ==============================================================================
CREATE INDEX idx_users_email ON uasers(email);
CREATE INDEX idx_ride_posts_departure ON ride_posts(departure_time);
CREATE INDEX idx_ride_posts_status ON ride_posts(status);
CREATE INDEX idx_ride_posts_origin_dest ON ride_posts(origin_id, destination_id);
CREATE INDEX idx_group_trip_requests_status ON group_trip_requests(status);
CREATE INDEX idx_sub_requests_ride_post ON sub_requests(ride_post_id);
CREATE INDEX idx_bookings_passenger ON bookings(passenger_id);
CREATE INDEX idx_bookings_rider ON bookings(rider_id);

-- ==============================================================================
-- 12. SEED DATA (CUET, CU, Premier University & Chittagong Corridors)
-- ==============================================================================

-- A. Seed Users (Password for all demo accounts: 'password123')
INSERT INTO users (id, name, email, password_hash, phone, university_or_org, nid_status, student_id_status, rating_avg, total_trips, active_mode)
VALUES
('a1111111-1111-1111-1111-111111111111', 'Md. Redwan Mahmud', 'redwan@cuet.ac.bd', crypt('password123', gen_salt('bf')), '+880 1712-345678', 'CSE, CUET (ID: 2204055)', 'verified', 'verified', 4.95, 42, 'passenger'),
('b2222222-2222-2222-2222-222222222222', 'Imtiaj Uddin', 'imtiaj@premieruniv.edu', crypt('password123', gen_salt('bf')), '+880 1819-223344', 'Premier University (PU)', 'verified', 'verified', 4.88, 56, 'rider'),
('c3333333-3333-3333-3333-333333333333', 'Mobtasim Islam Anas', 'anas@cu.ac.bd', crypt('password123', gen_salt('bf')), '+880 1911-556677', 'University of Chittagong (CU)', 'verified', 'verified', 4.92, 84, 'rider'),
('d4444444-4444-4444-4444-444444444444', 'Syed Juman Al Mahmoud', 'juman@cuet.ac.bd', crypt('password123', gen_salt('bf')), '+880 1622-778899', 'CSE, CUET (ID: 2204060)', 'verified', 'verified', 4.96, 31, 'rider');

-- B. Seed Vehicles
INSERT INTO vehicles (rider_id, vehicle_type, registration_number, model_name, documents_verified)
VALUES
('b2222222-2222-2222-2222-222222222222', 'Motorcycle', 'Chatto Metro-Ha 139396', 'Honda CB Hornet 160R', TRUE),
('c3333333-3333-3333-3333-333333333333', 'Motorcycle', 'Chatta Metro-Ha 188841', 'Suzuki Gixxer SF', TRUE),
('d4444444-4444-4444-4444-444444444444', 'Car', 'Chatto Metro-Ga 112233', 'Toyota Corolla Axio', TRUE);

-- C. Seed Locations
INSERT INTO locations (id, name, description, latitude, longitude)
VALUES
('loc_cuet', 'CUET Campus (Main Gate)', 'Chittagong University of Engineering and Technology, Raozan', 22.4601, 91.9711),
('loc_gec', 'GEC Circle', 'GEC Intersection, Nasirabad, Chattogram', 22.3592, 91.8215),
('loc_2nogate', '2 No. Gate (Sholoshohor)', 'Sholoshohor 2 No. Gate, CDA Avenue', 22.3685, 91.8266),
('loc_agrabad', 'Agrabad Commercial Area', 'Badamtoli Mor, Agrabad C/A', 22.3275, 91.8123),
('loc_oxygen', 'Oxygen Intersection', 'Oxygen Mor, Hathazari Road', 22.3995, 91.8152),
('loc_cu', 'Chittagong University (Zero Point)', 'University of Chittagong, Hathazari', 22.4716, 91.7877),
('loc_muradpur', 'Muradpur Mor', 'Muradpur Intersection, Arakan Road', 22.3654, 91.8412),
('loc_newmarket', 'New Market Mor', 'Kotwali, Chattogram', 22.3352, 91.8324),
('loc_pahartali', 'Pahartali Railway Station', 'Pahartali, Chattogram', 22.3580, 91.7770);

-- D. Seed Ride Posts (with Primary & Alternate Corridors)
INSERT INTO ride_posts (
    id, rider_id, origin_id, destination_id,
    primary_route_name, primary_route_via, primary_polyline, primary_distance_km, primary_duration_mins,
    alternate_routes, detour_tolerance_km,
    departure_time, total_seats, available_seats, fare_per_seat,
    vehicle_type, vehicle_plate, vehicle_model, status
)
VALUES
(
    'e5555555-5555-5555-5555-555555555551',
    'b2222222-2222-2222-2222-222222222222',
    'loc_cuet',
    'loc_gec',
    'Kaptai Highway → Muradpur → 2 No Gate',
    'Via Kaptai Rd & CDA Ave',
    '[[22.4601, 91.9711], [22.4350, 91.9300], [22.4050, 91.8850], [22.3820, 91.8540], [22.3654, 91.8412], [22.3685, 91.8266], [22.3592, 91.8215]]'::jsonb,
    24.50,
    45,
    '[{"id": "alt_bayezid", "name": "Via Oxygen & Bayezid Bypass", "viaRoadName": "Via Oxygen - Bayezid Link", "distanceKm": 26.2, "durationMinutes": 48, "isSelected": true, "polyline": [[22.4601, 91.9711], [22.4350, 91.9300], [22.3995, 91.8152], [22.3810, 91.7980], [22.3592, 91.8215]]}]'::jsonb,
    2.00,
    NOW() + INTERVAL '1 day',
    1,
    1,
    120.00,
    'Motorcycle',
    'Chatto Metro-Ha 139396',
    'Honda CB Hornet',
    'scheduled'
),
(
    'e5555555-5555-5555-5555-555555555552',
    'c3333333-3333-3333-3333-333333333333',
    'loc_oxygen',
    'loc_agrabad',
    '2 No Gate → GEC → Tigerpass',
    'Via CDA Avenue & Tigerpass',
    '[[22.3995, 91.8152], [22.3685, 91.8266], [22.3592, 91.8215], [22.3480, 91.8160], [22.3390, 91.8140], [22.3275, 91.8123]]'::jsonb,
    12.80,
    30,
    '[{"id": "alt_port", "name": "Via Pahartali & Port Connecting Road", "viaRoadName": "Via Port Connecting Road", "distanceKm": 14.1, "durationMinutes": 32, "isSelected": true, "polyline": [[22.3995, 91.8152], [22.3580, 91.7770], [22.3410, 91.7820], [22.3275, 91.8123]]}]'::jsonb,
    1.50,
    NOW() + INTERVAL '1 day 1 hour',
    1,
    1,
    80.00,
    'Motorcycle',
    'Chatta Metro-Ha 188841',
    'Suzuki Gixxer SF',
    'scheduled'
);
