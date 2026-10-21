# Khmer Horror Podcast — Admin Web Dashboard Deployment Guide

## 1. Production Build

From the `admin/` directory:
```bash
npm run build
```
The output will be generated in `admin/dist/`.

---

## 2. Environment Variables Configuration

In your production hosting environment (e.g. Vercel, Netlify, Cloudflare Pages), configure these environment variables:

| Variable | Description | Example |
|---|---|---|
| `VITE_SUPABASE_URL` | Your production Supabase project URL | `https://xyz.supabase.co` |
| `VITE_SUPABASE_ANON_KEY` | Your public anon/publishable key | `eyJhbGciOi...` |

> **Security Warning**: NEVER set `SUPABASE_SERVICE_ROLE_KEY` or `VITE_SERVICE_ROLE_KEY` on the client web application!

---

## 3. Deploying to Vercel

```bash
cd admin
vercel --prod
```
Or connect your GitHub repository to Vercel:
- **Framework Preset**: Vite
- **Root Directory**: `admin`
- **Build Command**: `npm run build`
- **Output Directory**: `dist`

---

## 4. Deploying to Netlify

Create `admin/netlify.toml`:
```toml
[build]
  command = "npm run build"
  publish = "dist"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

---

## 5. Post-Deployment Verification Checklist

1. Access the production URL and verify HTTPS redirection.
2. Log in with an admin account; verify access to stories, episodes, and users.
3. Attempt logging in with a non-admin account; verify redirection to the "Unauthorized Access" screen.
4. Verify cover image upload and MP3 audio preview playback in the browser.
