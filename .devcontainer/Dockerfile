FROM mcr.microsoft.com/vscode/devcontainers/universal:latest

RUN pwsh -NoLogo -NoProfile -Command "Install-Module Pester -RequiredVersion 4.10.1 -AllowClobber -Force -Scope AllUsers -SkipPublisherCheck"
RUN pwsh -NoLogo -NoProfile -Command "Import-Module -Name Pester -Force -Global"
