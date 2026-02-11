import ast
import re
import sys

def load_gdscript_cases(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    match = re.search(r'const CASES_B: Array = \s*\[', content)
    if not match:
        print("Could not find start of CASES_B array.")
        sys.exit(1)

    start = match.end() - 1

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
        print("Could not find end of CASES_B array.")
        sys.exit(1)

    gd_str = content[start:end+1]

    lines = gd_str.split('\n')
    cleaned_lines = []
    for line in lines:
        if '#' in line:
            line = line.split('#')[0]
        cleaned_lines.append(line)

    gd_str = '\n'.join(cleaned_lines)

    gd_str = gd_str.replace('null', 'None')
    gd_str = gd_str.replace('true', 'True')
    gd_str = gd_str.replace('false', 'False')

    try:
        data = ast.literal_eval(gd_str)
        return data
    except Exception as e:
        print(f"AST Eval Error: {e}")
        sys.exit(1)

def validate_case_b(c):
    errors = []

    if c.get("interaction_type") == "MULTI_SELECT_ROWS":
        # Disjoint Set Verification
        A = set(c.get("answer_row_ids", []))
        B = set(c.get("boundary_row_ids", []))
        O = set(c.get("opposite_row_ids", []))
        U = set(c.get("unrelated_row_ids", []))

        # Check intersections
        if not A.isdisjoint(B):
            # Exception: Non-strict logic allows B in A?
            # Re-reading logic: "boundary_row_ids... identifying WHICH rows are boundary".
            # Logic: "if not strict and is_subset(B, A) and not is_subset(B, S) -> EXCLUDED_BOUNDARY".
            # This implies B MUST be a subset of A for non-strict cases to trigger EXCLUDED_BOUNDARY properly.
            # BUT for strict cases, B and A must be disjoint to trigger INCLUDED_BOUNDARY.

            strict = c.get("predicate", {}).get("strict_expected", True)
            if strict:
                 errors.append(f"Strict mode: A and B must be disjoint. Overlap: {A & B}")
            else:
                 # Non-strict: B should be subset of A? Or just overlap allowed?
                 # If B is not in A, then EXCLUDED_BOUNDARY check fails because `is_subset(B, A)` is false.
                 # So for non-strict, B MUST be subset of A.
                 if not B.issubset(A):
                     errors.append(f"Non-strict mode: B must be subset of A. B-A: {B - A}")

        if not A.isdisjoint(O): errors.append(f"A intersects O: {A & O}")
        if not A.isdisjoint(U): errors.append(f"A intersects U: {A & U}")

        if not B.isdisjoint(O): errors.append(f"B intersects O: {B & O}")
        if not B.isdisjoint(U): errors.append(f"B intersects U: {B & U}")

        if not O.isdisjoint(U): errors.append(f"O intersects U: {O & U}")

    return len(errors) == 0, errors

def main():
    cases = load_gdscript_cases("scripts/case_07/da7_cases_b.gd")
    print(f"Loaded {len(cases)} cases.")

    all_valid = True
    for c in cases:
        is_valid, errs = validate_case_b(c)
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
