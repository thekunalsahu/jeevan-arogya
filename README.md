# Jeevan Arogya
App created by Kunal Sahu (0818CL241109)
Karthik KB(0818CL241094)
Kartik sharma(0818CL241095)
jitender prusty(0818CL241088)

Project Video link https://drive.google.com/file/d/1AV0KE_hIUv5cb_WFRpE1GCh6gwNcy2T5/view?usp=drivesdk

A Flutter healthcare assistance app with a polished mobile UI, emergency SOS flows, doctor discovery, hospital and medicine search, appointment screens, Supabase-ready auth, and database schema support.

## Features

- Modern Flutter landing and login experience
- Email OTP auth integration via Supabase and GitHub OTP service
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

## Auth

Enable Email auth in Supabase.

For local web development, set Supabase Auth URL configuration to:

```text
http://127.0.0.1:5173
```

## Vercel

This repo includes `vercel.json` so Vercel builds Flutter Web and serves `build/web`.

The app includes the public Supabase project URL and publishable anon key as a fallback so OTP does not show as unconfigured on Vercel. You can still override them in Vercel Project Settings:

```text
SUPABASE_URL
SUPABASE_ANON_KEY
SUPABASE_REDIRECT_URL
```

For GitHub OTP service integration on Vercel, add this environment variable:

```text
EMAIL_OTP_SERVICE_URL
```

`EMAIL_OTP_SERVICE_URL` should point to your deployed instance of `sauravhathi/otp-service` (example: `https://your-otp-service.vercel.app`).
