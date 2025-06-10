# GravyJS Demo

A live demonstration of GravyJS - a WYSIWYG editor for React/NextJS applications with configurable variable templates.

## Features

- 📝 Rich text editing with variable placeholders
- 🔄 Dynamic variable population
- 📋 Snippet management
- 🎨 Customizable variable delimiters
- 📱 Responsive design
- 🚀 Built with Vite + React

## Local Development

```bash
npm install
npm run dev
```

## Building

```bash
npm run build
npm run preview
```

## Deployment

This demo is deployed to [gravyjs.com](https://gravyjs.com) using AWS S3 and CloudFront.

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

## GravyJS Package

This demo uses the GravyJS package from the monorepo workspace. In production, it will use the published NPM package.