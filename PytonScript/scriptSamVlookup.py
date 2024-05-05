import csv

def read_csv_file(file_name):
    with open(file_name, mode='r', newline='', encoding='utf-8') as file:
        reader = csv.reader(file)
        headers = next(reader)  # Read the first line as the header
        data = list(reader)
        return headers, data

def write_csv_file(file_name, headers, data):
    with open(file_name, mode='w', newline='', encoding='utf-8') as file:
        writer = csv.writer(file)
        writer.writerow(headers)  # Write the headers
        writer.writerows(data)  # Write the data rows

if __name__ == "__main__":
    csv_file_modify = 'modify.csv'
    csv_file_reference = 'reference.csv'

    modify_headers, modify = read_csv_file(csv_file_modify)
    reference_headers, reference = read_csv_file(csv_file_reference)

    combined_headers = modify_headers + reference_headers

    updated_rows = []
    for rowModify in modify:
        matched = False
        for rowReference in reference:
            if rowModify[3] in rowReference[0] or rowModify[3] in rowReference[0]:  # Assuming the match condition is based on the first column
                updated_rows.append(rowModify + rowReference)
                matched = True
                break

        if not matched:
            updated_rows.append(rowModify + [''] * len(reference_headers))  # Extend with empty values for unmatched rows

    write_csv_file(csv_file_modify, combined_headers, updated_rows)
