# SampleMind Frontend — Next.js + Tauri + PWA + WSLg
### Complete UI Development Guide — March 2026

---

## Part 1 — Next.js 14 Setup

### 1.1 — Project Init
```bash
cd ~/projects/samplemind
npx create-next-app@14 frontend \
  --typescript \
  --tailwind \
  --eslint \
  --app \
  --src-dir \
  --import-alias "@/*"
cd frontend
```

### 1.2 — Dependencies
```bash
npm install \
  wavesurfer.js@7.7.0 \
  framer-motion@11.2.0 \
  zustand@4.5.2 \
  @tanstack/react-query@5.40.0 \
  axios@1.7.2 \
  react-hot-toast@2.4.1 \
  lucide-react@0.383.0

# Shadcn/UI
npx shadcn-ui@latest init
# Options: style=Default, baseColor=slate, CSS variables=yes
# Add components:
npx shadcn-ui@latest add button card badge input slider progress toast dialog
```

### 1.3 — next.config.js (with PWA)
```js
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  output: 'standalone',    // Required for Tauri + Docker
  experimental: {
    serverActions: { allowedOrigins: ['localhost:3000', 'localhost:8000'] }
  },
  async rewrites() {
    return [
      { source: '/api/:path*', destination: 'http://localhost:8000/api/:path*' }
    ]
  }
}
module.exports = nextConfig
```

---

## Part 2 — Design System (Tokyo Night Glassmorphism)

### 2.1 — Global CSS (src/app/globals.css)
```css
@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  /* Tokyo Night color palette */
  --bg-primary:    #07050f;
  --bg-secondary:  #1a1b26;
  --bg-tertiary:   #16161e;
  --surface:       rgba(26, 27, 38, 0.7);
  --surface-hover: rgba(36, 37, 54, 0.8);
  --border:        rgba(122, 162, 247, 0.15);
  --border-hover:  rgba(122, 162, 247, 0.35);

  /* Text */
  --text-primary:  #c0caf5;
  --text-secondary:#a9b1d6;
  --text-muted:    #565f89;

  /* Accents */
  --accent-blue:   #7aa2f7;
  --accent-purple: #bb9af7;
  --accent-cyan:   #7dcfff;
  --accent-green:  #9ece6a;
  --accent-yellow: #e0af68;
  --accent-red:    #f7768e;

  /* Glass effect */
  --glass-bg:      rgba(26, 27, 38, 0.6);
  --glass-border:  rgba(122, 162, 247, 0.12);
  --glass-blur:    20px;
}

body {
  background: var(--bg-primary);
  color: var(--text-primary);
  font-family: 'JetBrains Mono', 'Inter', monospace;
}

@layer components {
  .glass-card {
    @apply rounded-xl border backdrop-blur-xl;
    background: var(--glass-bg);
    border-color: var(--glass-border);
    box-shadow: 0 8px 32px rgba(0,0,0,0.3), inset 0 1px 0 rgba(255,255,255,0.05);
    transition: all 0.2s ease;
  }
  .glass-card:hover {
    border-color: var(--border-hover);
    box-shadow: 0 12px 40px rgba(0,0,0,0.4), inset 0 1px 0 rgba(255,255,255,0.08);
    transform: translateY(-2px);
  }
  .glass-card.selected {
    border-color: var(--accent-blue);
    box-shadow: 0 0 0 1px var(--accent-blue), 0 12px 40px rgba(122,162,247,0.15);
  }
  .gradient-text {
    background: linear-gradient(135deg, var(--accent-blue), var(--accent-purple));
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
  }
  .neon-border {
    border: 1px solid var(--accent-cyan);
    box-shadow: 0 0 10px rgba(125, 207, 255, 0.2), inset 0 0 10px rgba(125, 207, 255, 0.05);
  }
  .animated-blob {
    position: fixed;
    border-radius: 50%;
    filter: blur(80px);
    opacity: 0.12;
    animation: blob-float 8s ease-in-out infinite;
    pointer-events: none;
    z-index: 0;
  }
}

@keyframes blob-float {
  0%, 100% { transform: translate(0, 0) scale(1); }
  33%       { transform: translate(30px, -30px) scale(1.05); }
  66%       { transform: translate(-20px, 20px) scale(0.95); }
}
```

### 2.2 — Tailwind Config
`tailwind.config.ts`:
```ts
import type { Config } from 'tailwindcss'

const config: Config = {
  darkMode: 'class',
  content: ['./src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        tokyo: {
          bg:       '#07050f',
          surface:  '#1a1b26',
          base:     '#16161e',
          blue:     '#7aa2f7',
          purple:   '#bb9af7',
          cyan:     '#7dcfff',
          green:    '#9ece6a',
          yellow:   '#e0af68',
          red:      '#f7768e',
          text:     '#c0caf5',
          muted:    '#565f89',
        }
      },
      fontFamily: {
        mono: ['JetBrains Mono', 'Cascadia Code', 'monospace'],
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      backdropBlur: { xl: '20px' },
      animation: {
        'blob-float': 'blob-float 8s ease-in-out infinite',
        'waveform':   'waveform 1.2s ease-in-out infinite',
        'fade-in':    'fadeIn 0.3s ease-out',
        'slide-up':   'slideUp 0.4s ease-out',
      },
      keyframes: {
        'blob-float': {
          '0%, 100%': { transform: 'translate(0,0) scale(1)' },
          '33%':      { transform: 'translate(30px,-30px) scale(1.05)' },
          '66%':      { transform: 'translate(-20px,20px) scale(0.95)' },
        },
        fadeIn:  { from: { opacity: '0' }, to: { opacity: '1' } },
        slideUp: { from: { transform: 'translateY(16px)', opacity: '0' }, to: { transform: 'translateY(0)', opacity: '1' } },
      }
    },
  },
  plugins: [],
}
export default config
```

---

## Part 3 — Core Components

### 3.1 — Animated Background
`src/components/ui/AnimatedBackground.tsx`:
```tsx
export function AnimatedBackground() {
  return (
    <div className="fixed inset-0 overflow-hidden pointer-events-none z-0">
      <div className="animated-blob w-[600px] h-[600px] bg-tokyo-purple -top-32 -left-32"
           style={{ animationDelay: '0s' }} />
      <div className="animated-blob w-[500px] h-[500px] bg-tokyo-blue top-1/2 right-0"
           style={{ animationDelay: '-3s' }} />
      <div className="animated-blob w-[400px] h-[400px] bg-pink-500 bottom-0 left-1/3"
           style={{ animationDelay: '-6s' }} />
    </div>
  )
}
```

### 3.2 — WaveformPlayer Component
`src/components/audio/WaveformPlayer.tsx`:
```tsx
'use client'
import { useEffect, useRef, useState, useCallback } from 'react'
import WaveSurfer from 'wavesurfer.js'
import { Play, Pause, Volume2 } from 'lucide-react'
import { Slider } from '@/components/ui/slider'

interface WaveformPlayerProps {
  audioUrl: string
  sampleName: string
  duration?: number
  bpm?: number
  keySignature?: string
  onEnded?: () => void
}

export function WaveformPlayer({
  audioUrl, sampleName, duration, bpm, keySignature, onEnded
}: WaveformPlayerProps) {
  const containerRef = useRef<HTMLDivElement>(null)
  const wavesurferRef = useRef<WaveSurfer | null>(null)
  const [isPlaying, setIsPlaying]   = useState(false)
  const [isLoaded, setIsLoaded]     = useState(false)
  const [volume, setVolume]         = useState(0.8)
  const [currentTime, setCurrentTime] = useState(0)
  const [totalDuration, setTotalDuration] = useState(duration || 0)

  useEffect(() => {
    if (!containerRef.current) return

    wavesurferRef.current = WaveSurfer.create({
      container: containerRef.current,
      waveColor:     'rgba(122,162,247,0.5)',
      progressColor: 'rgba(122,162,247,1)',
      cursorColor:   '#7dcfff',
      height:        64,
      barWidth:      2,
      barGap:        1,
      barRadius:     2,
      normalize:     true,
    })

    const ws = wavesurferRef.current
    ws.load(audioUrl)
    ws.setVolume(volume)

    ws.on('ready', () => {
      setIsLoaded(true)
      setTotalDuration(ws.getDuration())
    })
    ws.on('audioprocess', () => setCurrentTime(ws.getCurrentTime()))
    ws.on('play',  () => setIsPlaying(true))
    ws.on('pause', () => setIsPlaying(false))
    ws.on('finish', () => { setIsPlaying(false); onEnded?.() })

    return () => { ws.destroy() }
  }, [audioUrl])

  const togglePlay = useCallback(() => {
    wavesurferRef.current?.playPause()
  }, [])

  const handleVolume = useCallback((val: number[]) => {
    const v = val[0]
    setVolume(v)
    wavesurferRef.current?.setVolume(v)
  }, [])

  const formatTime = (s: number) =>
    `${Math.floor(s/60)}:${String(Math.floor(s%60)).padStart(2,'0')}`

  return (
    <div className="glass-card p-4 space-y-3">
      <div className="flex items-center justify-between">
        <span className="text-tokyo-text font-mono text-sm truncate max-w-[60%]">{sampleName}</span>
        <div className="flex gap-2 text-xs text-tokyo-muted">
          {bpm && <span className="text-tokyo-blue">{bpm.toFixed(0)} BPM</span>}
          {keySignature && <span className="text-tokyo-purple">{keySignature}</span>}
        </div>
      </div>

      <div ref={containerRef} className="w-full" />

      <div className="flex items-center gap-3">
        <button
          onClick={togglePlay}
          disabled={!isLoaded}
          className="p-2 rounded-lg bg-tokyo-blue/20 hover:bg-tokyo-blue/30
                     text-tokyo-blue transition-colors disabled:opacity-50"
        >
          {isPlaying ? <Pause size={16} /> : <Play size={16} />}
        </button>

        <span className="text-xs text-tokyo-muted font-mono">
          {formatTime(currentTime)} / {formatTime(totalDuration)}
        </span>

        <div className="flex items-center gap-2 ml-auto">
          <Volume2 size={14} className="text-tokyo-muted" />
          <div className="w-20">
            <Slider
              min={0} max={1} step={0.01}
              value={[volume]}
              onValueChange={handleVolume}
              className="w-full"
            />
          </div>
        </div>
      </div>
    </div>
  )
}
```

### 3.3 — SampleCard Component
`src/components/samples/SampleCard.tsx`:
```tsx
'use client'
import { memo } from 'react'
import { Music, Tag, Clock } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import type { Sample } from '@/types'

interface SampleCardProps {
  sample: Sample
  isSelected: boolean
  onSelect: (id: string) => void
  onPlay: (id: string) => void
}

export const SampleCard = memo(function SampleCard({
  sample, isSelected, onSelect, onPlay
}: SampleCardProps) {
  // Deterministic waveform bars (no randomness — same every render)
  const bars = Array.from({ length: 32 }, (_, i) => {
    const seed = (sample.id.charCodeAt(i % sample.id.length) * 0x9e3779b9 + i * 0x6c62272e) >>> 0
    return 20 + (seed % 80)
  })

  return (
    <div
      className={`glass-card p-4 cursor-pointer group ${isSelected ? 'selected' : ''}`}
      onClick={() => onSelect(sample.id)}
    >
      {/* Header */}
      <div className="flex items-start justify-between mb-3">
        <div className="flex-1 min-w-0">
          <p className="text-tokyo-text text-sm font-medium truncate">{sample.name}</p>
          <p className="text-tokyo-muted text-xs mt-0.5 truncate">{sample.path}</p>
        </div>
        <button
          onClick={(e) => { e.stopPropagation(); onPlay(sample.id) }}
          className="ml-2 p-1.5 rounded-lg bg-tokyo-blue/10 hover:bg-tokyo-blue/25
                     text-tokyo-blue opacity-0 group-hover:opacity-100 transition-all"
        >
          <Music size={14} />
        </button>
      </div>

      {/* Mini waveform */}
      <div className="flex items-end gap-[2px] h-12 mb-3">
        {bars.map((h, i) => (
          <div
            key={i}
            className="flex-1 rounded-sm transition-colors"
            style={{
              height: `${h}%`,
              background: isSelected
                ? `rgba(122,162,247,${0.4 + (h/100)*0.6})`
                : `rgba(122,162,247,${0.15 + (h/100)*0.35})`
            }}
          />
        ))}
      </div>

      {/* Metadata badges */}
      <div className="flex flex-wrap gap-1.5">
        <Badge variant="outline" className="text-tokyo-blue border-tokyo-blue/30 text-xs px-1.5 py-0">
          {sample.bpm?.toFixed(0)} BPM
        </Badge>
        <Badge variant="outline" className="text-tokyo-purple border-tokyo-purple/30 text-xs px-1.5 py-0">
          {sample.key} {sample.mode}
        </Badge>
        {sample.instrument && (
          <Badge variant="outline" className="text-tokyo-green border-tokyo-green/30 text-xs px-1.5 py-0">
            <Tag size={9} className="mr-1" />
            {sample.instrument}
          </Badge>
        )}
        {sample.mood && (
          <Badge variant="outline" className="text-tokyo-yellow border-tokyo-yellow/30 text-xs px-1.5 py-0">
            {sample.mood}
          </Badge>
        )}
      </div>

      {/* AI confidence */}
      {sample.confidence && (
        <div className="mt-2 h-0.5 rounded-full bg-tokyo-surface overflow-hidden">
          <div
            className="h-full bg-gradient-to-r from-tokyo-blue to-tokyo-purple transition-all duration-500"
            style={{ width: `${sample.confidence * 100}%` }}
          />
        </div>
      )}
    </div>
  )
})
```

---

## Part 4 — State Management + API

### 4.1 — Zustand Store
`src/store/useSampleStore.ts`:
```ts
import { create } from 'zustand'
import { devtools } from 'zustand/middleware'
import type { Sample, SearchFilters } from '@/types'

interface SampleStore {
  samples:      Sample[]
  selectedId:   string | null
  playingId:    string | null
  searchQuery:  string
  filters:      SearchFilters
  isLoading:    boolean

  setSamples:     (s: Sample[]) => void
  selectSample:   (id: string | null) => void
  playSample:     (id: string | null) => void
  setSearchQuery: (q: string) => void
  setFilter:      (key: keyof SearchFilters, value: string) => void
  clearFilters:   () => void
}

const defaultFilters: SearchFilters = {
  instrument: '',
  mood: '',
  minBpm: 0,
  maxBpm: 300,
  key: '',
  mode: ''
}

export const useSampleStore = create<SampleStore>()(
  devtools((set) => ({
    samples:     [],
    selectedId:  null,
    playingId:   null,
    searchQuery: '',
    filters:     defaultFilters,
    isLoading:   false,

    setSamples:     (samples) => set({ samples }),
    selectSample:   (selectedId) => set({ selectedId }),
    playSample:     (playingId)  => set({ playingId }),
    setSearchQuery: (searchQuery) => set({ searchQuery }),
    setFilter:      (key, value) => set((s) => ({ filters: { ...s.filters, [key]: value } })),
    clearFilters:   () => set({ filters: defaultFilters }),
  }))
)
```

### 4.2 — API Client
`src/lib/api.ts`:
```ts
import axios from 'axios'
import type { Sample } from '@/types'

const api = axios.create({ baseURL: '/api/v1' })

export const samplemindApi = {
  // Search
  search: (query: string, filters = {}) =>
    api.post<Sample[]>('/search', { query, ...filters }),

  // Library
  getSamples: (page = 0, limit = 50) =>
    api.get<Sample[]>('/samples', { params: { page, limit } }),

  // Tags
  tagFile: (filePath: string) =>
    api.post('/tag/file', { file_path: filePath }),

  tagDirectory: (dirPath: string) =>
    api.post('/tag/directory', { directory_path: dirPath }),

  // AI agent
  agentQuery: (query: string) =>
    api.post('/agent/query', { query }),

  // Stats
  getStats: () => api.get('/stats'),
}

// TanStack Query hooks
import { useQuery, useMutation } from '@tanstack/react-query'

export const useSamples = (page = 0) =>
  useQuery({
    queryKey: ['samples', page],
    queryFn: () => samplemindApi.getSamples(page).then(r => r.data),
    staleTime: 60_000,
  })

export const useSearch = (query: string, filters = {}) =>
  useQuery({
    queryKey: ['search', query, filters],
    queryFn: () => samplemindApi.search(query, filters).then(r => r.data),
    enabled: query.length > 2,
    staleTime: 30_000,
  })

export const useTagFile = () =>
  useMutation({
    mutationFn: (filePath: string) => samplemindApi.tagFile(filePath).then(r => r.data),
  })
```

---

## Part 5 — Tauri Desktop App

### 5.1 — Install Rust + Tauri
```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env
rustup default stable

# Tauri CLI
npm install --save-dev @tauri-apps/cli@1.6
npm install @tauri-apps/api@1.6

# Init Tauri (from frontend/ directory)
npx tauri init
# App name: SampleMind
# Window title: SampleMind AI
# Web assets: ../out  (Next.js static export dir)
# Dev URL: http://localhost:3000
# Dev command: npm run dev
# Build command: npm run build && npm run export
```

### 5.2 — Tauri Configuration
`src-tauri/tauri.conf.json`:
```json
{
  "build": {
    "beforeDevCommand": "npm run dev",
    "beforeBuildCommand": "npm run build",
    "devPath": "http://localhost:3000",
    "distDir": "../out"
  },
  "package": {
    "productName": "SampleMind",
    "version": "0.1.0"
  },
  "tauri": {
    "allowlist": {
      "all": false,
      "fs": {
        "all": true,
        "scope": ["$AUDIO", "$HOME/samples/**", "$HOME/projects/samplemind/data/**"]
      },
      "shell": { "open": true },
      "path": { "all": true }
    },
    "windows": [{
      "title": "SampleMind AI",
      "width": 1400,
      "height": 900,
      "minWidth": 1200,
      "minHeight": 700,
      "resizable": true,
      "fullscreen": false,
      "decorations": true,
      "transparent": false
    }],
    "security": { "csp": null }
  }
}
```

### 5.3 — Tauri Rust Commands
`src-tauri/src/main.rs`:
```rust
#![cfg_attr(all(not(debug_assertions), target_os = "windows"), windows_subsystem = "windows")]

#[tauri::command]
fn scan_directory(path: String) -> Result<Vec<String>, String> {
    use std::path::Path;
    let dir = Path::new(&path);
    if !dir.is_dir() {
        return Err(format!("Not a directory: {}", path));
    }

    let audio_exts = ["wav", "mp3", "flac", "ogg", "aif", "aiff"];
    let mut files = Vec::new();

    if let Ok(entries) = std::fs::read_dir(dir) {
        for entry in entries.flatten() {
            let p = entry.path();
            if let Some(ext) = p.extension().and_then(|e| e.to_str()) {
                if audio_exts.contains(&ext.to_lowercase().as_str()) {
                    files.push(p.to_string_lossy().to_string());
                }
            }
        }
    }
    files.sort();
    Ok(files)
}

#[tauri::command]
fn get_system_info() -> serde_json::Value {
    serde_json::json!({
        "platform": std::env::consts::OS,
        "arch":     std::env::consts::ARCH,
    })
}

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![scan_directory, get_system_info])
        .run(tauri::generate_context!())
        .expect("Error running SampleMind Tauri app");
}
```

### 5.4 — Build Tauri App
```bash
# Development
npx tauri dev

# Production build (creates .AppImage on Linux, .exe on Windows)
npx tauri build

# Output: src-tauri/target/release/bundle/
# Linux: SampleMind_0.1.0_amd64.AppImage
# Linux deb: SampleMind_0.1.0_amd64.deb
```

---

## Part 6 — PWA Configuration

### 6.1 — next.config.js with next-pwa
```bash
npm install next-pwa
```
`next.config.js`:
```js
const withPWA = require('next-pwa')({
  dest: 'public',
  register: true,
  skipWaiting: true,
  disable: process.env.NODE_ENV === 'development',
  runtimeCaching: [
    {
      urlPattern: /^https:\/\/localhost:8000\/api\//,
      handler: 'NetworkFirst',
      options: {
        cacheName: 'api-cache',
        expiration: { maxEntries: 100, maxAgeSeconds: 300 }
      }
    }
  ]
})

module.exports = withPWA({
  reactStrictMode: true,
  output: 'standalone',
})
```

### 6.2 — Web App Manifest
`public/manifest.json`:
```json
{
  "name": "SampleMind AI",
  "short_name": "SampleMind",
  "description": "AI-powered audio sample management",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#07050f",
  "theme_color": "#7aa2f7",
  "orientation": "landscape-primary",
  "icons": [
    { "src": "/icons/icon-192.png", "sizes": "192x192", "type": "image/png", "purpose": "any maskable" },
    { "src": "/icons/icon-512.png", "sizes": "512x512", "type": "image/png", "purpose": "any maskable" }
  ],
  "categories": ["music", "productivity"],
  "shortcuts": [
    { "name": "Search Samples", "url": "/search", "description": "AI semantic search" },
    { "name": "Upload Samples", "url": "/upload", "description": "Add new samples" }
  ]
}
```

### 6.3 — Add to HTML Head
`src/app/layout.tsx`:
```tsx
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'SampleMind AI',
  description: 'AI-powered audio sample management',
  manifest: '/manifest.json',
  themeColor: '#7aa2f7',
  appleWebApp: { capable: true, statusBarStyle: 'black-translucent' },
  viewport: 'width=device-width, initial-scale=1, maximum-scale=1',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="dark">
      <body className="bg-[#07050f] text-[#c0caf5] antialiased min-h-screen">
        {children}
      </body>
    </html>
  )
}
```

---

## Part 7 — WSLg Deployment (ThinkPad)

### 7.1 — Run Next.js GUI from WSL2
WSLg automatically bridges Linux GUI apps to the Windows desktop:
```bash
# Start dev server inside WSL2
cd ~/projects/samplemind/frontend
npm run dev

# Open browser (WSLg auto-opens in Windows)
thorium-browser http://localhost:3000 &

# Or open from Windows browser directly
# http://localhost:3000 works because WSL2 port forwarding is automatic
```

### 7.2 — Run as Native Linux App via Electron (alternative to Tauri)
```bash
# If you want a native WSLg window instead of browser
npm install electron electron-builder --save-dev

# electron/main.js
cat > electron/main.js <<'EOF'
const { app, BrowserWindow } = require('electron')
function createWindow() {
  const win = new BrowserWindow({
    width: 1400, height: 900,
    backgroundColor: '#07050f',
    webPreferences: { nodeIntegration: false, contextIsolation: true }
  })
  win.loadURL('http://localhost:3000')
  win.setMenuBarVisibility(false)
}
app.whenReady().then(createWindow)
EOF
node electron/main.js   # Run — window appears on Windows desktop via WSLg
```

---

## Part 8 — Type Definitions

`src/types/index.ts`:
```ts
export interface Sample {
  id:         string
  name:       string
  path:       string
  instrument: string
  confidence: number
  bpm:        number
  key:        string
  mode:       string
  mood?:      string
  duration?:  number
  fileSize?:  number
  createdAt?: string
  tags?:      string[]
}

export interface SearchFilters {
  instrument: string
  mood:       string
  minBpm:     number
  maxBpm:     number
  key:        string
  mode:       string
}

export interface AgentResponse {
  type:   'search' | 'analysis'
  result: string
  query?: string
  file?:  string
}
```

---

## Quick Start
```bash
cd ~/projects/samplemind/frontend

# Dev mode (browser)
npm run dev

# Tauri desktop app
npx tauri dev

# Production build
npm run build
npx tauri build  # creates .AppImage
```

---

*SampleMind Frontend — Next.js 14 + Tauri + PWA + WSLg — March 2026*
