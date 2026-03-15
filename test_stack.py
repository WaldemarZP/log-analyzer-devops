#!/usr/bin/env python3
"""
Integration tests for log analyzer monitoring stack.
Verifies: Prometheus, Grafana, metrics endpoint, and log processing.
"""
import sys
import time
import requests
from requests.exceptions import RequestException


def test_service(url, name, timeout=5):
    """Test if service is reachable."""
    try:
        response = requests.get(url, timeout=timeout)
        if response.status_code in (200, 302):  # 302 = redirect to login (Grafana)
            print(f"✅ {name} is reachable ({response.status_code})")
            return True
        else:
            print(f"❌ {name} returned unexpected status: {response.status_code}")
            return False
    except RequestException as e:
        print(f"❌ {name} unreachable: {e}")
        return False


def test_metrics():
    """Test if Prometheus metrics endpoint is active."""
    try:
        response = requests.get("http://localhost:8000/metrics", timeout=5)
        if response.status_code == 200 and "log_levels_total" in response.text:
            print("✅ Metrics endpoint is active and contains log data")
            # Extract ERROR count
            for line in response.text.split("\n"):
                if 'log_levels_total{level="ERROR"}' in line and not line.startswith("#"):
                    value = line.split()[-1]
                    print(f"   Found {value} ERROR logs in metrics")
            return True
        else:
            print("❌ Metrics endpoint missing log data")
            return False
    except RequestException as e:
        print(f"❌ Metrics endpoint unreachable: {e}")
        return False


def test_log_processing():
    """Test if log analyzer processed sample.log correctly."""
    try:
        with open("report.json", "r") as f:
            import json
            report = json.load(f)
            errors = report.get("ERROR", 0)
            warnings = report.get("WARNING", 0)
            info = report.get("INFO", 0)
            total = errors + warnings + info

            if total == 52:  # 51 log lines + 1 summary line
                print(f"✅ Log analyzer processed 51 lines (ERROR: {errors}, WARNING: {warnings}, INFO: {info})")
                return True
            else:
                print(f"❌ Unexpected log count: {total} lines (expected 52)")
                return False
    except FileNotFoundError:
        print("⚠️  report.json not found (run log_analyzer.py first)")
        return False
    except Exception as e:
        print(f"❌ Error reading report.json: {e}")
        return False


def main():
    print("=" * 60)
    print("🧪 Log Analyzer Integration Tests")
    print("=" * 60)

    results = []

    # Test 1: Prometheus
    results.append(test_service("http://localhost:9090", "Prometheus"))

    # Test 2: Grafana
    results.append(test_service("http://localhost:3000", "Grafana"))

    # Test 3: Nginx reverse proxy (root path → Grafana)
    results.append(test_service("http://localhost", "Nginx (Grafana proxy)"))

    # Test 4: Nginx reverse proxy (Prometheus path)
    results.append(test_service("http://localhost/prometheus/", "Nginx (Prometheus proxy)"))

    # Test 5: Metrics endpoint
    results.append(test_metrics())

    # Test 6: Log processing
    results.append(test_log_processing())

    print("=" * 60)
    if all(results):
        print("🎉 ALL TESTS PASSED!")
        return 0
    else:
        print("❌ SOME TESTS FAILED")
        return 1


if __name__ == "__main__":
    sys.exit(main())
