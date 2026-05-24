# Jeevan Arogya

A Flutter healthcare assistance app with a polished mobile UI, emergency SOS flows, doctor discovery, hospital and medicine search, appointment screens, Supabase-ready auth, and database schema support.

## Features

- Modern Flutter landing and login experience
- Mobile OTP auth integration via Supabase and Twilio
- Emergency SOS card with animated pulse effect
- Doctor listings, appointment booking UI, hospital discovery, emergency cab UI
- Supabase schema for profiles, doctors, appointments, SOS alerts, cab requests, and supporting data
- Location-gated maps for nearby hospitals, doctors, medicines, and cab flows

## Setup

1. Copy `.env.example` to `.env`.
2. Add your Supabase URL and anon key.
3. Run the SQL in `supabase/schema.sql` inside Supabase SQL Editor.
4. Install packages:

```bash
flutter pub get
```

5. Run locally:

```bash
flutter run -d chrome
```

## Supabase Auth

Enable Phone auth in Supabase and configure Twilio as the SMS provider.

For local web development, set Supabase Auth URL configuration to:

```text
http://127.0.0.1:5173
```

## Vercel

This repo includes `vercel.json` so Vercel builds Flutter Web and serves `build/web`.

Add these environment variables in Vercel Project Settings if you want live Supabase auth/data:

```text
SUPABASE_URL
SUPABASE_ANON_KEY
SUPABASE_REDIRECT_URL
```
