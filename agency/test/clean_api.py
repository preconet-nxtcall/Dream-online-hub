import re

path = r'D:\download\fairbiz\office-manage\api.php'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

print(f"Original line count: {len(lines)}")

# Let's inspect lines 860 to 880
for idx, l in enumerate(lines[860:880], start=861):
    print(f"{idx}: {repr(l)}")

# Let's check duplicate else
new_lines = []
skip = False
for i, line in enumerate(lines):
    # check if line 871 has "} else {" right after another "} else {"
    if i > 0 and lines[i].strip() == "} else {" and lines[i-4].strip() == "} else {":
        # skip this duplicate block
        pass
    new_lines.append(line)

# Let's rewrite cleanly
content = "".join(lines)
# Clean duplicate else
dup_pattern = r"(\s*\}\s*else\s*\{\s*http_response_code\(400\);\s*echo\s*json_encode\(\[\"success\"\s*=>\s*false,\s*\"message\"\s*=>\s*\"Valid ID required\.\"]\);\s*exit;\s*\})(\s*else\s*\{\s*http_response_code\(400\);\s*echo\s*json_encode\(\[\"success\"\s*=>\s*false,\s*\"message\"\s*=>\s*\"Valid ID required\.\"]\);\s*exit;\s*\})"

cleaned = re.sub(dup_pattern, r"\1", content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(cleaned)

print("Cleaned file written!")
