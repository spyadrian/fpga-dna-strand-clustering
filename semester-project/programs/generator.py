import random
from faker import Faker
import Levenshtein

fake = Faker()


def generate_random_string(length, is_dna=False):
    if is_dna:
        return ''.join(random.choices('ACTG', k=length))
    else:
        word = fake.word()
        return word[:length]


def create_string_pairs(num_pairs, max_len):

    pairs = []
    for i in range(num_pairs):
        is_dna = i >= num_pairs // 2
        len1, len2 = random.randint(1, max_len), random.randint(1, max_len)
        str1, str2 = generate_random_string(
            len1, is_dna), generate_random_string(len2, is_dna)
        distance = Levenshtein.distance(str1, str2)
        pairs.append((str1, str2, distance))
    return pairs


def save_to_file(pairs, filename):

    with open(filename, 'w') as file:
        for str1, str2, distance in pairs:
            file.write(f'"{str1}","{str2}",{distance}\n')


if __name__ == "__main__":

    num_pairs = 200
    max_len = 244
    output_file = 'data.txt'

    string_pairs = create_string_pairs(num_pairs, max_len)
    save_to_file(string_pairs, output_file)

    print(f"Data saved to {output_file}")
