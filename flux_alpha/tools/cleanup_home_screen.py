
import os

file_path = r'd:\Project Fluxalpha\flux_alpha\lib\screens\home_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Ranges to delete (1-based inclusive)
# 1. 2979 to 3757
# 2. 3920 to 4012
ranges = [(2979, 3757), (3920, 4012)]

new_lines = []
for i, line in enumerate(lines):
    line_num = i + 1
    exclude = False
    for start, end in ranges:
        if start <= line_num <= end:
            exclude = True
            break
    if not exclude:
        new_lines.append(line)

with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print(f"Processed {len(lines)} lines, kept {len(new_lines)} lines.")
