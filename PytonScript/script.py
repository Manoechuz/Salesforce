import csv
import sys
import os
import shutil

if __name__ == "__main__":
    print('Order of arguments: python script.py <path_to_csv_file> <column_number> <column_number> ...')
    # Path to your CSV file
    try:  
        csv_file_path = sys.argv[1]
    except IndexError:
        print("Please provide the path to the CSV file as the third argument.")
        sys.exit(1)
    
    try:
        arrArg = []
        for i in range(2, len(sys.argv)):
            arrArg.append(sys.argv[i])
    except IndexError:
        print("Please provide the column number after the third argument.")
        sys.exit(1)

    folder_name = 'data'

    # Remove the folder if it exists
    if os.path.exists(folder_name) and os.path.isdir(folder_name):
        shutil.rmtree(folder_name)

    # Create the folder
    os.mkdir(folder_name)

    # Reading from the CSV file
    with open(csv_file_path, mode='r', newline='', encoding='utf-8') as file:
        reader = csv.reader(file)
        data = list(reader)
        for index,row in enumerate(data):

            if(index == 0):
                continue
            elif(data[index][0] == 'TRUE'):
                data[index][0] = '1'

            elif(data[index][0] == 'FALSE'):
                data[index][0] = '0'

            # Path to your HTML file
            for col in arrArg:
                html_file_path = 'data/' + str(index) + '_'+ str(col) +'.html'

                # Create and write to the HTML file
                with open(html_file_path, mode='w', encoding='utf-8') as file:
                    file.write(row[int(col)])
                
                # Update the CSV file with the path to the HTML file
                data[index][int(col)] = html_file_path

    with open(csv_file_path, mode='w', newline='', encoding='utf-8') as file:
        writer = csv.writer(file)
        writer.writerows(data)