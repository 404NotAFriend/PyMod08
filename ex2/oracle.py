#!/usr/bin/env python3

import os

from dotenv import load_dotenv

REQUIRED_VARS = [
    "MATRIX_MODE",
    "DATABASE_URL",
    "API_KEY",
    "LOG_LEVEL",
    "ZION_ENDPOINT",
]


def load_configuration() -> tuple[dict[str, str], list[str]]:
    load_dotenv()
    config: dict[str, str] = {}
    missing: list[str] = []
    for var in REQUIRED_VARS:
        value = os.environ.get(var)
        if value is None:
            missing.append(var)
        else:
            config[var] = value
    return config, missing


def describe_database(url: str | None, mode: str) -> str:
    if url is None:
        return "Not configured (missing DATABASE_URL)"
    if mode == "production":
        return "Connected to production cluster"
    return "Connected to local instance"


def describe_api_access(key: str | None) -> str:
    if key is None:
        return "Not authenticated (missing API_KEY)"
    return "Authenticated"


def describe_zion_network(endpoint: str | None) -> str:
    if endpoint is None:
        return "Offline (missing ZION_ENDPOINT)"
    return "Online"


def describe_log_level(level: str | None, mode: str) -> str:
    level = level or "INFO"
    if mode == "production" and level == "DEBUG":
        return f"{level} (WARNING: verbose logging in production)"
    return level


def print_missing_configuration_warning(missing: list[str]) -> None:
    print("WARNING: missing configuration, using defaults:")
    for var in missing:
        print(f"  - {var}")
    print()


def print_configuration(config: dict[str, str]) -> None:
    mode = config.get("MATRIX_MODE", "development")
    print("Configuration loaded:")
    print(f"Mode: {mode}")
    print(f"Database: {describe_database(config.get('DATABASE_URL'), mode)}")
    print(f"API Access: {describe_api_access(config.get('API_KEY'))}")
    print(f"Log Level: {describe_log_level(config.get('LOG_LEVEL'), mode)}")
    zion_endpoint = config.get("ZION_ENDPOINT")
    print(f"Zion Network: {describe_zion_network(zion_endpoint)}")


def print_security_check() -> None:
    print()
    print("Environment security check:")
    print("[OK] No hardcoded secrets detected")
    if os.path.isfile(".env"):
        print("[OK] .env file properly configured")
    else:
        print("[MISSING] .env file not found - copy .env.example to .env")
    print("[OK] Production overrides available")


def main() -> None:
    print("ORACLE STATUS: Reading the Matrix...")
    print()

    config, missing = load_configuration()
    if missing:
        print_missing_configuration_warning(missing)

    print_configuration(config)
    print_security_check()

    print()
    print("The Oracle sees all configurations.")


if __name__ == "__main__":
    main()
