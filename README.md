# yo3 Platform - Frontend

Advanced surveillance platform frontend with React + TypeScript + Vite.

## 🚀 Quick Start

```bash
cd frontend
npm install
npm run dev
```

Open [http://localhost:5173](http://localhost:5173) in your browser.

---

## 📚 Documentation

- **[Frontend Guide](./docs/FRONTEND.md)** - React component architecture, features, and development
- **[Contributing](./docs/CONTRIBUTING.md)** - How to contribute to this project
- **[License](./docs/LICENSE)** - MIT License

---

## 🎯 Features

- React 18 + TypeScript + Vite
- Advanced surveillance monitoring
- Real-time video streaming
- Device management interface
- Analytics dashboard
- 20+ React components
- Internationalization (i18n)
- Comprehensive testing setup

---

## 📦 Project Structure

```
frontend/
├── src/
│   ├── components/          # 20+ React components
│   ├── contexts/            # Auth context
│   ├── hooks/               # Custom React hooks
│   ├── lib/                 # Utilities and helpers
│   ├── locales/             # i18n translations
│   ├── styles/              # Global CSS
│   ├── App.tsx              # Main app component
│   └── main.tsx             # Entry point
├── public/                  # Static assets
├── package.json             # Dependencies
├── vite.config.ts           # Build configuration
└── tsconfig.json            # TypeScript config
```

---

## 🛠️ Available Scripts

```bash
npm run dev          # Start development server
npm run build        # Build for production
npm run preview      # Preview production build
npm run lint         # Run ESLint
npm run test         # Run tests
npm run coverage     # Generate test coverage
```

---

## 🌐 Deployment

The frontend is automatically deployed to GitHub Pages:

```
https://hyukiody.github.io/yO3-platform/
```

### Build & Deploy

```bash
npm run build
# Deployment happens automatically via GitHub Actions
```

---

## 📋 License

This project is licensed under the MIT License - see [LICENSE](./docs/LICENSE) for details.

---

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](./docs/CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

---

## 📧 Support

For issues or questions:
- [GitHub Issues](https://github.com/hyukiody/yO3-platform/issues)
- [GitHub Discussions](https://github.com/hyukiody/yO3-platform/discussions)

---

**Repository**: https://github.com/hyukiody/yO3-platform  
**Status**: ✅ Production-Ready
- ✅ Encryption showcase (AES-256-GCM)
- ✅ Video streaming demos
- ⚠️ Backend services (mocked - no real database)

---

### 🐳 Local Deployment (Full Stack)

#### Prerequisites
- Docker & Docker Compose 2.20+
- 8GB RAM, 50GB disk space

#### Deploy with Docker Compose
```bash
# Clone repository
git clone https://github.com/hyukiody/yO3-platform.git
cd yO3-platform

# Start entire platform (databases + all services)
docker-compose -f docker-compose.orchestrator.yml up -d

# Verify services running
docker-compose -f docker-compose.orchestrator.yml ps
```

#### Access Services
- **Frontend**: http://localhost (port 80)
- **Login**: admin / admin123
- **API Documentation**: http://localhost:8091/swagger-ui.html

#### Service Endpoints (Internal)
- Identity Service: http://localhost:8081
- Data Core: http://localhost:9090
- Stream Processing: http://localhost:8082
- Middleware: http://localhost:8091

---

### 💻 Development Mode

```bash
# Frontend development server
cd frontend
npm install
npm run dev
```

Access at `http://localhost:5173`

---

## Project Structure

```
yo3-platform/
├── identity-service/     # JWT auth, license validation (8081)
├── data-core/           # Storage, encryption, quotas (8082)
├── stream-processing/   # Event processing (8083)
├── frontend/            # React dashboard (5173)
├── contracts/           # Shared interfaces
├── docs/               # Documentation
└── docker-compose.yml
```

---

## Documentation

- [Architecture](ARCHITECTURE.md) - System design and patterns
- [Security](SECURITY.md) - Security policies and best practices
- [Deployment](DEPLOYMENT.md) - Production deployment guide
- [Contributing](CONTRIBUTING.md) - Development workflow
- **[First Development Checkpoint](FIRST_DEV_CHECKPOINT.md)** - Containerized testing environment

---

## 🎯 Development Checkpoints

### Checkpoint 1: Containerized Testing Environment (IN PROGRESS)
Complete containerized development environment for testing and distribution.

**Status**: 🚧 IN PROGRESS

**Completed**:
- ✅ Service structure identified (4 microservices + 2 databases)
- ✅ All Dockerfiles created and fixed for multi-module Maven
- ✅ docker-compose.dev.yml orchestration created
- ✅ Development environment configuration (.env.dev)
- ✅ Automation scripts (start-dev.ps1, stop-dev.ps1, test-dev.ps1)
- ✅ Complete documentation (DEV_CHECKPOINT.md)

**In Progress**:
- 🔄 Building container images

**Next Steps**:
- Complete Docker builds
- Test full deployment with `./start-dev.ps1`
- Validate with `./test-dev.ps1`
- Export containers for distribution

📖 **See [FIRST_DEV_CHECKPOINT.md](FIRST_DEV_CHECKPOINT.md) for complete details**

---

## 📚 Documentation

- **[QUICK_START.md](QUICK_START.md)** - 5-minute quick start guide
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Production deployment guide
- **[CHANGELOG.md](CHANGELOG.md)** - Version history
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Development guidelines

> **Note**: Detailed technical documentation is maintained in the private development repository.

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Please follow our [Code of Conduct](CODE_OF_CONDUCT.md) in all interactions.

---

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

---

## 📦 Docker Hub

Pre-built Docker images available:

```bash
docker pull hyukiody/yo3-platform:v1.0.0
docker pull hyukiody/yo3-platform:latest
```

See [DOCKER_PUSH.md](DOCKER_PUSH.md) for publishing instructions.

---

## 🔗 Links

- **🌐 Live Demo**: https://hyukiody.github.io/yO3-platform/
- **📦 GitHub**: https://github.com/hyukiody/yO3-platform
- **🐳 Docker Hub**: https://hub.docker.com/r/hyukiody/yo3-platform

---

**Built with Spring Boot 3.4, React 18, and Docker Compose**

