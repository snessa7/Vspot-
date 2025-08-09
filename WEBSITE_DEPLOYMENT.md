# Website & Privacy Policy Deployment Guide

## Overview
This document outlines the setup for the ClipboardAppBeta landing page and privacy policy hosted on Netlify with GitHub integration.

## Website Structure
```
website/
├── index.html          # Landing page
├── privacy.html        # Privacy policy page
├── styles.css          # Styling
├── assets/            # Images, icons, screenshots
│   ├── app-icon.png
│   ├── screenshots/
│   └── favicon.ico
└── netlify.toml       # Netlify configuration
```

## Netlify Deployment Setup

### 1. GitHub Repository Configuration
- Push code to GitHub repository
- Keep website files in `/website` directory
- Netlify will auto-deploy from main branch

### 2. Netlify Configuration
1. Connect GitHub repository to Netlify
2. Set build settings:
   - Base directory: `website`
   - Build command: (none for static site)
   - Publish directory: `website`
3. Configure custom domain (optional)
4. Enable automatic deploys from main branch

### 3. Privacy Policy Requirements
The privacy policy must include:
- Data collection practices (local-only storage)
- Clipboard monitoring explanation
- No cloud transmission disclosure
- User rights and data deletion
- Contact information
- Last updated date

### 4. Landing Page Features
- App description and key features
- Download links (Mac App Store)
- Screenshots showcasing menubar functionality
- Privacy policy link (required for App Store)
- Support/contact information
- System requirements (macOS 13.0+)

## Continuous Deployment Workflow
1. Make changes to website files locally
2. Commit changes to GitHub
3. Push to main branch
4. Netlify automatically deploys within minutes
5. Verify deployment at Netlify dashboard

## App Store Integration
- Privacy Policy URL: `https://[your-domain].netlify.app/privacy.html`
- Support URL: `https://[your-domain].netlify.app/#support`
- Marketing URL: `https://[your-domain].netlify.app`

## Important Notes
- Privacy policy URL must be live before App Store submission
- Keep privacy policy updated with app changes
- Test all links before App Store submission
- Consider adding analytics (privacy-compliant) to track visits