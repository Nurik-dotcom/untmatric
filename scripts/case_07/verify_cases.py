import ast
import re
import sys

def load_gdscript_cases(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Find the CASES_A array start
    # Look for 'static var CASES_A: Array = ['
    match = re.search(r'static var CASES_A: Array = \s*\[', content)
    if not match:
        print("Could not find start of CASES_A array.")
        sys.exit(1)

    start = match.end() - 1 # Points to '['

    # Find the matching closing bracket
    # Since we might have nested brackets, we need to count them.
    nesting = 0
    end = -1
    for i in range(start, len(content)):
        char = content[i]
        if char == '[':
            nesting += 1
        elif char == ']':
            nesting -= 1
            if nesting == 0:
                end = i
                break

    if end == -1:
        print("Could not find end of CASES_A array.")
        sys.exit(1)

    gd_str = content[start:end+1]

    # Remove comments
    lines = gd_str.split('\n')
    cleaned_lines = []
    for line in lines:
        if '#' in line:
            line = line.split('#')[0]
        cleaned_lines.append(line)

    gd_str = '\n'.join(cleaned_lines)

    # Replace GDScript keywords with Python
    gd_str = gd_str.replace('null', 'None')
    gd_str = gd_str.replace('true', 'True')
    gd_str = gd_str.replace('false', 'False')

    try:
        data = ast.literal_eval(gd_str)
        return data
    except Exception as e:
        print(f"AST Eval Error: {e}")
        # print("Snippet:", gd_str[:500])
        sys.exit(1)

def validate_case(c):
    errors = []
    # 1. Required Fields
    req_fields = ["id", "schema_version", "level", "topic", "case_kind",
        "interaction_type", "prompt", "table", "options", "answer_id"]
    for f in req_fields:
        if f not in c:
            errors.append(f"Missing field: {f}")
            return False, errors

    # 2. Schema
    if c["schema_version"] != "DA7.A.v1":
        errors.append(f"Bad schema: {c['schema_version']}")
    if c["level"] != "A":
        errors.append(f"Bad level: {c['level']}")

    # 3. Table
    if "columns" not in c["table"] or "rows" not in c["table"]:
        errors.append("Bad table structure")
    else:
        # Check columns
        if not c["table"]["columns"]:
             errors.append("No columns")

        col_ids = [col["col_id"] for col in c["table"]["columns"]]
        for row in c["table"]["rows"]:
            if "row_id" not in row or "cells" not in row:
                errors.append("Bad row structure")
                continue
            for cid in col_ids:
                if cid not in row["cells"]:
                    errors.append(f"Row {row.get('row_id')} missing cell {cid}")

    # 4. Options
    if len(c["options"]) < 2:
        errors.append("Too few options")

    has_answer = False
    valid_reasons = [
        "COUNT_HEADER_AS_RECORD", "MISSED_COLUMN", "MISSED_ROW",
        "CONFUSE_ROWS_WITH_COLUMNS", "OFF_BY_ONE",
        "PRIMARY_KEY_NOT_UNIQUE", "PRIMARY_KEY_CAN_BE_NULL",
        "CHOOSE_FIRST_COLUMN_BIAS", "TYPE_CONFUSION_NUMBER_TEXT",
        "TYPE_CONFUSION_DATE_TEXT"
    ]

    for opt in c["options"]:
        if opt["id"] == c["answer_id"]:
            has_answer = True
            if opt.get("f_reason") is not None:
                errors.append("Correct answer has f_reason != null")
        else:
            if opt.get("f_reason") is None:
                errors.append(f"Incorrect option {opt['id']} has f_reason == null")
            elif opt["f_reason"] not in valid_reasons:
                errors.append(f"Unknown f_reason: {opt['f_reason']}")

    if not has_answer:
        errors.append("answer_id not found in options")

    # 5. Expected Dimensions
    if c["expected"]["n_rows"] != len(c["table"]["rows"]):
        errors.append(f"Rows mismatch: exp {c['expected']['n_rows']} real {len(c['table']['rows'])}")
    if c["expected"]["n_cols"] != len(c["table"]["columns"]):
         errors.append(f"Cols mismatch: exp {c['expected']['n_cols']} real {len(c['table']['columns'])}")

    return len(errors) == 0, errors

def main():
    cases = load_gdscript_cases("scripts/case_07/da7_cases_a.gd")
    print(f"Loaded {len(cases)} cases.")

    all_valid = True
    for c in cases:
        is_valid, errs = validate_case(c)
        if not is_valid:
            print(f"FAIL: Case {c.get('id', '??')}: {errs}")
            all_valid = False
        else:
            print(f"OK: Case {c['id']}")

    if all_valid:
        print("VERIFICATION SUCCESS")
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
