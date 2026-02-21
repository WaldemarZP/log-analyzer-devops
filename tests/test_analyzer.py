import pytest
import json
from pathlib import Path


from log_analyzer import read_log_files, parse_log_levels, save_reports


def test_read_log_file_exists():
    content = read_log_files("sample.log")
    assert isinstance(content, str)
    assert len(content) > 0


def test_read_log_files_not_exist():
    with pytest.raises(FileNotFoundError):
        read_log_files("not_existent.log")


def test_parse_log_levels_basic():
    content = "ERROR: failed\nWARNING: slow\nINFO: started\nERROR: timeout"
    stats = parse_log_levels(content)
    assert stats["ERROR"] == 2
    assert stats["WARNING"] == 1
    assert stats["INFO"] == 1


def test_parse_log_levels_with_filter():
    content = "ERROR: failed\nWARNING: slow\nINFO: started\nERROR: timeout"
    stats = parse_log_levels(content, level_filter="ERROR")
    assert stats["ERROR"] == 2
    assert stats["WARNING"] == 0
    assert stats["INFO"] == 0


def test_parse_log_levels_case_insensitive():
    content = "error: lowercase\nError: mixed\nERROR: uppercase"
    stats = parse_log_levels(content)
    assert stats["ERROR"] == 3


def test_save_report_creates_file():
    test_output = "test_report.json"
    stats = {"ERROR": 1, "WARNING": 2, "INFO": 3}

    save_reports(stats, test_output)

    assert Path(test_output).exists()

    Path(test_output).unlink()


def test_save_report_valid_json():
    test_output = "test_report.json"
    stats = {"ERROR": 5, "WARNING": 3, "INFO": 10}

    save_reports(stats, test_output)

    with open(test_output, 'r') as f:
        loaded = json.load(f)

    assert loaded == stats

    Path(test_output).unlink()
