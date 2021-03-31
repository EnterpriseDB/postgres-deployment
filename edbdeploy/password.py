import os
import random
import string


def random_password(length=24):
    # Build a random string composed by letters, digits and punctuation char,
    # of length 'length'.
    letters = string.ascii_letters + string.digits + ".-+=_"
    return ''.join(random.choice(letters) for i in range(length))


def save_password(project_path, username, password):
    # Save password - the same way that edb-ansible works - into:
    #   <project_path>/.edbpass/<username>_pass
    password_file = os.path.join(
        project_path, '.edbpass', '%s_pass' % username
    )

    # Create the .edbpass if it does not exist
    if not os.path.exists(os.path.dirname(password_file)):
        os.makedirs(os.path.dirname(password_file))

    with open(password_file, 'w') as f:
        f.write(password)


def get_password(project_path, username):
    # Read username's password from the file
    password_file = os.path.join(
        project_path, '.edbpass', '%s_pass' % username
    )
    with open(password_file, 'r') as f:
        # Remove new line char if any because edb-ansible put \n at the end of
        # the line.
        password = f.read().replace('\n', '')
        return password


def list_passwords(project_path):
    # Fetch all the credentials present in project directory
    pass_dir = os.path.join(project_path, '.edbpass')
    passwords = []

    for pass_file in os.listdir(pass_dir):
        if not pass_file.endswith('_pass'):
            continue
        username = pass_file.replace('_pass', '')
        passwords.append([username, get_password(project_path, username)])

    return passwords
