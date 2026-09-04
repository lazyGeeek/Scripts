import sys

def main():
    targets = []
    with open(sys.argv[1], "r") as input_file:
        content = input_file.readlines()

        for line in content:
            position = line.find("[")

            if position != -1:
                targets.append(line[0:position - 1] + "\n")

        targets[-1] = targets[-1][-1]
        input_file.close()

    with open("http_targets.txt", "a") as output:
        output.writelines(targets)
        output.close()

if __name__ == '__main__':
    main()
