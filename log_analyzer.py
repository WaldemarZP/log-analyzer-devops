#!/usr/bin/env python3
import argparse
import json
import logging
import re
import time
from pathlib import Path
from typing import Dict
from prometheus_client import start_http_server, Counter, Gauge, Histogram


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler("analyzer.log", encoding="utf-8"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


LOG_LINES_PROCESSED = Counter('log_lines_processed_total', 'Total lines processed from log files')
LOG_ERRORS = Counter('log_errors_total', 'Total number of errors during log processing')
PROCESSING_TIME = Histogram('log_processing_seconds', 'Time spent processing logs')
LOG_LEVELS = Gauge('log_levels_total', 'Count of log levels', ['level'])


# def count_lines(filepath: str) -> int:
#     """Counts the number of lines in the file"""
#     with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
#         return sum(1 for _ in f)

@PROCESSING_TIME.time()
def read_log_files(filepath: str) -> str:
    path = Path(filepath)
    try:
        logger.info(f"Reading logs from {filepath}")
        content = path.read_text(encoding='utf-8', errors='ignore')
        LOG_LINES_PROCESSED.inc(len(content.split('\n')))
        return content
    except FileNotFoundError:
        LOG_ERRORS.inc()
        logger.error(f"File {filepath} doesn't exist")
        raise
    except PermissionError:
        LOG_ERRORS.inc()
        logger.error(f"Don't have permission to read {filepath}")
        raise


def parse_log_levels(content: str, level_filter: str = None) -> Dict[str, int]:
    logger.info(f"Start parsing log")
    pattern = r'\b(ERROR|WARNING|INFO)\b'
    matches = re.findall(pattern, content, re.IGNORECASE)

    stats = {"ERROR": 0, "WARNING": 0, "INFO": 0}
    for level in matches:
        stats[level.upper()] += 1
        LOG_LEVELS.labels(level=level.upper()).set(stats[level.upper()])

    logger.info(f"Parsing completed: {stats}")
    return stats


def save_reports(stats: Dict[str, int], output_path: str = "report.json") -> None:
    try:
        logger.info(f"Saving report to {output_path}")
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(stats, f, indent=4)
        logger.info("Report saved")
    except Exception as e:
        logger.error(f"Error when saving report to {e}")
        raise


def main():
    parser = argparse.ArgumentParser(description="Analyze log levels")
    parser.add_argument("--file", type=str, default="sample.log", help="Path to the log file")
    parser.add_argument("--output", type=str, default="report.json", help="Path to the report file")
    parser.add_argument("--level", type=str, help="Filter by log level (ERROR, WARNING, INFO)")

    args = parser.parse_args()

    try:
        logger.info(f"LAUNCHING THE LOG ANALYZER")
        logger.info(f"Parameters: file:{args.file}, output:{args.output}, level:{args.level}")

        content = read_log_files(args.file)
        stats = parse_log_levels(content, args.level)
        save_reports(stats, args.output)

        logger.info("Stats by logs level:")
        for level, count in stats.items():
            logger.info(f" {level}: {count}")
    except Exception as e:
        logger.critical(f"Critical Error: {e}", exc_info=True)


start_http_server(8000)
logger.info("Prometheus metrics server started on port 8000")


if __name__ == "__main__":
    main()
    logger.info("Keeping metrics server alive for 60 seconds...")
    time.sleep(60)
    logger.info("Exiting after 60 seconds")
    # lines = count_lines("sample.log")
    # print(f"✅ the file contains {lines} lines")
