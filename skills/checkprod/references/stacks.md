# Where Each Item Lives

Use the `FRAMEWORK` and `BACKEND` lines from prod-scan to pick the column, then put each fix where this file says. Paths are from the project root.

## Pages and SEO

| Item | Next.js app router | Next.js pages router | Vite or CRA React | Astro |
|------|--------------------|----------------------|-------------------|-------|
| FE1 404 page | `app/not-found.tsx` | `pages/404.tsx` | a catch-all route plus a `404.html` on the host | `src/pages/404.astro` |
| FE3, FE4 title and description | `export const metadata` or `generateMetadata` per `page.tsx`, a title template in `app/layout.tsx` | `<Head>` from `next/head` per page | `index.html` plus `react-helmet-async` or `document.title` per route | props on the layout, rendered in `<head>` |
| FE5 share image | `app/opengraph-image.png` or `openGraph` and `twitter` in metadata | og meta tags in `<Head>` | og meta tags in `index.html` | og meta tags in the layout head |
| FE6 favicon set | `app/favicon.ico`, `app/icon.svg`, `app/apple-icon.png`, `app/manifest.ts` | files in `public/` linked from `pages/_document.tsx` | files in `public/` linked from `index.html` | files in `public/` linked from the layout |
| FE7, FE8 robots and sitemap | `app/robots.ts`, `app/sitemap.ts` | `public/robots.txt` and `next-sitemap` | `public/robots.txt`, `vite-plugin-sitemap` or a build script | `public/robots.txt`, `@astrojs/sitemap` |
| FE10 viewport | added by Next, override with `export const viewport` | added by Next | `index.html` | layout head |
| FE12 loading | `loading.tsx` per segment and Suspense | component state with a skeleton | component state with a skeleton | islands render server side, skeletons only in client islands |
| Public env prefix (BE1) | `NEXT_PUBLIC_` | `NEXT_PUBLIC_` | `VITE_` or `REACT_APP_` | `PUBLIC_` |
| Server code | `app/**/route.ts`, server actions, `middleware.ts` | `pages/api/**`, `middleware.ts` | a separate API server | `src/pages/**/*.ts` endpoints, `src/middleware.ts` |
| Security headers (BE20) | `headers()` in `next.config.js` or the host | `headers()` in `next.config.js` | host config (`vercel.json`, `netlify.toml`, `_headers`) | host config or middleware |

| Item | SvelteKit | Nuxt | Remix | Plain HTML |
|------|-----------|------|-------|------------|
| FE1 404 page | `src/routes/+error.svelte` | `error.vue` | a root `ErrorBoundary` and a splat route | `404.html` |
| FE3, FE4 title and description | `<svelte:head>` per `+page.svelte` | `useHead` or `useSeoMeta` per page | `export const meta` per route | `<title>` and meta tags per file |
| FE5 share image | og tags in `<svelte:head>` | `useSeoMeta` with `ogImage` | og entries in `meta` | og meta tags per file |
| FE6 favicon set | files in `static/`, linked from `src/app.html` | files in `public/`, `app.head` in `nuxt.config` | files in `public/`, `links` export in `app/root.tsx` | files next to the pages |
| FE7, FE8 robots and sitemap | `static/robots.txt`, `src/routes/sitemap.xml/+server.ts` | `public/robots.txt`, `@nuxtjs/sitemap` | `public/robots.txt`, a `sitemap[.]xml.tsx` resource route | `robots.txt` and `sitemap.xml` files |
| FE10 viewport | `src/app.html` | added by Nuxt | `app/root.tsx` | each page head |
| FE12 loading | `{#await}` blocks and `+page.ts` streaming | `useFetch` pending state | `useNavigation` and `defer` | no async data usually |
| Public env prefix (BE1) | `PUBLIC_` | `NUXT_PUBLIC_` and `runtimeConfig.public` | anything returned from a loader | anything in the page |
| Server code | `+server.ts`, `+page.server.ts`, `hooks.server.ts` | `server/api/**`, `server/middleware/**` | loaders and actions in `app/routes/**` | none |
| Security headers (BE20) | `hooks.server.ts` or the host | `nuxt-security` or route rules | `entry.server.tsx` or the host | host config |

## Backends

| Item | Supabase | Firebase |
|------|----------|----------|
| BE1 keys | the anon key is public by design. The service role key stays server side only | the web config `apiKey` is public by design. Admin SDK credentials stay server side only |
| BE2 data rules | `alter table ... enable row level security` and owner policies in `supabase/migrations/*.sql`, then the security advisor | `firestore.rules` or `database.rules.json`, tested with the emulator |
| BE7 rate limits | built in limits on auth, set in the dashboard. Add limits in edge functions and your own API | App Check plus limits in Cloud Functions |
| BE8 storage | private buckets in `storage.buckets`, policies on `storage.objects`, `createSignedUrl` | `storage.rules` with owner checks, short lived download URLs |
| BE13 field tampering | column privileges, check constraints, triggers or a server function for role, price and status | rules that compare `request.resource.data` with `resource.data` for protected fields |
| BE17 sessions | `@supabase/ssr` cookie sessions on the server | Firebase Auth with session cookies on the server for SSR |
