# Standard Architecture Patterns

Reference patterns extracted from `/k/tb/DXPortal` and `/k/quantumapi`.

---

## .NET Clean Architecture

### Layer Structure

```
{ProjectName}.Domain          → Entities, Value Objects, Domain Events, Enums (zero dependencies)
{ProjectName}.Application     → Use Cases, CQRS/MediatR, Interfaces, DTOs, Validation
{ProjectName}.Infrastructure  → EF Core, External Services, Crypto, Repos implementation
{ProjectName}.Api             → Controllers, Middleware, DI, Filters (entry point)
{ProjectName}.Tests           → Unit + Integration tests (xUnit, Moq, FluentAssertions)
```

### Solution File Layout

```
src/backend/webapi/
├── {ProjectName}.sln
├── Directory.Build.props        ← Shared build settings (nullable, implicit usings, etc.)
├── Directory.Packages.props     ← Central package version management
├── src/
│   ├── {ProjectName}.Domain/
│   │   ├── Entities/
│   │   ├── ValueObjects/
│   │   ├── Events/
│   │   ├── Enums/
│   │   └── Exceptions/
│   ├── {ProjectName}.Application/
│   │   ├── Common/
│   │   │   ├── Interfaces/
│   │   │   ├── Behaviours/       ← MediatR pipeline behaviours
│   │   │   └── Exceptions/
│   │   ├── {Module}/
│   │   │   ├── Commands/
│   │   │   ├── Queries/
│   │   │   └── DTOs/
│   │   └── DependencyInjection.cs
│   ├── {ProjectName}.Infrastructure/
│   │   ├── Persistence/
│   │   │   ├── {ProjectName}DbContext.cs
│   │   │   ├── Configurations/   ← EF Core entity configs
│   │   │   └── Migrations/
│   │   ├── Services/
│   │   └── DependencyInjection.cs
│   └── {ProjectName}.Api/
│       ├── Controllers/
│       ├── Middleware/
│       ├── Filters/
│       ├── Program.cs
│       └── appsettings.json
└── tests/
    ├── {ProjectName}.UnitTests/
    ├── {ProjectName}.IntegrationTests/
    └── {ProjectName}.ArchTests/   ← Architecture fitness tests (NetArchTest)
```

### Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Interface | `I` prefix + PascalCase | `IUserRepository` |
| Class | PascalCase | `UserService` |
| Method | PascalCase verb | `CreateUser`, `GetUserById` |
| Property | PascalCase | `CreatedAt` |
| Private field | `_camelCase` | `_userRepository` |
| Parameter | camelCase | `userId` |
| Constant | PascalCase | `MaxRetryCount` |
| DTO | `Dto` suffix | `UserDto` |
| Command | `Command` suffix | `CreateUserCommand` |
| Query | `Query` suffix | `GetUserByIdQuery` |
| Handler | `Handler` suffix | `CreateUserCommandHandler` |

### Key Packages (.NET 10)

```xml
<!-- Application -->
<PackageReference Include="MediatR" Version="12.*" />
<PackageReference Include="FluentValidation.DependencyInjectionExtensions" Version="11.*" />
<PackageReference Include="Mapster" Version="7.*" />

<!-- Infrastructure -->
<PackageReference Include="Microsoft.EntityFrameworkCore" Version="10.*" />
<PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="10.*" />

<!-- API -->
<PackageReference Include="Microsoft.AspNetCore.OpenApi" Version="10.*" />
<PackageReference Include="Scalar.AspNetCore" Version="2.*" />

<!-- Tests -->
<PackageReference Include="xunit" Version="2.*" />
<PackageReference Include="Moq" Version="4.*" />
<PackageReference Include="FluentAssertions" Version="7.*" />
<PackageReference Include="Testcontainers.PostgreSql" Version="4.*" />
<PackageReference Include="NetArchTest.Rules" Version="1.*" />
<PackageReference Include="coverlet.collector" Version="6.*" />
```

### Code Coverage

- Minimum: **75%** (enforced in CI)
- Target: **80%+**
- Exempt: DTOs, trivial constructors, generated migration code
- Tool: `coverlet` + `reportgenerator`

---

## React + Vite Frontend

### Directory Structure

```
src/frontend/
├── package.json
├── vite.config.ts
├── tsconfig.json
├── index.html
├── public/
└── src/
    ├── main.tsx
    ├── App.tsx
    ├── assets/
    ├── components/
    │   ├── ui/                  ← shadcn/ui components (auto-generated)
    │   └── shared/              ← Project-wide shared components
    ├── features/
    │   └── {module}/
    │       ├── components/
    │       ├── hooks/
    │       ├── pages/
    │       └── api.ts
    ├── lib/
    │   ├── api.ts               ← Axios/fetch client
    │   ├── auth.ts
    │   └── utils.ts
    ├── hooks/                   ← Global hooks
    ├── store/                   ← Global state (Zustand)
    └── types/                   ← Shared TypeScript types
```

### Key Packages (pnpm only)

```json
{
  "dependencies": {
    "react": "^19",
    "react-dom": "^19",
    "react-router-dom": "^7",
    "@tanstack/react-query": "^5",
    "zustand": "^5",
    "axios": "^1",
    "zod": "^3",
    "react-hook-form": "^7",
    "@hookform/resolvers": "^3"
  },
  "devDependencies": {
    "vite": "^6",
    "@vitejs/plugin-react": "^4",
    "typescript": "^5",
    "tailwindcss": "^4",
    "vitest": "^3",
    "@testing-library/react": "^16"
  }
}
```

---

## Terraform Infrastructure (Azure)

### Module Pattern

```
infrastructure/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   └── prod/
├── modules/
│   ├── 001_base/              ← Resource groups, Key Vault, Log Analytics
│   ├── 002_database/          ← PostgreSQL Flexible Server
│   ├── 003_container_apps/    ← ACA or AKS
│   ├── 004_networking/        ← VNet, subnets, NSGs
│   └── 005_frontend_cdn/      ← Static Web App or CDN
└── shared/
    ├── providers.tf
    └── versions.tf
```

### Provider Versions

```hcl
terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
  }
}
```

---

## .NET Aspire (Local Dev)

### AppHost Structure

```
src/
└── {ProjectName}.AppHost/
    ├── {ProjectName}.AppHost.csproj
    └── Program.cs
```

### Program.cs Pattern

```csharp
var builder = DistributedApplication.CreateBuilder(args);

var postgres = builder.AddPostgres("postgres")
    .AddDatabase("{projectname}db");

var api = builder.AddProject<Projects.{ProjectName}_Api>("api")
    .WithReference(postgres);

builder.AddNpmApp("frontend", "../frontend", "dev")
    .WithHttpEndpoint(port: 5173, env: "VITE_PORT")
    .WithExternalHttpEndpoints();

builder.Build().Run();
```

---

## GitHub Actions CI/CD

### Workflow Files

```
.github/
└── workflows/
    ├── backend-ci.yml         ← Build, test, coverage check
    ├── frontend-ci.yml        ← Build, lint, type-check
    ├── infrastructure-ci.yml  ← terraform plan (PR only)
    └── deploy-{env}.yml       ← Deploy on merge to main/release
```

### Coverage Gate (backend-ci.yml excerpt)

```yaml
- name: Run tests with coverage
  run: dotnet test --collect:"XPlat Code Coverage" --results-directory ./coverage

- name: Check coverage threshold
  run: |
    dotnet tool install -g dotnet-reportgenerator-globaltool
    reportgenerator -reports:./coverage/**/*.xml -targetdir:./coverage/report -reporttypes:JsonSummary
    COVERAGE=$(jq '.summary.linecoverage' ./coverage/report/Summary.json)
    echo "Coverage: $COVERAGE%"
    if (( $(echo "$COVERAGE < 75" | bc -l) )); then
      echo "Coverage $COVERAGE% is below minimum 75%"
      exit 1
    fi
```

---

## GitHub Issue Governance

Every task MUST be tracked as a GitHub Issue before any code is written.

### Required Issue Fields

1. **Title** — Clear and actionable
2. **Labels** — At minimum: `layer:*`, `type:*`, `priority:*`
3. **Milestone** — Which delivery phase
4. **Acceptance criteria** — What "done" looks like

### Standard Label Set

```bash
# Layer labels
gh label create "layer:frontend"        --color "0075ca"
gh label create "layer:backend"         --color "0075ca"
gh label create "layer:infrastructure"  --color "0075ca"
gh label create "layer:database"        --color "0075ca"
gh label create "layer:auth"            --color "0075ca"
gh label create "layer:ci-cd"           --color "0075ca"
gh label create "layer:documentation"   --color "0075ca"

# Type labels
gh label create "type:feature"          --color "a2eeef"
gh label create "type:bug"              --color "d73a4a"
gh label create "type:task"             --color "e4e669"
gh label create "type:spike"            --color "ededed"

# Priority labels
gh label create "priority:critical"     --color "b60205"
gh label create "priority:high"         --color "d93f0b"
gh label create "priority:medium"       --color "fbca04"
gh label create "priority:low"          --color "0e8a16"
```
