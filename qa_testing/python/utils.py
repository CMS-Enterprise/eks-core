# Check for missing required packages and attempt to import them
missing_packages = []

# Import standard Python libraries, noting any that are missing
try:
    import datetime
except ModuleNotFoundError:
    missing_packages.append("datetime")

try:
    import os
except ModuleNotFoundError:
    missing_packages.append("os")

try:
    import platform
except ModuleNotFoundError:
    missing_packages.append("platform")

try:
    import pkg_resources
    from pkg_resources import DistributionNotFound, VersionConflict
except ModuleNotFoundError:
    missing_packages.append("pkg_resources")

try:
    import re
except ModuleNotFoundError:
    missing_packages.append("re")

try:
    import sys
except ModuleNotFoundError:
    missing_packages.append("sys")

try:
    import time
except ModuleNotFoundError:
    missing_packages.append("time")

try:
    from typing import List
except ModuleNotFoundError:
    missing_packages.append("typing")


#####################################################################
# Python Progress Bar Libraries
#   https://builtin.com/software-engineering-perspectives/python-progress-bar
#   https://pypi.org/project/progress/
#
#   pip install progress
#
try:
    from progress.bar import IncrementalBar
except ModuleNotFoundError:
    missing_packages.append("progress.bar")

if missing_packages:
    print("Missing required Python packages:")
    for package in missing_packages:
        print(f"  - {package}")
    print(f"[!] Please review 'Batcave Landing Zone Python Script Dependencies'"
          f"    in the BLZ/docs/onboarding/Onboarding-and-Prerequisits.md")
    sys.exit(1)


def color_list(text_list: List[str], color_codes: List[str]) -> List[str]:
    colored_list=[]
    for text in text_list:
        colored_list.append(color_text(text, color_codes))
    return colored_list


def color_text(text: str, color_codes: List[str]) -> str:
    """
        list colors in bash/unix
        for i in {0..255}; do printf "\033[38;5;${i}m%-4s \033[38;5;${i}m\033[0m\n" "\\033[38;5;${i}m"; done

        t_ = text color
            d_ = dark
            l_ = light
            b_ = bright
    """
    # Define the color codes in a dictionary
    colors = {
        "t_red": "\033[38;5;1m",
        "t_l_red": "\033[38;5;9m",
        "t_d_red": "\033[38;5;88m",

        "t_orange": "\033[38;5;202m",
        "t_l_orange": "\033[38;5;208m",
        "t_d_orange": "\033[38;5;166m",
        "t_peach": "\033[38;5;173m",
        "t_brown": "\033[38;5;94m",

        "t_yellow": "\033[38;5;11m",
        "t_l_yellow": "\033[38;5;191m",
        "t_d_yellow": "\033[38;5;3m",
        "t_gold": "\033[38;5;58m",
        "t_neon": "\033[38;5;154m",

        "t_l_green": "\033[38;5;10m",
        "t_green": "\033[38;5;34m",
        "t_b_green": "\033[38;5;46m",
        "t_d_green": "\033[38;5;28m",
        "t_forrest": "\033[38;5;22m",

        "t_d_teal": "\033[38;5;23m",
        "t_teal": "\033[38;5;30m",
        "t_l_teal": "\033[38;5;43m",
        "t_aqua": "\033[38;5;50m",

        "t_cyan": "\033[38;5;51m",
        "t_b_blue": "\033[38;5;45m",
        "t_blue": "\033[38;5;33m",
        "t_d_blue": "\033[38;5;27m",
        "t_l_blue": "\033[38;5;12m",

        "t_l_purple": "\033[38;5;105m",
        "t_purple": "\033[38;5;99m",
        "t_d_purple": "\033[38;5;57m",
        "t_b_purple": "\033[38;5;129m",
        "t_lavender": "\033[38;5;13m",

        "t_hotpink": "\033[38;5;165m",
        "t_pink": "\033[38;5;212m",
        "t_rose": "\033[38;5;174m",

        "t_d_grey": "\033[38;5;239m",
        "t_grey": "\033[38;5;243m",
        "t_l_grey": "\033[38;5;248m",

        "t_white": "\033[38;5;255m",

        "t_bold": "\033[1m",
        "t_underline": "\033[4m",
        "t_italics": "\033[3m",

        "t_reset": "\033[0m"
    }

    # Remove existing color formatting from the text
    text = re.sub(r'\033\[[0-9;]*m', '', text)

    colored_text = text
    for color_code in color_codes:
        if color_code in colors:
            colored_text = colors[color_code] + colored_text

    # Reset the color at the end of the text
    colored_text += colors["t_reset"]

    return colored_text


def non_visible_length(text: str) -> int:
    non_visible_chars = re.findall(r'\x1b\[[0-9;]*m', text)
    return sum(len(char) for char in non_visible_chars)


def time_lapsed(start_time: datetime.datetime) -> datetime.timedelta:
    time_now = datetime.datetime.now()
    return time_now - start_time


def print_time_status(start_time: datetime.datetime) -> None:
    s_time = color_text(start_time.strftime("%H:%M:%S"), ['t_grey'])
    l_time = color_text(str(time_lapsed(start_time)).split(".")[0], ['t_d_green'])
    print(f"[*] Script {'Start Time:':<14}{s_time:<14}")
    print(f"           {'Time Lapsed:':<14}{l_time:<14}\n")


def status_message(message: str, status: str, start_time: datetime.datetime = None) -> None:
    if start_time:
        print_time_status(start_time)

    status_symbols = {
        'info': '*',
        'execution': color_text('x', ['t_l_orange']),
        'warning': color_text('!', ['t_pink']),
        'error': color_text('!', ['t_red']),
        'question': color_text('?', ['t_l_purple']),
        'success': color_text('+', ['t_b_green'])
    }

    if status in status_symbols:
        print(f"[{status_symbols[status]}] {message}")
    else:
        print(f"[*] {message}")  # Default case


def pause() -> None:
    input(f"[*] Press Enter to continue . . .")


def continue_prompt(message: str = '', skip: bool = False) -> bool:
    q = color_text(f'?', ['t_l_purple'])
    if message:
        print(f"[{q}] {message}")

    if skip:
        prompt = "Continue (y), Exit script (x), or Skip (s)... ? (y/x/s): "
    else:
        prompt = "Continue (y) or Exit script (x)... ? (y/x): "

    while True:
        user_input = input(f"[{q}] {prompt}")
        if user_input:  # Check if the input is not empty
            if user_input.lower()[0] == 'y':
                return True
            elif user_input.lower()[0] == 'x':
                status_message("Exiting...", 'warning')
                sys.exit(1)
            elif user_input.lower()[0] == 's' and skip:
                return False


def wait(sec: int, message: str = '', start_time: datetime.datetime = None) -> None:
    if start_time:
        print_time_status(start_time)

    reason = message + ' ' if message else ''
    status_message(f"Waiting {color_text(f'{sec}', ['t_l_purple'])} seconds {reason}to continue...", 'warning')

    updates = int(sec * 100)

    with IncrementalBar('   ', max=updates, suffix='%(percent).1f%% - %(eta)ds') as bar:
        for i in range(updates):
            time.sleep(sec / updates)
            bar.next()
    return


def quit_now(message: str = '', start_time: datetime.datetime = None):
    if message:
        status_message(message, 'error', start_time)
    status_message('Cannot continue, exiting!', 'error')
    sys.exit(0)


def print_dict(data, indent=0):
    """
    Recursively print nested dictionaries.
    """
    # Iterate through dictionary items
    for key, value in data.items():
        if isinstance(value, dict):
            print('  ' * indent + str(key) + ':')
            print_dict(value, indent + 1)
        elif isinstance(value, list):
            print('  ' * indent + str(key) + ':')
            for item in value:
                if isinstance(item, dict):
                    print_dict(item, indent + 1)
                else:
                    print('  ' * (indent + 1) + str(item))
        else:
            print('  ' * indent + str(key) + ': ' + str(value))


def get_os_environment_variable(env_key_label: str, verbose: bool = False) -> str:
    try:
        env_value = os.environ[env_key_label]
    except KeyError:
        cf_env_key_label = f"{color_text(f'{env_key_label}', ['t_d_yellow'])}"
        if verbose:
            status_message(f"Environment variable ${cf_env_key_label} not set", 'error')
        return ''
    else:
        if verbose:
            status_message(f"Value for Environment Variable "
                           f"{color_text(f'${env_key_label}', ['t_d_yellow'])}"
                           f" : {color_text(f'{env_value}', ['t_l_yellow'])}", 'info')
        return env_value


def verify_requirements(requirements_file: str = os.path.dirname(os.path.abspath(__file__)) +
                        '/requirements.txt') -> bool:
    try:
        with open(requirements_file, 'r') as f:
            requirements = f.read().splitlines()

        # Check if the installed packages meet the requirements
        pkg_resources.require(requirements)
        status_message(f"All python module requirements are met. Proceed with script execution.", 'success')
        return True
    except (DistributionNotFound, VersionConflict) as e:
        cf_pip_cmd = color_text('pip download -r scripts/requirements.txt -d scripts/packages', ['t_l_yellow'])
        cf_pip_install = color_text('sudo pip install -r scripts/requirements.txt', ['t_l_yellow'])
        status_message(f"Requirements not met. Exiting.\n\n"
                       f"    Run the following from the BLZ root directory:\n"
                       f"        {cf_pip_cmd}\n"
                       f"        {cf_pip_install}\n"
                       f"Error: {e}", 'error')
        sys.exit(1)


def verify_min_python_version(desired_ver: int, desired_subver: int) -> bool:
    current_env_python_ver_t = platform.python_version_tuple()
    current_env_python_ver = platform.python_version()

    if int(current_env_python_ver_t[0]) >= desired_ver:
        if int(current_env_python_ver_t[1]) >= desired_subver:
            status_message(f"Python ver: {current_env_python_ver} meets requirement >= {desired_ver}.{desired_subver}",
                           "success")
            return True

    status_message(
        f"Python ver: {current_env_python_ver} doesn't meet requirement >= {desired_ver}.{desired_subver}",
        "error")
    return False
