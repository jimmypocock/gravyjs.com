# GravyJS Demo

A live demonstration of GravyJS - a WYSIWYG editor for React/NextJS applications with configurable variable templates.

## Features

- 📝 Rich text editing with variable placeholders
- 🔄 Dynamic variable population
- 📋 Snippet management
- 🎨 Customizable variable delimiters
- 📱 Responsive design
- 🚀 Built with Vite + React
- 📊 Google Analytics integration

## Local Development

### Setup

```bash
npm install
npm run setup:env  # Set up environment variables
```

Edit `.env` and add your Google Analytics ID:
```env
VITE_GA_MEASUREMENT_ID=G-YOUR-ID-HERE
```

### Run Development Server

```bash
npm run dev
```

## Building

```bash
npm run build
npm run preview
```

## Deployment

This demo is deployed to [gravyjs.com](https://gravyjs.com) using AWS S3 and CloudFront.

**Note:** The Google Analytics ID from your `.env` file will be included in the production build during deployment.

### Deployment

#### From gravyjs-demo directory:
```bash
npm run setup    # One-time infrastructure setup
npm run deploy   # Build and deploy to S3/CloudFront
```

#### From gravyprompts.com root:
```bash
npm run demo:setup    # One-time infrastructure setup
npm run demo:deploy   # Build and deploy to S3/CloudFront
```

The setup command creates the S3 bucket and configures it for static hosting.
The deploy command builds the app, syncs to S3, and invalidates CloudFront cache.

## Environment Variables

The following environment variables are supported:

| Variable | Description | Required |
|----------|-------------|----------|
| `VITE_GA_MEASUREMENT_ID` | Google Analytics Measurement ID | No |

## GravyJS Package

This demo uses the GravyJS package from the monorepo workspace. In production, it will use the published NPM package.