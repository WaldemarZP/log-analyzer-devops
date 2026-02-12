#!/usr/bin/env python3
"""Day 1: counting lines in the log"""

def count_lines(filepath: str) -> int:
    """Counts the number of lines in the file"""
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        return sum(1 for _ in f)

if __name__ == "__main__":
    lines = count_lines("sample.log")
    print(f"✅ the file contains {lines} lines")
