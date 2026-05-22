create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  phone text not null default '',
  email text not null default '',
  city text not null default 'Indore',
  blood_group text,
  allergies text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.doctors (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  specialty text not null,
  experience_years int not null default 0,
  degree text not null default '',
  fee int not null default 0,
  rating numeric(2,1) not null default 4.5,
  reviews int not null default 0,
  next_slot text not null default '',
  hospital text not null default '',
  area text not null default '',
  is_online boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.hospitals (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  area text not null,
  distance_km numeric(5,2) not null default 0,
  is_open boolean not null default true,
  has_ayushman boolean not null default false,
  phone text not null default '',
  latitude double precision,
  longitude double precision,
  created_at timestamptz not null default now()
);

create table if not exists public.jan_aushadhi_kendras (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  area text not null,
  distance_km numeric(5,2) not null default 0,
  phone text not null default '',
  is_open boolean not null default true,
  latitude double precision,
  longitude double precision,
  created_at timestamptz not null default now()
);

create table if not exists public.health_schemes (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  department text not null,
  benefit text not null,
  eligibility text not null,
  action text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.emergency_contacts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  phone text not null,
  relation text not null default 'Family',
  is_primary boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  doctor_id uuid not null references public.doctors(id) on delete restrict,
  slot_time timestamptz not null,
  status text not null default 'confirmed',
  reason text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.sos_alerts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  latitude double precision not null,
  longitude double precision not null,
  status text not null default 'sent',
  note text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.cab_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  pickup text not null,
  drop_location text not null,
  pickup_latitude double precision not null,
  pickup_longitude double precision not null,
  status text not null default 'requested',
  driver_name text not null default '',
  eta_minutes int not null default 5,
  created_at timestamptz not null default now()
);

create table if not exists public.health_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  record_type text not null default 'report',
  file_url text,
  notes text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  sender_name text not null,
  body text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.emergency_contacts enable row level security;
alter table public.appointments enable row level security;
alter table public.sos_alerts enable row level security;
alter table public.cab_requests enable row level security;
alter table public.health_records enable row level security;
alter table public.messages enable row level security;
alter table public.doctors enable row level security;
alter table public.hospitals enable row level security;
alter table public.jan_aushadhi_kendras enable row level security;
alter table public.health_schemes enable row level security;

create policy "public read doctors" on public.doctors
  for select using (true);

create policy "public read hospitals" on public.hospitals
  for select using (true);

create policy "public read kendras" on public.jan_aushadhi_kendras
  for select using (true);

create policy "public read schemes" on public.health_schemes
  for select using (true);

create policy "users read own profile" on public.profiles
  for select using (auth.uid() = id);

create policy "users insert own profile" on public.profiles
  for insert with check (auth.uid() = id);

create policy "users update own profile" on public.profiles
  for update using (auth.uid() = id);

create policy "users manage own contacts" on public.emergency_contacts
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "users manage own appointments" on public.appointments
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "users manage own sos" on public.sos_alerts
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "users manage own cabs" on public.cab_requests
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "users manage own records" on public.health_records
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "users read own messages" on public.messages
  for select using (auth.uid() = user_id or user_id is null);

create policy "users update own messages" on public.messages
  for update using (auth.uid() = user_id);

insert into public.doctors
  (name, specialty, experience_years, degree, fee, rating, reviews, next_slot, hospital, area, is_online)
values
  ('Dr. Ananya Sharma', 'Cardiologist', 10, 'MBBS, MD', 800, 4.8, 128, 'Today, 11:30 AM', 'Apollo Hospital', 'Malviya Nagar', true),
  ('Dr. Rohit Verma', 'Orthopedic', 8, 'MBBS, MS', 600, 4.6, 96, 'Today, 02:00 PM', 'Choithram Hospital', 'Manik Bagh', true),
  ('Dr. Neha Patel', 'Pediatrician', 7, 'MBBS, DCH', 500, 4.7, 74, 'Tomorrow, 10:00 AM', 'Bombay Hospital', 'Vijay Nagar', true),
  ('Dr. Karan Mehta', 'Dermatologist', 9, 'MBBS, DDV', 700, 4.5, 68, 'Today, 04:30 PM', 'SkinCare Clinic', 'Palasia', false)
on conflict do nothing;

insert into public.hospitals
  (name, area, distance_km, is_open, has_ayushman, phone, latitude, longitude)
values
  ('Apollo Hospitals', 'Malviya Nagar', 2.4, true, true, '+917314442222', 22.7533, 75.8937),
  ('Choithram Hospital', 'Manik Bagh', 3.1, true, true, '+917312360500', 22.7017, 75.8522),
  ('Bombay Hospital', 'Vijay Nagar', 4.2, true, false, '+917314777777', 22.7539, 75.9044),
  ('Shalby Hospital', 'Race Course', 4.8, true, true, '+917314012345', 22.7244, 75.8781)
on conflict do nothing;

insert into public.jan_aushadhi_kendras
  (name, area, distance_km, phone, is_open, latitude, longitude)
values
  ('Jan Aushadhi Kendra', 'Malviya Nagar', 1.2, '+917300000001', true, 22.7501, 75.8931),
  ('Jan Aushadhi Kendra', 'Vijay Nagar', 2.7, '+917300000002', true, 22.7542, 75.9004),
  ('Jan Aushadhi Kendra', 'Bhawarkuan', 3.4, '+917300000003', true, 22.6928, 75.8677),
  ('Jan Aushadhi Kendra', 'Palasia', 4.1, '+917300000004', true, 22.7245, 75.8840)
on conflict do nothing;

insert into public.health_schemes
  (title, department, benefit, eligibility, action)
values
  ('Ayushman Bharat PM-JAY', 'National Health Authority', 'Cashless care up to Rs. 5,00,000 per family per year.', 'Approved beneficiary database and family criteria.', 'Check eligibility and find empanelled hospitals.'),
  ('Jan Aushadhi Yojana', 'Department of Pharmaceuticals', 'Affordable quality generic medicines.', 'Available to all citizens.', 'Find nearest kendra and call for stock confirmation.'),
  ('CGHS', 'Central Government Health Scheme', 'Healthcare support for eligible central government employees and pensioners.', 'Registered CGHS beneficiaries.', 'Find empanelled clinics and wellness centers.'),
  ('ESIC', 'Employees State Insurance', 'Medical care and insurance benefits for eligible workers.', 'Employees covered under ESIC contribution rules.', 'Locate ESIC hospitals and dispensaries.')
on conflict do nothing;
